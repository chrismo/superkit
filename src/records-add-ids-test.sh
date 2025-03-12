#!/usr/bin/env bash

set -euo pipefail

this_dir=$(dirname "${BASH_SOURCE[0]}")

zq_and_super "$this_dir"/records.spq '{foo:"bar"} | sk_add_ids()' \
  '[{id:1,foo:"bar"}]'
zq_and_super "$this_dir"/records.spq '[{foo:"bar"}] | over this | sk_add_ids()' \
  '[{id:1,foo:"bar"}]'
zq_and_super "$this_dir"/records.spq '[{a:"a"},{b:"b"}] | over this | sk_add_ids()' \
  '[{id:1,a:"a"},{id:2,b:"b"}]'
zq_and_super "$this_dir"/records.spq '[{id:1}] | sk_add_ids()' \
  '[{id:1}]'
zq_and_super "$this_dir"/records.spq '[{foo:"bar",id:2}] | sk_add_ids()' \
  '[{id:2,foo:"bar"}]'
zq_and_super "$this_dir"/records.spq 'yield 1 | sk_add_ids()' \
  '[{id:1}]'
