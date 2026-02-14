#!/usr/bin/env bash

set -euo pipefail

super_test array.spq '{a:1} | sk_in_array(this)' '[{a:1}]'
super_test array.spq '[{a:1}] | sk_in_array(this)' '[{a:1}]'
super_test array.spq '[[1]] | sk_in_array(this)' '[[1]]'
super_test array.spq 'values 1 | sk_in_array(this)' '[1]'
super_test array.spq 'values "a" | sk_in_array(this)' '["a"]'
super_test array.spq '|{"a":1}| | sk_in_array(this)' '[|{"a":1}|]'

super_test array.spq '[] | sk_in_array(this)' '[]'

# this is a consequence of the whole "no matches with where" returns a kind of
# 'nothing' that cannot be detected or acted on in any way.
# https://github.com/brimdata/super/issues/4708
super_test array.spq '[] | unnest this | where a==1 | sk_in_array(this)' ''
