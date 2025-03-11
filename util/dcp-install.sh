#!/usr/bin/env bash

set -euo pipefail

function _script_dir() {
  dirname "${BASH_SOURCE[0]}"
}

docker exec -it superkit mkdir -p /home/devnull/dist
docker cp "$(_script_dir)"/../dist/superkit.tar.gz superkit:/home/devnull/dist/superkit.tar.gz
docker cp "$(_script_dir)"/../install.sh superkit:/home/devnull/
docker exec -it -e LOCAL_INSTALL=1 superkit /home/devnull/install.sh
