#!/usr/bin/env bash

set -euo pipefail

zq_and_super array.spq '{a:1} | sk_in_array(this)' '[{a:1}]'
zq_and_super array.spq '[{a:1}] | sk_in_array(this)' '[{a:1}]'
zq_and_super array.spq '[[1]] | sk_in_array(this)' '[[1]]'
zq_and_super array.spq 'yield 1 | sk_in_array(this)' '[1]'
zq_and_super array.spq 'yield "a" | sk_in_array(this)' '["a"]'
zq_and_super array.spq '|{"a":1}| | sk_in_array(this)' '[|{"a":1}|]'

zq_and_super array.spq '[] | sk_in_array(this)' '[]'

# this is a consequence of the whole "no matches with where" returns a kind of
# 'nothing' that cannot be detected or acted on in any way.
# https://github.com/brimdata/super/issues/4708
zq_and_super array.spq '[] | over this | where a==1 | sk_in_array(this)' ''
