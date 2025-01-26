#!/usr/bin/env bash

set -euo pipefail

function default() {
  pushd ../super
  go test -tags=kit ./mdtest
  popd
}

function v() {
  pushd ../super
  go test -v -tags=kit ./mdtest | grep TestMarkdownExamples
  popd
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
