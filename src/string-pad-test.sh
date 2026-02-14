#!/usr/bin/env bash

set -euo pipefail

super_test string.spq,integer.spq 'values sk_pad_right("hey", " ", 3)' '"hey"'
super_test string.spq,integer.spq 'values sk_pad_right("hey", " ", 4)' '"hey "'

super_test string.spq,integer.spq 'values sk_pad_right("hey", " ", 2)' '"hey"'
super_test string.spq,integer.spq 'values sk_pad_right("hey", " ", -1)' '"hey"'

super_test string.spq,integer.spq 'values sk_pad_right("foo", "-", 100)' \
  '"foo-------------------------------------------------------------------------------------------------"'

# Must call this with values! Without values, it raises a Go exception. My hunch
# is because the func is recursive.
