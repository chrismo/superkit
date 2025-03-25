#!/usr/bin/env bash

set -euo pipefail

zq_and_super array.spq '{a:1} | sk_in_array(this)' '[{a:1}]'
zq_and_super array.spq '[{a:1}] | sk_in_array(this)' '[{a:1}]'
zq_and_super array.spq '[[1]] | sk_in_array(this)' '[[1]]'
zq_and_super array.spq 'yield 1 | sk_in_array(this)' '[1]'
zq_and_super array.spq 'yield "a" | sk_in_array(this)' '["a"]'
zq_and_super array.spq '|{"a":1}| | sk_in_array(this)' '[|{"a":1}|]'
