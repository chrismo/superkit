#!/usr/bin/env bash

branch="${1:-main}"

curl -fsS https://raw.githubusercontent.com/chrismo/superkit/refs/heads/$branch/install.sh |
  REPO_BRANCH=$branch bash
