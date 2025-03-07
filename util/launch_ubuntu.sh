#!/usr/bin/env bash

set -euo pipefail

function _script_dir() {
  dirname "${BASH_SOURCE[0]}"
}

[ "$(docker ps -aq -f name=superkit)" ] && docker rm -f superkit
docker run --name superkit -it superkit:"$1"-"$2" /bin/bash

