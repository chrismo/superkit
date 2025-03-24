#!/usr/bin/env bash

set -euo pipefail

zq_and_super integer.spq,string.spq 'sk_capitalize("hey")' '"Hey"'
zq_and_super integer.spq,string.spq 'sk_capitalize("hey you")' '"Hey you"'
zq_and_super integer.spq,string.spq 'yield "hey you" | sk_capitalize(this)' '"Hey you"'

zq_and_super integer.spq,string.spq 'sk_titleize("hey you")' '"Hey You"'
zq_and_super integer.spq,string.spq 'sk_titleize("hey  you")' '"Hey  You"'
