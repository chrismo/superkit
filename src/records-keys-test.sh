#!/usr/bin/env bash

set -euo pipefail

this_dir=$(dirname "${BASH_SOURCE[0]}")

_assert '["a","b","c","d"]' \
  "$(zq -z -I "$this_dir"/records.spq '{a:1,b:2,c:3,d:4} | sk_keys()')"
_assert '["a","b","c","d"]' \
  "$(zq -z -I "$this_dir"/records.spq '[{a:1},{b:2},{c:3},{d:4}] | over this | sk_keys()')"
_assert '["d","b","a","c"]' \
  "$(zq -z -I "$this_dir"/records.spq '{d:1,b:2,a:3,c:4} | sk_keys()')"
_assert '["a"]' \
  "$(zq -z -I "$this_dir"/records.spq '{a:{b:1,c:2}} | sk_keys()')"
