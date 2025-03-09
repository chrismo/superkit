#!/usr/bin/env bash

set -euo pipefail

function _check_command() {
  command -v "$1" &>/dev/null
}

function disable-bin() {
  local -r fn="$1"
  local -r suffix="-disabled"

  if _check_command "$fn$suffix"; then
    echo "$fn is $suffix"
  else
    sudo mv -v "$fn" "$fn$suffix"
  fi
}

function enable-bin() {
  local -r fn="$1"
  local -r suffix="-disabled"

  if _check_command "$fn$suffix"; then
    sudo mv -v "$fn$suffix" "$fn"
    command "$fn" --version
  else
    if _check_command "$fn"; then
      command "$fn" --version
    else
      echo "$fn is not found"
    fi
  fi
}

function enabler() {
  if [ "$bat" == "-" ]; then
    disable-bin "/home/devnull/.local/bin/bat"
  elif [ "$bat" == "+" ]; then
    enable-bin "/home/devnull/.local/bin/bat"
  fi

  if [ "$fzf_old" == "-" ]; then
    disable-bin "/usr/bin/fzf"
  elif [ "$fzf_old" == "+" ]; then
    sudo cp /home/devnull/fzf-old /usr/bin/fzf
  fi

  if [ "$fzf_new" == "-" ]; then
    disable-bin "/usr/bin/fzf"
  elif [ "$fzf_new" == "+" ]; then
    sudo cp /home/devnull/fzf-new /usr/bin/fzf
  fi

  if [ "$glow" == "-" ]; then
    disable-bin "/home/devnull/.local/bin/glow"
  elif [ "$glow" == "+" ]; then
    enable-bin "/home/devnull/.local/bin/glow"
  fi

  if [ "$super" == "-" ]; then
    disable-bin "/usr/local/bin/super"
  elif [ "$super" == "+" ]; then
    enable-bin "/usr/local/bin/super"
  fi

  if [ "$zq" == "-" ]; then
    disable-bin "/usr/bin/zq"
  elif [ "$zq" == "+" ]; then
    enable-bin "/usr/bin/zq"
  fi
}

function _usage() {
  cat <<EOF
  -b  Enable bat
  -b- Disable bat
  -f  Enable fzf
  -f- Disable fzf
  -g  Enable glow
  -g- Disable glow
  -s  Enable super
  -s- Disable super
  -z  Enable zq
  -z- Disable zq
EOF
}

function usage() {
  _usage | less -FX
}

declare bat=""
declare fzf_old=""
declare fzf_new=""
declare glow=""
declare super=""
declare zq=""

if [ $# -eq 0 ]; then
  usage
else
  while [ $# -gt 0 ]; do
    # ugly, but it works
    case "$1" in
    -h)
      usage
      exit 0
      ;;
    -b)
      bat="+"
      ;;
    -b-)
      bat="-"
      ;;
    -f-old)
      fzf_old="+"
      ;;
    -f-old-)
      fzf_old="-"
      ;;
    -f-new)
      fzf_new="+"
      ;;
    -f-new-)
      fzf_new="-"
      ;;
    -f)
      fzf_old="+"
      ;;
    -f-)
      fzf_old="-"
      ;;
    -g)
      glow="+"
      ;;
    -g-)
      glow="-"
      ;;
    -s)
      super="+"
      ;;
    -s-)
      super="-"
      ;;
    -z)
      zq="+"
      ;;
    -z-)
      zq="-"
      ;;
    *)
      echo "Invalid option: $1"
      usage
      exit 1
      ;;
    esac
    shift
  done

  enabler
fi
