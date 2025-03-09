#!/usr/bin/env bash

set -euo pipefail

function reader_opts() {
  local -r index="$1"

  case $index in
  glow) echo "-g -b-" ;;
  bat) echo "-b -g-" ;;
  less) echo "-g- -b-" ;;
  esac
}

function index_opts() {
  local -r index="$1"

  case $index in
  glow) echo "-g -f-" ;;
  fzf) echo "-f -g-" ;;
  less) echo "-g- -f-" ;;
  esac
}

function brim_opts() {
  local -r tool="$1"

  case $tool in
  super) echo "-s -z-" ;;
  zq) echo "-z -s-" ;;
  none) echo "-s- -z-" ;;
  esac
}

# shellcheck disable=SC2016
# shellcheck disable=SC2162
# shellcheck disable=SC2046
function skdoc() {
  echo "skdoc *glob* depends on glow, bat, \$PAGER, less"
  for reader in glow bat less; do
    ./enabler.sh $(reader_opts "$reader")

    # TODO: `skdoc subq` gives weird results
    echo 'Test `skdoc grok`'
    read -p "Continue? (y/N): " confirm && [[ $confirm == [yY] ]] || return
  done

  echo '`skdoc` (index) depends on glow, fzf, \$PAGER, less'
  echo "(after selection, the it depends on reader, which we just tested)"
  for index in glow fzf less; do
    ./enabler.sh $(index_opts "$index")

    echo 'Test `skdoc` (index)'
    read -p "Continue? (y/N): " confirm && [[ $confirm == [yY] ]] || return
  done
}

# shellcheck disable=SC2046
# shellcheck disable=SC2016
function skgrok() {
  echo "skgrok depends on super or zq, then fzf or \$PAGER -> less"
  for index in fzf less; do
    for brim in super zq none; do
      ./enabler.sh $(brim_opts "$brim")
      ./enabler.sh $(index_opts "$index")

      echo 'Test `skgrok`'
      read -p "Continue? (y/N): " confirm && [[ $confirm == [yY] ]] || return
    done
  done
}

# shellcheck disable=SC2046
# shellcheck disable=SC2016
function skops() {
  echo "skops depends on super or zq, then fzf or \$PAGER -> less"
  for index in fzf less; do
    for brim in super zq none; do
      ./enabler.sh $(brim_opts "$brim")
      ./enabler.sh $(index_opts "$index")

      echo 'Test `skgrok`'
      read -p "Continue? (y/N): " confirm && [[ $confirm == [yY] ]] || return
    done
  done
}

function default() {
  skdoc
  skgrok
  skops
}

function _usage() {
  grep -E '^function' "${BASH_SOURCE[0]}" | sort
}

function usage() {
  _usage | less -FX
}

if [ $# -eq 0 ]; then
  default
else
  while getopts "ho:" opt; do
    case $opt in
    h)
      usage
      exit 0
      ;;
    o) opt="$OPTARG" ;;
    \?) # ignore invalid options
      ;;
    esac
  done

  # Remove options processed by getopts, so the remaining args can be handled
  # positionally.
  shift $((OPTIND - 1))

  "$@"
fi
