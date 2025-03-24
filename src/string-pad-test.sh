#!/usr/bin/env bash

set -euo pipefail

# TODO: even though sk_pad_right doesn't depend en integer.spq, for parsing
# successfully it still does :/ I thought I checked this case out?
#
# If it does require it, then it'd be nice to not require dependencies for every
# test. And I need to think longer about how my file organization should scale.
#
# Probably faster to just have the test.sh "build" the final single superkit.spq
# file and run all tests against it anyway,

zq_and_super integer.spq,string.spq 'yield sk_pad_right("hey", " ", 3)' '"hey"'
zq_and_super integer.spq,string.spq 'yield sk_pad_right("hey", " ", 4)' '"hey "'

zq_and_super integer.spq,string.spq 'yield sk_pad_right("hey", " ", 2)' '"hey"'
zq_and_super integer.spq,string.spq 'yield sk_pad_right("hey", " ", -1)' '"hey"'

zq_and_super integer.spq,string.spq 'yield sk_pad_right("foo", "-", 100)' \
  '"foo-------------------------------------------------------------------------------------------------"'

# Must call this with yield! Without yield, it raises a Go exception. My hunch
# is because the func is recursive.
