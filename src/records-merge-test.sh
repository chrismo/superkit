#!/usr/bin/env bash

set -euo pipefail

this_dir=$(dirname "${BASH_SOURCE[0]}")

_assert '{a:1,b:2,c:3,d:4}' \
  "$(zq -z -I "$this_dir"/records.spq '[{a:1},{b:2},{c:3},{d:4}] | kmerge_records()')"
_assert '{a:1}' \
  "$(zq -z -I "$this_dir"/records.spq '[{a:1},{a:1}] | kmerge_records()')"
_assert '{a:1,b:"sandwich",c:333}' \
  "$(zq -z -I "$this_dir"/records.spq '[{a:1},{b:"sandwich",c:333}] | kmerge_records()')"
_assert '{a:1,b:{c:333}}' \
  "$(zq -z -I "$this_dir"/records.spq '[{a:1},{b:{c:333}}] | kmerge_records()')"
_assert '{a:1,b:{c:3,d:4},e:[5,{f:6}]}' \
  "$(zq -z -I "$this_dir"/records.spq '[{a:1},{b:{c:3, d:4}},{e:[5, {f:6}]}] | kmerge_records()')"
_assert '{a:1,b:{c:3,d:4},e:[{f:6,g:7}]}' \
  "$(zq -z -I "$this_dir"/records.spq '[{a:1},{b:{c:3, d:4}},{e:[{f:6},{g:7}]}] | kmerge_records()')"
_assert '{a:1,b:{c:{d:2}}}' \
  "$(zq -z -I "$this_dir"/records.spq '[{a:1},{b:{c:{d:2}}}] | kmerge_records()')"

# TODO: this is a fun coincidence from the implementation, but maybe sk could
# include a separate kmap_to_record() func/op
_assert '{a:1,b:2}' \
  "$(zq -z -I "$this_dir"/records.spq '|{"a":1,"b":2}| | kmerge_records()')"
