#!/usr/bin/env bash

set -euo pipefail

function default() {
  local -r filter="${1:-}"
  # -mdpath="../../superkit/src"

  pushd ../super
  # -v for verbose output
  go test -v -tags=kit ./mdtest -mdfilter="$filter"
  popd
}

function v() {
  pushd ../super
  go test -v -tags=kit ./mdtest | grep TestMarkdownExamples
  popd
}

default "$@"

