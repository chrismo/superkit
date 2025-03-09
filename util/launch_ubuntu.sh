#!/usr/bin/env bash

set -euo pipefail

function _script_dir() {
  dirname "${BASH_SOURCE[0]}"
}

function default() {

  docker build -f "$(_script_dir)"/sk-ubuntu.dockerfile \
    --progress plain \
    -t superkit .

  [ "$(docker ps -aq -f name=superkit)" ] && docker rm -f superkit
  docker run --name superkit -it superkit:latest /bin/bash
}

default
