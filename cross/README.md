# Cross compiling `probe-rs` for Raspberry Pi 3B 

Using Multipass, no Docker Desktop needed.

>Note: If you have Windows + WSL2, with Docker Desktop installed, these instructions can be followed.

Instructions for cross-compiling Rust binaries (`probe-rs`, in particular) to the [Raspberry Pi 3B](https://www.raspberrypi.com/products/raspberry-pi-3-model-b/) platform. This platform (though having 1GB of RAM) is not sufficient for Rust compiler stack.<sup>`|1|`</sup> You can adopt this setup for cross-compiling other such tools.

<small>`|1|`: You can get around the limitations [with `--jobs 1`](https://matrix.to/#/#probe-rs:matrix.org/$177zGb6oHLGzurXXi5hpYCb_tihbzUVaFG07c8QhJos). But compilation will take almost 2 hours.</small>

>WARN! The [`rustembedded/cross`](https://hub.docker.com/r/rustembedded/cross) Docker image used by these instructions (which are from the `probe-rs` documentation) has been:
>
> *"Updated over 3 years ago".*

## Requirements

- [Multipass](https://canonical.com/multipass) virtualization software installed

	>Note: The VM will require some 7GB of disk space, in addition to installing Multipass.

<!--
Developed on:
- macOS 15.2
- Multipass 1.15.0

- Windows 10 Home
- WSL 2.3.26.0
-->

## Steps

### 1. Create a Docker-containing VM

>WSL2: If using WSL2, you already have an Ubuntu environment. Skip to next.

```
$ multipass launch docker --memory 4GB --cpus 4
Starting docker /
[...]
```

>You can adjust the VM parameters based on your computer. The default is 2 CPUs but the more you give, the faster the build will be.

<p />

>Multipass has built-in support for Docker, meaning that naming a VM `docker` brings certain users, groups in it, and installs Docker itself.

Dive to it:

```
$ multipass shell docker
```

The rest of the commands we'll execute within this Ubuntu VM environment.


### 2. Install tools

The [`mp`](https://github.com/akauppi/mp) repo has instructions for setting up a Rust build environment. We'll reuse it here, by downloading it into the VM.

```
[ubuntu]~$ git clone --depth=1 https://github.com/akauppi/mp.git
```

```
[ubuntu]~$ chmod a+x mp/rust/linux/*.sh
```

That allows us to execute the files under `rust/linux/`:

```
[ubuntu]~$ mp/rust/linux/rustup.sh
[...]
To ginfo: default toolchain set to 'stable-x86_64-unknown-linux-gnu'

  stable-x86_64-unknown-linux-gnu installed - rustc 1.83.0 (90b35a623 2024-11-26)
```

The `cargo` ecosystem is now installed, but to reach it in current prompt:

```
[ubuntu]~$ . $HOME/.cargo/env
```

>Testing:
>
>```
>$ rustc --version
>rustc 1.84.0 (9fc6b4312 2025-01-07)
>```

Let's install also `rustfmt`:

```
[ubuntu]~$ rustup component add rustfmt
info: downloading component 'rustfmt'
info: installing component 'rustfmt'
```


### 3. Follow [`probe-rs` steps](https://probe.rs/docs/library/crosscompiling/)

>Note: We've regrouped the commands, compared to the `probe-rs` docs.

#### 3.1 Create a Docker image

```
[ubuntu]~$ mkdir crossimage
```

```
[ubuntu]~$ cat > crossimage/Dockerfile <<EOF
FROM rustembedded/cross:armv7-unknown-linux-gnueabihf
ENV PKG_CONFIG_ALLOW_CROSS=1
ENV PKG_CONFIG_LIBDIR=/usr/lib/arm-linux-gnueabihf/pkgconfig
RUN dpkg --add-architecture armhf && \
    apt-get update && \
    apt-get install -y libusb-1.0-0-dev:armhf libftdi1-dev:armhf libudev-dev:armhf
EOF
```

```
[ubuntu]~$ docker build -t crossimage crossimage/
[...]
 => => naming to docker.io/library/crossimage    0.0s
```

We now have a `crossimage` Docker image built.

>Testing:
>
>```
>$ docker images
>[...]
>crossimage     latest    87cdd66eebcc   3 minutes ago   1.04GB
>```

#### 3.2 Install `cross` add-on

```
[ubuntu]~$ cargo install cross
```

>Note: Unlike the official instructions, adding lines to `Cross.toml` does not seem to be needed.

#### 3.3 Cross-build `probe-rs`

```
[ubuntu]~$ git clone --depth=1 https://github.com/probe-rs/probe-rs
```

```
[ubuntu]~$ cd probe-rs
```

```
[ubuntu]~/[...]$ cross build -p probe-rs-tools --release --target=armv7-unknown-linux-gnueabihf
[...]
    Finished `release` profile [optimized] target(s) in 7m 18s
```

We now have a Raspberry Pi 3B capable binary in `target/armv7-unknown-linux-gnueabihf/release/probe-rs`.

>Testing:
>
>```
>$ file target/armv7-*/release/probe-rs
>target/armv7-unknown-linux-gnueabihf/release/probe-rs: ELF 32-bit LSB pie executable, ARM, EABI5 version 1 (SYSV), dynamically linked, interpreter /lib/ld-linux-armhf.so.3, for GNU/Linux 3.2.0, BuildID[sha1]=3214d84cfb4b080e1e0dd6530341621c70320eb3, not stripped
>```

```
[ubuntu]~$ cd ~
```


### 4. Move to the Raspberry Pi

>In the following, we assume:
>
>- the IP of a Raspberry Pi to be `192.168.1.199` 
>- the user to be `probe-rs`
>
>You'll certainly get the gist and be able to change the appropriate parts, if you wish for something different.

```
ubuntu@docker:~$ scp probe-rs/target/armv7-unknown-linux-gnueabihf/release/probe-rs probe-rs@192.168.1.199:
The authenticity of host '192.168.1.199 (192.168.1.199)' can't be established.
[...]
Are you sure you want to continue connecting (yes/no/[fingerprint])? yes
Warning: Permanently added '192.168.1.199' (ED25519) to the list of known hosts.
probe-rs@192.168.1.199's password: 
probe-rs                				100%   28MB   4.3MB/s   00:06    
```

>Note: You were asked for a pw, because this `docker` VM isn't keypair connected with your Raspberry Pi. Since this is just a one-time access, entering the pw is fine.

#### Testing (optional)

Once moved, we can test that the binary really runs:

```
ubuntu@docker:~$ ssh -q probe-rs@192.168.1.199 -t 'bash -ic "./probe-rs --version"'
probe-rs@192.168.1.199's password: 
probe-rs 0.25.0 (git commit: v0.25.0-5-g9a767f2-modified)
```

Looks good!

### 5. RPi target setup

We now have the binary on the Raspberry Pi target. Let's move it to a comfortable place and set up the environment (access rights etc.).

For this, you'll need an `ssh` session to the device.

```
ubuntu@docker:~$ ssh probe-rs@192.168.1.199
[...]
probe-rs@rpi:~ $
```

#### Comfortable location

Move the binary to `~/bin` (or any destination you fancy), and add that to the `PATH`:

```
probe-rs@rpi:~ $ mkdir bin
probe-rs@rpi:~ $ mv probe-rs bin/
```

```
probe-rs@rpi:~ $ echo >> ~/.bashrc 'export PATH="$PATH:$HOME/bin"'
probe-rs@rpi:~ $ source ~/.bashrc
```

>Testing:
>
>```
>probe-rs@rpi:~ $ probe-rs version
>probe-rs 0.25.0 (git commit: 5805879)
>```

#### `udev` configuration

Next, we'll set up [`udev` rules](https://probe.rs/docs/getting-started/probe-setup/#linux%3A-udev-rules) so that accessing the MCUs will not need `root` priviledges.

You'll need to do this from another account on the Raspberry Pi - one that has `sudo` rights.

>```
>ubuntu@docker:~$ ssh user@192.168.1.199
>user@192.168.1.199's password: 
>```

```
user@rpi:~ $ curl --proto '=https' --tlsv1.2 -LsSf https://probe.rs/files/69-probe-rs.rules -o abc
user@rpi:~ $ sudo mv abc /etc/udev/rules.d/69-probe-rs.rules
```

```
user@rpi:~ $ sudo udevadm control --reload
```

```
user@rpi:~ $ sudo udevadm trigger
```

#### Adding to `plugdev` group

```
user@rpi:~ sudo usermod -a -G plugdev probe-rs
```

Without this, some commands like `probe-rs info` - and flashing - won't work from the `probe-rs` account.

Now, we are ready!!!  


## Test with a development board

Let's test the setup with actual hardware. Please be on the device as `probe-rs` user.

Insert a USB cable to a dev board.

```
probe-rs@rpi:~ $ probe-rs list
The following debug probes were found:
[0]: ESP JTAG -- 303a:1001:54:32:04:44:74:C0 (EspJtag)
```

```
$ probe-rs info --protocol jtag
Probing target via JTAG

No DAP interface was found on the connected probe. ARM-specific information cannot be printed.
RISC-V Chip:
  IDCODE: 000000dc25
    Version:      0
    Part:         13
    Manufacturer: 1554 (Espressif Systems (Shanghai)  Co Ltd)
Xtensa Chip:
  IDCODE: 0000000000
    Version:      0
    Part:         0
    Manufacturer: 0 (Unknown Manufacturer Code)
```


## Clean-up

>NOTE! You might want to keep the `docker` image around, e.g. for compiling the next version of `probe-rs`. 

Once you have placed `probe-rs` on the target, there's no need for the `docker` VM to be kept around. Remove it by:

```
$ multipass stop docker
$ multipass delete --purge docker
```

This releases some 9GB of your disk space.

>Note: Why stop it first? Multipass 1.14 and 1.15 have suffered from issues when changing state of running images. Stopping it first is a pre-emptive measure.


## References

- [`probe-rs` > Crosscompiling](https://probe.rs/docs/library/crosscompiling/)
- [Docker on Mac – a lightweight option with Multipass](https://ubuntu.com/blog/docker-on-mac-a-lightweight-option-with-multipass) (Aug'23)


