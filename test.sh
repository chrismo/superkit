#!/usr/bin/env bash

set -euo pipefail

declare assert_count=0
echo "*** Running tests $(date) ***"

function _assert() {
  local -r expected="$1"
  local -r actual="$2"

  ((assert_count++))

  if [ "$expected" != "$actual" ]; then
    echo "test failed: expected <$expected> actual <$actual>"
  else
    echo -n '.'
  fi
}

function zq_and_super() {
  local -r include="$1"
  local -r query="$2"
  local -r expected="$3"

  _assert "$expected" "$(zq -z -I "$include" "$query")"
  _assert "$expected" "$(super -z -I "$include" -c "$query")"
}

filter="${1:-}"
for test_fn in ./src/*-test.sh; do
  [ -n "$filter" ] && [[ "$test_fn" != *$filter* ]] && continue

  # shellcheck disable=SC1090
  source "${test_fn}"
done

echo
echo "asserts: $assert_count"
