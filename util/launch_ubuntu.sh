#!/usr/bin/env bash

set -euo pipefail

# to test installation on a clean machine

docker build -f ./sk-ubuntu.dockerfile -t superkit .

[ "$(docker ps -aq -f name=superkit)" ] && docker rm -f superkit
docker run --name superkit -it superkit:latest /bin/bash
