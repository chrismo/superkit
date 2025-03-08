#!/usr/bin/env bash

branch="${1:-main}"
release="${2:-}"

curl -fsS https://raw.githubusercontent.com/chrismo/superkit/refs/heads/"$branch"/install.sh |
  RELEASE="$release" bash
