#!/usr/bin/env bash

set -euo pipefail

echo "--$(date)--"

# TODO: move this into the src dir as proper sk_ functions with unit tests
# so it can be re-used in the wild, too.

cat ./src/format.spq |
super -i line -Z -c '
  const patterns="SKDOC \\{skdoc:.*?\\}func \\w+"

  op parse_skdoc_record(sk_record): (
    regexp_replace(sk_record, "//", "") // remove comment chars
    | grok("%{DATA:skdoc}func %{WORD:func_name}", this)
    | skdoc:=parse_zson(skdoc).skdoc
    | order(this, <{}>)
  )

  collect(this)               // collect all lines to get the entire file
  | join(this, "")            // make it all one string
  | split(this, "{skdoc")[1:] // drop the 0th item before the first occurrence
  | over this
  | f"\{skdoc{this}"          // restore text removed by split func
  | grok(".*?%{SKDOC:skdoc_record}", this, patterns)
  | parse_skdoc_record(this.skdoc_record)' -
