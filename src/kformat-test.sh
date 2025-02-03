#!/usr/bin/env bash

set -euo pipefail

this_dir=$(dirname "${BASH_SOURCE[0]}")

function kformat_bytes_test() {
  local -r input="$1"
  local -r expected="$2"

  type="uint64"
  [ "${input:0:1}" = "-" ] && type="int64"

  _assert "$expected" \
    "$(super -f text -I "$this_dir"/kformat.spq -c "yield $type('$input') | kformat_bytes()")"
}

function kformat_bytes_s_test() {
  local -r input="$1"
  local -r expected="$2"

  _assert "$expected" \
    "$(super -f text -I "$this_dir"/kformat.spq -c "yield int64('$input') | kformat_bytes_s()")"
}

kformat_bytes_test 0 "0 B"
kformat_bytes_test 1 "1 B"
kformat_bytes_test 1023 "1023 B"
kformat_bytes_test 1024 "1 KB"
kformat_bytes_test 1048575 "1023 KB"
kformat_bytes_test 1048576 "1 MB"
kformat_bytes_test 1073741823 "1023 MB"
kformat_bytes_test 1073741824 "1 GB"
kformat_bytes_test 1099511627775 "1023 GB"
kformat_bytes_test 1099511627776 "1 TB"
kformat_bytes_test 1125899906842620 "1023 TB" # TODO: math says TB->PB point (still TB)

# TODO: Here be inaccuracies maybe?
kformat_bytes_test 1125899906842621 "0 PB"    # START three numbers here going 0 PB weirdly
kformat_bytes_test 1125899906842623 "0 PB"    # END   three numbers here going 0 PB weirdly
kformat_bytes_test 1125899906842624 "1 PB"    # this is correct, right?
kformat_bytes_test 1152921504606840767 "1023 PB"
kformat_bytes_test 1152921504606840768 "0 EB" # START numbers that return 0 EB
kformat_bytes_test 1152921504606846911 "0 EB" # END   numbers that return 0 EB
kformat_bytes_test 1152921504606846912 "1 EB" # finally tips to 1 EB, but too early right?
kformat_bytes_test 1152921504606846999 "1 EB"
kformat_bytes_test 1152921504606847000 "1 EB" # math says this should be the PB->EB point (dbl-check)
kformat_bytes_test 2305843009213694000 "2 EB"
kformat_bytes_test 4611686018427388000 "4 EB"
kformat_bytes_test 5764607523034235000 "5 EB"
kformat_bytes_test 8070450532247929000 "7 EB"
kformat_bytes_test 9223372036854775999 ""
kformat_bytes_test 9223372036854776000 ""
kformat_bytes_test 13835058055282164000 ""
kformat_bytes_test 18446744073709551615 "" # This is the MAX uint64 value, but something gives out way before.

# negatives will auto-switch to the signed int type
kformat_bytes_test -1 "-1 B"
kformat_bytes_test -1 "-1 B"
kformat_bytes_test -1023 "-1023 B"
kformat_bytes_test -1024 "-1 KB"
kformat_bytes_test -1048575 "-1023 KB"
kformat_bytes_test -1048576 "-1 MB"
kformat_bytes_test -1073741823 "-1023 MB"
kformat_bytes_test -1073741824 "-1 GB"
kformat_bytes_test -1099511627775 "-1023 GB"
kformat_bytes_test -1099511627776 "-1 TB"
kformat_bytes_test -1125899906842620 "-1023 TB"
