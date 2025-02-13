# Cross compiling for Raspberry Pi 3B 

<!-- tbd. good photo; maybe take ourselves??? -->

Instructions for cross-compiling Rust binaries (`probe-rs` and `espflash`, in particular) to the [Raspberry Pi 3B](https://www.raspberrypi.com/products/raspberry-pi-3-model-b/) platform. This platform (though having 1GB of RAM and 4 cores) is not quite sufficient for the Rust compiler stack.<sup>`|1|`</sup> Thus, we cross-compile.

<small>`|1|`: You can get around the limitations [with `--jobs 1`](https://matrix.to/#/#probe-rs:matrix.org/$177zGb6oHLGzurXXi5hpYCb_tihbzUVaFG07c8QhJos). But... compilation will take almost 2 hours.</small>

>[!WARN]
>
>The [`rustembedded/cross`](https://hub.docker.com/r/rustembedded/cross) image used in these instructions (derived from the `probe-rs` documentation) says: *"Updated over 3 years ago".* (but the instructions do work...)


## Requirements

These instructions are for Ubuntu Linux, with Docker CLI installed. This can mean:

- Windows + WSL2 + Docker Desktop   // what the author uses
- A native Ubuntu Linux account
- An Ubuntu Linux VM

>[!HINT]
>If you are on a Mac, or don't want to install Docker on your main system, have a look at [Appendix A. Multipass and Docker](#), to create a suitable VM.

<!--
Developed on:
- Windows 10 Home
- WSL 2.3.26.0
- Docker Desktop 4.38.0
-->

## Steps

<!-- REMOVE tbd.
### 1. Install tools (to WSL2 instance)

We follow the instructions in [`mp`](https://github.com/akauppi/mp) repo for setting up a Rust build environment. 

After this step, you have:

- `cargo` installed
- `rustfmt` plugin installed

If you already have these, just skip to step 2.

**Fetch the recipies**

In a suitable (temporary) folder:

```
$ git clone --depth=1 https://github.com/akauppi/mp.git
$ cd mp/rust/linux
$ chmod a+x *.sh
```

This folder has three scripts; we'll run them all:

```
$ ls -1
rustftm.sh
rustup.sh
shared-target.sh
```
-->

### 1. Install Rust toolchain to WSL2

```
$ sudo apt-get update
```

```
$ curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- \
  --default-toolchain none -y --profile minimal
```

```
$ . $HOME/.cargo/env
```

```
$ rustup default stable
```

>Test it:
>
>```
>$ cargo --version
>cargo 1.84.1 (66221abde 2024-11-19)
>```

<!-- #hidden; not needed?
Let's also install `rustfmt`:

```
$ rustup component add rustfmt
info: downloading component 'rustfmt'
info: installing component 'rustfmt'
```
-->

>[!NOTE]
>
>If you needed to install some system-level packages (e.g. `pkg-config`) via `sudo apt install`, let the author know. Let's add them to the instructions.


### 2. Prepare the `rustembedded/cross:armv7-unknown-linux-gnueabihf` image - and use it!

>Based on [these instructions](https://probe.rs/docs/library/crosscompiling/) from `probe-rs` docs, but re-ordered.

#### 2.1 Create a Docker image

```
$ mkdir crossimage
```

```
$ cat > crossimage/Dockerfile <<EOF
FROM rustembedded/cross:armv7-unknown-linux-gnueabihf
ENV PKG_CONFIG_ALLOW_CROSS=1
ENV PKG_CONFIG_LIBDIR=/usr/lib/arm-linux-gnueabihf/pkgconfig
RUN dpkg --add-architecture armhf && \
    apt-get update && \
    apt-get install -y libusb-1.0-0-dev:armhf libftdi1-dev:armhf libudev-dev:armhf
EOF
```

```
$ docker build -t crossimage crossimage/
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

#### 2.2 Install `cross` add-on

```
$ cargo install cross
```

>Note: Unlike in the `probe-rs` instructions, adding lines to `Cross.toml` does not seem to be needed.

#### 2.3 Cross-build `probe-rs`

```
$ git clone --depth=1 https://github.com/probe-rs/probe-rs
```

```
$ cd probe-rs
```

It's way safer to use a released version than the current "head" of the `main` branch.

```
[probe-rs] $ git checkout v0.27.0
```

```
[probe-rs] $ cross build -p probe-rs-tools --release --target=armv7-unknown-linux-gnueabihf
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
$ cd ..
```

#### 2.4 Cross-build `espflash` (optional)

```
$ git clone --depth=1 https://github.com/esp-rs/espflash.git
```

```
$ cd espflash
```

It's way safer to use a released version than the current "head" of the `main` branch.

```
[espflash] $ git checkout v3.3.0
```

```
[espflash] $ cross build -p espflash --release --target=armv7-unknown-linux-gnueabihf --no-default-features --features=cli
[...]
    Finished `release` profile [optimized] target(s) in 7m 18s
```

>[!NOTE]
>
>The author doesn't know, how to cross-compile with the `udev` feature. Omitting the feature merely means, you need modify groups when setting things up in the Raspberry Pi (we'll come to that, soon).

We now have a Raspberry Pi 3B capable binary in `target/armv7-unknown-linux-gnueabihf/release/espflash`.

>Testing:
>
>```
>$ file target/armv7-*/release/espflash
>target/armv7-unknown-linux-gnueabihf/release/probe-rs: ELF 32-bit LSB pie executable, ARM, EABI5 version 1 (SYSV), dynamically linked, interpreter /lib/ld-linux-armhf.so.3, for GNU/Linux 3.2.0, BuildID[sha1]=1967[...]0e50, not stripped
>```

```
[ubuntu]~$ cd ..
```

### 3. Intermission!

The binaries are now done. We need to move them to the Raspberry Pi, and set up the development computer to reach them there.

At this moment, it's worth noting that you might want to **preserve the above (temporary) folder**. Why? 

When neww releases of the tools arise, it's now enough for you to do `git pull` and rebuild. If you remove the folder and/or the Docker image, you'll need to start all from the beginning.


### 4. Move to the Raspberry Pi

>In the following, we assume:
>
>- the IP of a Raspberry Pi to be `192.168.1.199` 
>- the user to be `probe-rs`
>
>You'll certainly get the gist and be able to change the appropriate parts, if you wish for something different.

#### 4.1 Move `probe-rs`

```
$ scp probe-rs/target/armv7-unknown-linux-gnueabihf/release/probe-rs probe-rs@192.168.1.199:
The authenticity of host '192.168.1.199 (192.168.1.199)' can't be established.
[...]
Are you sure you want to continue connecting (yes/no/[fingerprint])? yes
Warning: Permanently added '192.168.1.199' (ED25519) to the list of known hosts.
probe-rs@192.168.1.199's password: 
probe-rs                				100%   28MB   4.3MB/s   00:06
```

>Note: You were asked for a pw, if the WSL2 instance isn't keypair connected with your Raspberry Pi. Since these are just a rare accesses, entering the pw is fine.

#### 4.2 Repeat for `espflash`

```
$ scp espflash/target/armv7-unknown-linux-gnueabihf/release/espflash probe-rs@192.168.1.199:
probe-rs@192.168.1.199's password: 
espflash                				100%   7450KB   1.9MB/s   00:03
```

>Note: In the above, `probe-rs` is the user-id on the Raspberry Pi.

#### 4.3 Testing (optional)

Once moved, we can test that the binary really runs:

```
$ ssh -q probe-rs@192.168.1.199 -t 'bash -ic "./probe-rs --version"'
probe-rs@192.168.1.199's password: 
probe-rs 0.25.0 (git commit: v0.25.0-5-g9a767f2-modified)
```

Looks good!



### 5. RPi target setup

We now have the binaries on the Raspberry Pi target, but they are slammed right at the home directory of `probe-rs`. Let's move them to a more comfortable position and set up the environment (access rights etc.).

For this, you'll need an `ssh` session to the Raspberry Pi.

```
$ ssh probe-rs@192.168.1.199
[...]
probe-rs@rpi:~ $
```

#### Comfortable location

Move the binaries to `~/bin` (or any destination you fancy), and add that to the `PATH`:

```
probe-rs@rpi:~ $ mkdir bin
probe-rs@rpi:~ $ mv probe-rs bin/
probe-rs@rpi:~ $ mv espflash bin/
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

#### RPi's `udev` configuration

Next, we'll set up [`udev` rules](https://probe.rs/docs/getting-started/probe-setup/#linux%3A-udev-rules) so that accessing the MCUs will not need `root` priviledges.

You'll need to do this from another account on the Raspberry Pi - one that has `sudo` rights.

>```
>$ ssh user@192.168.1.199
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

#### RPi's `plugdev` group

```
user@rpi:~ sudo usermod -a -G plugdev probe-rs
```

Without this, some commands like `probe-rs info` - and flashing - won't work from the `probe-rs` account.

Now, we are ready!!!  


#### Suggestion to keep multiple versions (optional)

Above, we simply moved the binaries to `~/bin` and that's it.

It might be a good idea to keep multiple versions of `probe-rs` and `espflash` around, though. We can easily do this with symbolic links.

```
$ ls -al bin
total 66336
drwxr-xr-x 2 probe-rs probe-rs     4096 Feb  2 23:01 .
drwxr-xr-x 8 probe-rs probe-rs     4096 Feb 13 13:42 ..
lrwxrwxrwx 1 probe-rs probe-rs       14 Feb  2 22:23 espflash -> espflash-3.3.0
-rwxr-xr-x 1 probe-rs probe-rs  7628716 Feb  2 22:22 espflash-3.3.0
lrwxrwxrwx 1 probe-rs probe-rs       15 Feb  2 23:01 probe-rs -> probe-rs.0.26.0
-rwxr-xr-x 1 probe-rs probe-rs 29734992 Dec 30 00:30 probe-rs.0.25.0
-rwxr-xr-x 1 probe-rs probe-rs 30548776 Jan 20 16:09 probe-rs.0.26.0
```

The names of the binaries carry their version, and `~/bin/probe-rs` and `~/bin/espflash` are mere links to the latest version. By changing that link, you can up- or downgrade your actual tool version, without changing anything on the developer account.


## Test with a development board

Let's plug in a development board.

If you want to test `probe-rs`, plug one to the USB/JTAG port. For `espflash`, either USB/UART or USB/JTAG work.

Test the commands:

- first within the Raspberry Pi (signed in as `probe-rs@`)
- if that works, from the developer account, over `ssh`

```
$ probe-rs list
The following debug probes were found:
[0]: ESP JTAG -- 303a:1001:54:32:04:44:74:C0 (EspJtag)
```

```
$ espflash board-info
```

## Appendix A. Multipass and Docker

Instructions on setting up a [Multipass](https://canonical.com/multipass) VM, running Docker.

>Note: The VM will require some 7GB of disk space, in addition to installing Multipass.


Multipass [has `docker` built-in](https://ubuntu.com/blog/docker-on-mac-a-lightweight-option-with-multipass).

```
$ multipass launch docker --memory 4GB --cpus 4
Starting docker /
[...]
```

```
$ multipass shell docker
```


## References

- [`probe-rs` > Crosscompiling](https://probe.rs/docs/library/crosscompiling/)


