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
#         flash [--partition-table <file>]
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
      #r _QUOTED_ALL_BUT_LAST=$(quote_params "${_ALL_BUT_LAST[@]}")

      # If '--partition-table <file>' is there, we need to a) upload the file, b) modify the file parameter.
      #
      # COPILOT implemented block
      _UPDATED_ARGS=()
      _PT_REMOTE=""
      i=0
      while [[ $i -lt ${#_ALL_BUT_LAST[@]} ]]; do
        arg="${_ALL_BUT_LAST[$i]}"

        if [[ "$arg" == "--partition-table" ]]; then
          pt_local="${_ALL_BUT_LAST[$((i+1))]}"
          pt_base=$(basename "$pt_local")
          pt_remote="$_PROBE_CACHE/$pt_base"

          echo "Uploading partition table: $pt_local → $pt_remote"
          scp "$pt_local" "$PROBE_RS_REMOTE:$pt_remote"

          # Replace the pair in the argument list
          _UPDATED_ARGS+=("--partition-table" "$pt_remote")

          # Skip next argument (the filename)
          i=$((i+2))
          continue
        fi

        _UPDATED_ARGS+=("$arg")
        i=$((i+1))
      done

      # Replace original quoted args with updated ones
      _QUOTED_ALL_BUT_LAST=$(quote_params "${_UPDATED_ARGS[@]}")
      #/COPILOT

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

