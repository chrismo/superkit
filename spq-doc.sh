#!/usr/bin/env bash

set -euo pipefail

echo "--$(date)--"

cat ./src/format.spq |
super -i line -c '
  const patterns="SKDOC \\{skdoc:.*?\\}func \\w+"

  collect(this)    // collect all lines to get the entire file
  | join(this, "") // make it all one string
  | split(this, "{skdoc")[1:] // drop the 0th item before the first occurrence
  | over this
  | f"\{skdoc{this}" // restore the split on bit
  | grok(".*?%{SKDOC:skdoc_record}", this, patterns)' -
