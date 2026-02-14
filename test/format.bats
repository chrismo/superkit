#!/usr/bin/env bats

setup() {
  load test_helper
}

sk_format_bytes() {
  local -r input="$1"
  local -r expected="$2"

  local type="uint64"
  [ "${input:0:1}" = "-" ] && type="int64"

  sk_assert_line format.spq "values '${input}'::${type} | sk_format_bytes(this)" "$expected"
}

@test "format_bytes: zero" {
  sk_format_bytes 0 "0 B"
}

@test "format_bytes: 1 byte" {
  sk_format_bytes 1 "1 B"
}

@test "format_bytes: 1023 bytes" {
  sk_format_bytes 1023 "1023 B"
}

@test "format_bytes: 1 KB" {
  sk_format_bytes 1024 "1 KB"
}

@test "format_bytes: 1023 KB" {
  sk_format_bytes 1048575 "1023 KB"
}

@test "format_bytes: 1 MB" {
  sk_format_bytes 1048576 "1 MB"
}

@test "format_bytes: 1023 MB" {
  sk_format_bytes 1073741823 "1023 MB"
}

@test "format_bytes: 1 GB" {
  sk_format_bytes 1073741824 "1 GB"
}

@test "format_bytes: 1023 GB" {
  sk_format_bytes 1099511627775 "1023 GB"
}

@test "format_bytes: 1 TB" {
  sk_format_bytes 1099511627776 "1 TB"
}

@test "format_bytes: 1023 TB" {
  sk_format_bytes 1125899906842620 "1023 TB"
}

# Known inaccuracies - see https://github.com/chrismo/superkit/issues/39

@test "format_bytes: 0 PB edge start" {
  sk_format_bytes 1125899906842621 "0 PB"
}

@test "format_bytes: 0 PB edge end" {
  sk_format_bytes 1125899906842623 "0 PB"
}

@test "format_bytes: 1 PB" {
  sk_format_bytes 1125899906842624 "1 PB"
}

@test "format_bytes: 1023 PB" {
  sk_format_bytes 1152921504606840767 "1023 PB"
}

@test "format_bytes: 0 EB edge start" {
  sk_format_bytes 1152921504606840768 "0 EB"
}

@test "format_bytes: 0 EB edge end" {
  sk_format_bytes 1152921504606846911 "0 EB"
}

@test "format_bytes: 1 EB" {
  sk_format_bytes 1152921504606846912 "1 EB"
}

@test "format_bytes: 2 EB" {
  sk_format_bytes 2305843009213694000 "2 EB"
}

@test "format_bytes: 4 EB" {
  sk_format_bytes 4611686018427388000 "4 EB"
}

@test "format_bytes: 8 EB" {
  sk_format_bytes 9223372036854776000 "8 EB"
}

@test "format_bytes: 12 EB" {
  sk_format_bytes 13835058055282164000 "12 EB"
}

@test "format_bytes: 16 EB max uint64" {
  sk_format_bytes 18446744073709551615 "16 EB"
}
