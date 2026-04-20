# Known issues

## espflash, ESP-IDF: Support for custom partitions file is only partial

When using a custom `partitions.csv`, the tool now supports `--partitions-table {file}` parameter.

It does *not* support:

- `espflash.toml`
- project metadata (in `Cargo.toml`)

The author does not really need these features. If implementing them, one should:

- check what the behaviour of `espflash` itself (CLI) is, vs. `cargo espflash`. We should only aim to be on-par with what the `espflash` CLI does, being a plug-and-play replacement.

>It's likely nothing is going to happen about this. Wanted to document that the ESP-IDF partitions support is partial.