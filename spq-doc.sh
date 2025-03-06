#!/usr/bin/env bash

set -euo pipefail

echo "--$(date)--"

cat ./src/format.spq |
super -i line -c '
  const patterns="SKDOC \\{skdoc:.*?\\}func \\w+"

  collect(this)
  | join(this, "")
  | grok(".*?%{SKDOC:skdoc_records}", this, patterns)' -
