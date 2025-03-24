#!/usr/bin/env bash

set -euo pipefail

zq_and_super integer.spq,string.spq 'yield sk_slice("hey", 0, 3)' '"hey"'
zq_and_super integer.spq,string.spq 'yield sk_slice("hey", 0, 4)' '"hey"'
zq_and_super integer.spq,string.spq 'yield sk_slice("hey", 0, -1)' '"he"'
zq_and_super integer.spq,string.spq 'yield sk_slice("hey", 0, -2)' '"h"'
zq_and_super integer.spq,string.spq 'yield sk_slice("hey", 0, -3)' '""'
zq_and_super integer.spq,string.spq 'yield sk_slice("hey", 0, -4)' '""'
zq_and_super integer.spq,string.spq 'yield sk_slice("hey", 3, 3)' '""'
zq_and_super integer.spq,string.spq 'yield sk_slice("hey", 400, 3)' '""'
zq_and_super integer.spq,string.spq 'yield sk_slice("hey", -2, -1)' '"e"'
zq_and_super integer.spq,string.spq 'yield sk_slice("hey", -4, -1)' '"he"'
zq_and_super integer.spq,string.spq 'yield sk_slice("hey", -4, 4)' '"hey"'
