#!/usr/bin/env bash

set -euo pipefail

super_test records.spq,array.spq '{foo:"bar"} | sk_add_ids' \
  '[{id:1,foo:"bar"}]'
super_test records.spq,array.spq '[{foo:"bar"}] | unnest this | sk_add_ids' \
  '[{id:1,foo:"bar"}]'
super_test records.spq,array.spq '[{a:"a"},{b:"b"}] | unnest this | sk_add_ids' \
  '[{id:1,a:"a"},{id:2,b:"b"}]'
super_test records.spq,array.spq '[{id:1}] | sk_add_ids' \
  '[{id:1}]'
super_test records.spq,array.spq '[{foo:"bar",id:2}] | sk_add_ids' \
  '[{id:2,foo:"bar"}]'
super_test records.spq,array.spq 'values 1 | sk_add_ids' \
  '[{id:1}]'
