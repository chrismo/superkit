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

filter="${1:-}"
for test_fn in ./src/*-test.sh; do
  [ -n "$filter" ] && [[ "$test_fn" != *$filter* ]] && continue

  # shellcheck disable=SC1090
  source "${test_fn}"
done

echo
