#!/usr/bin/env bash

set -euo pipefail

# to test installation on a clean machine

[ "$(docker ps -aq -f name=superkit)" ] && docker rm -f superkit

# tail is a cheap trick to keep it running, but you'll have to
# ctrl-c to stop it after this script finishes
docker run --name superkit -d ubuntu:jammy tail -f /dev/null

docker exec superkit bash -c "
adduser --disabled-password --gecos '' devnull &&
usermod -aG sudo devnull
"

docker exec -it superkit su - devnull

docker stop superkit
