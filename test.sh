#!/usr/bin/env bash

set -euo pipefail

function _assert() {
  local -r expected="$1"
  local -r actual="$2"

  if [ "$expected" != "$actual" ]; then
    echo "test failed: expected <$expected> actual <$actual>"
  else
    echo -n '.'
  fi
}

for test_fn in ./src/*-test.sh; do
  # shellcheck disable=SC1090
  source "${test_fn}"
done

echo
