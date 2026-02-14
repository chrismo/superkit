SRC_DIR="$(cd "$(dirname "${BATS_TEST_FILENAME}")/../src" && pwd)"

# Run a super query with includes and assert the output matches expected.
# Usage: sk_run "include1.spq,include2.spq" "query"
# Then check $output against expected value.
sk_run() {
  local -r include_files="$1"
  local -r query="$2"

  local includes=""
  for f in $(echo "$include_files" | tr ',' '\n'); do
    includes="$includes -I ${SRC_DIR}/$f"
  done

  # shellcheck disable=SC2086
  run super -s $includes -c "$query"
}

# Convenience: run and assert in one call
# Usage: sk_assert "include.spq" "query" "expected output"
sk_assert() {
  sk_run "$1" "$2"
  [ "$status" -eq 0 ] || {
    echo "super failed with status $status"
    echo "stderr: $output"
    return 1
  }
  [ "$output" = "$3" ] || {
    echo "expected: <$3>"
    echo "actual:   <$output>"
    return 1
  }
}

# Like sk_assert but uses -f line for clean output
sk_assert_line() {
  local -r include_files="$1"
  local -r query="$2"
  local -r expected="$3"

  local includes=""
  for f in $(echo "$include_files" | tr ',' '\n'); do
    includes="$includes -I ${SRC_DIR}/$f"
  done

  # shellcheck disable=SC2086
  run super -f line $includes -c "$query"
  [ "$status" -eq 0 ] || {
    echo "super failed with status $status"
    echo "stderr: $output"
    return 1
  }
  [ "$output" = "$expected" ] || {
    echo "expected: <$expected>"
    echo "actual:   <$output>"
    return 1
  }
}
