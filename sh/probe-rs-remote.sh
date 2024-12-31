#!/bin/bash
set -e

#
# Passes common 'probe-rs' commands over to a remote computer, via 'ssh'.
#
# Usage:
#   $ PROBE_RS_REMOTE=user@ip probe-rs-remote.sh [...]
#
# Supported:
#   probe-rs help|--help
#           list
#           info [options]
#           erase [options]
#           reset [options]
#           run [options] {path-to-elf-file}    | transfers the ELF file over
#
# Requires:
#   - ssh
#
# Credits:
#   - ChatGPT (31-dec-24) was _instrumental_ in getting the syntax (bash arrays and quoting) right! :)
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
  --*|help|list|info|erase|reset)   # simple commands = no file arguments
    ssh -q $PROBE_RS_REMOTE -t "bash -ic \"probe-rs $*\""
    ;;

  # Wouldn't have made this without ChatGPT's help!!
  run)
    _ALL_BUT_LAST=("${@:1:$#-1}")   # eh-ChatGPT-em
    _LAST="${@: -1}"              # [...]/target/riscv32imac-unknown-none-elf/release/examples/m3

    _ELF_LOCAL=$_LAST
    _ELF_REMOTE=$_PROBE_CACHE/$(basename $_LAST)  # .probe-rs/elf-cache/m3
    _QUOTED_ALL_BUT_LAST=$(quote_params "${_ALL_BUT_LAST[@]}")

    scp $_ELF_LOCAL $PROBE_RS_REMOTE:$_ELF_REMOTE

    # run remote with modified filename
    ssh -q $PROBE_RS_REMOTE -t "bash -ic \"probe-rs $_QUOTED_ALL_BUT_LAST $_ELF_REMOTE\""
    ;;

  *)
    echo >&2 "Unsupported command: '$1'"
    false
    ;;
esac

