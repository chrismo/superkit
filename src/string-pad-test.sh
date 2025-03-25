#!/usr/bin/env bash

set -euo pipefail

zq_and_super string.spq 'yield sk_pad_right("hey", " ", 3)' '"hey"'
zq_and_super string.spq 'yield sk_pad_right("hey", " ", 4)' '"hey "'

zq_and_super string.spq 'yield sk_pad_right("hey", " ", 2)' '"hey"'
zq_and_super string.spq 'yield sk_pad_right("hey", " ", -1)' '"hey"'

zq_and_super string.spq 'yield sk_pad_right("foo", "-", 100)' \
  '"foo-------------------------------------------------------------------------------------------------"'

# Must call this with yield! Without yield, it raises a Go exception. My hunch
# is because the func is recursive.
