#!/usr/bin/env bash

set -euo pipefail

function _script_dir() {
  dirname "${BASH_SOURCE[0]}"
}

function default() {

  docker build -f "$(_script_dir)"/sk-ubuntu.dockerfile \
    $install_bat $install_fzf $install_glow $install_super $install_zq \
    --progress plain \
    -t superkit .

  [ "$(docker ps -aq -f name=superkit)" ] && docker rm -f superkit
  docker run --name superkit -it superkit:latest /bin/bash
}

function _usage() {
  cat <<EOF
-b  Install bat
-f  Install fzf
-g  Install glow
-s  Install super
-z  Install zq
EOF
}

function usage() {
  _usage | less -FX
}

declare install_bat
declare install_glow
declare install_fzf
declare install_super
declare install_zq

if [ $# -eq 0 ]; then
  default
else
  while getopts "hbfgsz" opt; do
    case $opt in
    h)
      usage
      exit 0
      ;;
    b) install_bat="--build-arg install_bat=true" ;;
    f) install_fzf="--build-arg install_fzf=true" ;;
    g) install_glow="--build-arg install_glow=true" ;;
    s) install_super="--build-arg install_super=true" ;;
    z) install_zq="--build-arg install_zq=true" ;;
    \?) # ignore invalid options
      ;;
    esac
  done

  # Remove options processed by getopts, so the remaining args can be handled
  # positionally.
  shift $((OPTIND - 1))

  default "$@"
fi
