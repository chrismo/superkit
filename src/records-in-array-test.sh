#!/usr/bin/env bash

set -euo pipefail

this_dir=$(dirname "${BASH_SOURCE[0]}")

zq_and_super "$this_dir"/records.spq '{a:1} | sk_in_array(this)' '[{a:1}]'
zq_and_super "$this_dir"/records.spq '[{a:1}] | sk_in_array(this)' '[{a:1}]'
zq_and_super "$this_dir"/records.spq '[[1]] | sk_in_array(this)' '[[1]]'
zq_and_super "$this_dir"/records.spq 'yield 1 | sk_in_array(this)' '[1]'
zq_and_super "$this_dir"/records.spq 'yield "a" | sk_in_array(this)' '["a"]'
zq_and_super "$this_dir"/records.spq '|{"a":1}| | sk_in_array(this)' '[|{"a":1}|]'
