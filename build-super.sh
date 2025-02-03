#!/usr/bin/env bash

set -euo pipefail

echo "building super"
pushd ../super
make clean build install
cp ./dist/super /usr/local/bin
ls -la /usr/local/bin/super
super --version
echo "Version: $(git describe --tags --dirty --always)"
popd
