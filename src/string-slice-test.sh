#!/usr/bin/env bash

set -euo pipefail

super_test string.spq,integer.spq 'values sk_slice("hey", 0, 3)' '"hey"'
super_test string.spq,integer.spq 'values sk_slice("hey", 0, 4)' '"hey"'
super_test string.spq,integer.spq 'values sk_slice("hey", 0, -1)' '"he"'
super_test string.spq,integer.spq 'values sk_slice("hey", 0, -2)' '"h"'
super_test string.spq,integer.spq 'values sk_slice("hey", 0, -3)' '""'
super_test string.spq,integer.spq 'values sk_slice("hey", 0, -4)' '""'
super_test string.spq,integer.spq 'values sk_slice("hey", 3, 3)' '""'
super_test string.spq,integer.spq 'values sk_slice("hey", 400, 3)' '""'
super_test string.spq,integer.spq 'values sk_slice("hey", -2, -1)' '"e"'
super_test string.spq,integer.spq 'values sk_slice("hey", -4, -1)' '"he"'
super_test string.spq,integer.spq 'values sk_slice("hey", -4, 4)' '"hey"'
