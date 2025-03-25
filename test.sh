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

function _script_dir() {
  dirname "${BASH_SOURCE[0]}"
}

function _src_dir() {
  echo "$(_script_dir)/src"
}

# TODO: separate executions for each unit test won't scale well at all
# try an sk_unit? :)
function zq_and_super() {
  local -r include_files="$1"
  local -r query="$2"
  local -r expected="$3"

  local -r includes=$(
    super -f line -I "$(_src_dir)/include.spq" -c "
      sk_resolve_includes('$include_files', '$(_src_dir)')
      | f'-I $(_src_dir)/{this}'"
  )

  # shellcheck disable=SC2086
  _assert "$expected" "$(zq -z $includes "$query")"
  # shellcheck disable=SC2086
  _assert "$expected" "$(super -z $includes -c "$query")"
}

filter="${1:-}"
for test_fn in ./src/*-test.sh; do
  [ -n "$filter" ] && [[ "$test_fn" != *$filter* ]] && continue

  # shellcheck disable=SC1090
  source "${test_fn}"
done

echo
echo "asserts: $assert_count"
