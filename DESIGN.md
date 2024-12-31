# Design considerations

## Alternatives considered: USB/IP

Another approach is using USB/IP. This moves the airgap from *before* `probe-rs` to *after* it.

**Cons**

- The flashing speed is often < 2 KiB/s (over WLAN, one hop). We've reached a 15x improvement (or down from 2min -> 6s) by running `probe-rs` near the embedded device.

	This is due to the JTAG protocol using lots of small packets, and round trip logic. `espflash` tool is speedier, but introduces a different ecosystem, if we still use `probe-rs` for monitoring.

- The connection needs to be re-attached each time the MCU is unplugged/restarted.

	This can cause quite a bit of development friction. When `probe-rs` is being used remotely, it automatically sees devices once they are reconnected/restarted.

**Neutral**

- Remote setup is roughly as complicated as for `probe-rs` remote.

**Pros**

- USB/IP is cool!

Thus, in practical work it's clear remote `probe-rs` is a more transparent, and faster solution.

