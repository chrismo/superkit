#!/usr/bin/env bash

set -euo pipefail

brim_tools=("super" "zq")
reader_progs=("fzf" "glow" "bat")

for brim_tool in "${brim_tools[@]}"; do
  for reader_prog in "${reader_progs[@]}"; do
    echo >&2 "Building ${brim_tool}-${reader_prog} ..."
    docker build \
      --build-arg BRIM_TOOL="${brim_tool}" \
      --build-arg READER_PROG="${reader_prog}" \
      -t superkit:"$brim_tool"-"$reader_prog" \
      -f Dockerfile .
  done
done
