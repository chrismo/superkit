#!/usr/bin/env bash

set -euo pipefail

function _script_dir() {
  dirname "${BASH_SOURCE[0]}"
}

docker build -f "$(_script_dir)"/sk-ubuntu.dockerfile -t superkit .

[ "$(docker ps -aq -f name=superkit)" ] && docker rm -f superkit
docker run --name superkit -it superkit:latest /bin/bash
