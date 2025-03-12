#!/usr/bin/env bash

set -euo pipefail

this_dir=$(dirname "${BASH_SOURCE[0]}")

zq_and_super "$this_dir"/records.spq '[{a:1},{b:2},{c:3},{d:4}] | sk_merge_records()' \
 '{a:1,b:2,c:3,d:4}'
zq_and_super "$this_dir"/records.spq '[{a:1},{a:1}] | sk_merge_records()' \
 '{a:1}'
zq_and_super "$this_dir"/records.spq '[{a:1},{b:"sandwich",c:333}] | sk_merge_records()' \
 '{a:1,b:"sandwich",c:333}'
zq_and_super "$this_dir"/records.spq '[{a:1},{b:{c:333}}] | sk_merge_records()' \
 '{a:1,b:{c:333}}'
zq_and_super "$this_dir"/records.spq '[{a:1},{b:{c:3, d:4}},{e:[5, {f:6}]}] | sk_merge_records()' \
 '{a:1,b:{c:3,d:4},e:[5,{f:6}]}'
zq_and_super "$this_dir"/records.spq '[{a:1},{b:{c:3, d:4}},{e:[{f:6},{g:7}]}] | sk_merge_records()' \
 '{a:1,b:{c:3,d:4},e:[{f:6,g:7}]}'
zq_and_super "$this_dir"/records.spq '[{a:1},{b:{c:{d:2}}}] | sk_merge_records()' \
 '{a:1,b:{c:{d:2}}}'

# TODO: this is a fun coincidence from the implementation, but maybe sk could
# include a separate kmap_to_record() func/op
zq_and_super "$this_dir"/records.spq '|{"a":1,"b":2}| | sk_merge_records()' \
 '{a:1,b:2}'
