#!/usr/bin/env bash

set -euo pipefail

this_dir=$(dirname "${BASH_SOURCE[0]}")

function sk_format_bytes_test() {
  local -r input="$1"
  local -r expected="$2"

  type="uint64"
  [ "${input:0:1}" = "-" ] && type="int64"

  _assert "$expected" \
    "$(super -f text -I "$this_dir"/format.spq -c "yield $type('$input') | sk_format_bytes(this)")"
}

sk_format_bytes_test 0 "0 B"
sk_format_bytes_test 1 "1 B"
sk_format_bytes_test 1023 "1023 B"
sk_format_bytes_test 1024 "1 KB"
sk_format_bytes_test 1048575 "1023 KB"
sk_format_bytes_test 1048576 "1 MB"
sk_format_bytes_test 1073741823 "1023 MB"
sk_format_bytes_test 1073741824 "1 GB"
sk_format_bytes_test 1099511627775 "1023 GB"
sk_format_bytes_test 1099511627776 "1 TB"
# TODO: add some intermediate tipping points (better term?) from 1 TB to 2 TB
sk_format_bytes_test 1125899906842620 "1023 TB" # TODO: math says TB->PB point (still TB)

# TODO: Here be inaccuracies ... 0 PB is, well, wrong.
sk_format_bytes_test 1125899906842621 "0 PB"    # START three numbers here going 0 PB weirdly
sk_format_bytes_test 1125899906842623 "0 PB"    # END   three numbers here going 0 PB weirdly
sk_format_bytes_test 1125899906842624 "1 PB"    # this is correct, right?
sk_format_bytes_test 1152921504606840767 "1023 PB"
sk_format_bytes_test 1152921504606840768 "0 EB" # START numbers that return 0 EB
sk_format_bytes_test 1152921504606846911 "0 EB" # END   numbers that return 0 EB
sk_format_bytes_test 1152921504606846912 "1 EB" # finally tips to 1 EB, but too early right?
sk_format_bytes_test 1152921504606846999 "1 EB"
sk_format_bytes_test 1152921504606847000 "1 EB" # math says this should be the PB->EB point (dbl-check)
sk_format_bytes_test 2305843009213694000 "2 EB"
sk_format_bytes_test 4611686018427388000 "4 EB"
sk_format_bytes_test 5764607523034235000 "5 EB"
sk_format_bytes_test 8070450532247929000 "7 EB"
sk_format_bytes_test 9223372036854775999 "8 EB"
sk_format_bytes_test 9223372036854776000 "8 EB"
sk_format_bytes_test 13835058055282164000 "12 EB"
sk_format_bytes_test 18446744073709551614 "16 EB" # i guess this is rounding stuff?
sk_format_bytes_test 18446744073709551615 "16 EB" # this is the tipping point?

# negative values not supported. If you really need a negative value, do the
# positive and prepend a hyphen? ¯\_(ツ)_/¯

# TODO: research the possible division bugs/gotchyas with large EB values?
#       in the pipeline version of this?
#     default => {k: 1024, data: value}
#    | i:=uint64(floor(log(this.data) / log(this.k)))
#    | result:=uint64(this.data / pow(this.k, this.i))
#    | yield f"{this.result} {k_units[this.i]}"
