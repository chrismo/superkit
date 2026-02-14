#!/usr/bin/env bash

set -euo pipefail

super_test records.spq '{a:1,b:2,c:3,d:4} | sk_keys' \
  '["a","b","c","d"]'
super_test records.spq '[{a:1},{b:2},{c:3},{d:4}] | unnest this | sk_keys' \
  '["a","b","c","d"]'
super_test records.spq '{d:1,b:2,a:3,c:4} | sk_keys' \
  '["d","b","a","c"]'
super_test records.spq '{a:{b:1,c:2}} | sk_keys' \
  '["a"]'
