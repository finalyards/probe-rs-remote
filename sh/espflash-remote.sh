#!/bin/bash
set -e

#
# Passes common 'espflash' commands over to a remote computer, via 'ssh'.
#
# Usage:
#   $ PROBE_RS_REMOTE=user@ip espflash-remote.sh [...]
#
# Supported:
#   espflash help|--help
#         board-info
#         erase-flash
#         erase-parts
#         erase-region
#         flash
#         hold-in-reset
#         monitor
#         partition-table
#         reset
#         write-bin
#         checksum-md5
#
# Requires:
#   - ssh
#
_PROBE_CACHE=.probe-rs/elf-cache  # manually create this on the target

if [[ -z "$PROBE_RS_REMOTE" ]]; then
  echo >&2 "'PROBE_RS_REMOTE' env.var not set. Please set it to '{user}@{ip}', to reach the remote 'probe-rs'."
  false
fi

# quote each parameter, separately
quote_params() {
  local buf=()
  for x in "$@"; do
    buf+=("$(printf "%q" "$x")")
  done
  echo "${buf[@]}"
}

case "$1" in
  --*|help|board-info|erase-*|hold-in-reset|monitor|reset|checksum-md5)   # simple commands = no file arguments
    ssh -q $PROBE_RS_REMOTE -t "bash -ic \"espflash $*\""
    ;;

  # Wouldn't have made this without ChatGPT's help!!
  flash|partition-table|write-bin)
    _ALL_BUT_LAST=("${@:1:$#-1}")   # eh-ChatGPT-em
    _LAST="${@: -1}"              # [...]/target/riscv32imac-unknown-none-elf/release/examples/m3

    if [[ ${_LAST} = --* ]]; then   # e.g. 'espflash flash --help'
      ssh -q $PROBE_RS_REMOTE -t "bash -ic \"espflash $*\""
    else
      _ELF_LOCAL=$_LAST
      _ELF_REMOTE=$_PROBE_CACHE/$(basename $_LAST)  # .probe-rs/elf-cache/m3
      _QUOTED_ALL_BUT_LAST=$(quote_params "${_ALL_BUT_LAST[@]}")

      scp $_ELF_LOCAL $PROBE_RS_REMOTE:$_ELF_REMOTE

      # run remote with modified filename
      ssh -q $PROBE_RS_REMOTE -t "bash -ic \"espflash $_QUOTED_ALL_BUT_LAST $_ELF_REMOTE\""
    fi
    ;;
  *)
    echo >&2 <<EOF
Unsupported command: '$1'

This command might exist, but it's not proxied further by '$0'.
EOF
    false
    ;;
esac

