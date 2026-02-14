#!/usr/bin/env bash

set -euo pipefail

super_test string.spq,integer.spq 'sk_capitalize("hey")' '"Hey"'
super_test string.spq,integer.spq 'sk_capitalize("hey you")' '"Hey you"'
super_test string.spq,integer.spq 'values "hey you" | sk_capitalize(this)' '"Hey you"'

super_test string.spq,integer.spq 'sk_titleize("hey you")' '"Hey You"'
super_test string.spq,integer.spq 'sk_titleize("hey  you")' '"Hey  You"'
super_test string.spq,integer.spq 'sk_titleize("HEY yOu")' '"Hey You"'
