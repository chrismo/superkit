#!/usr/bin/env bash

set -euo pipefail

zq_and_super integer.spq 'sk_clamp(1,2,3)' '2'
zq_and_super integer.spq 'sk_clamp(4,2,3)' '3'

zq_and_super integer.spq 'sk_min(1,2)' '1'
zq_and_super integer.spq 'sk_min(2,1)' '1'
zq_and_super integer.spq 'sk_min(-3,8)' '-3'

zq_and_super integer.spq 'sk_max(1,2)' '2'
zq_and_super integer.spq 'sk_max(2,1)' '2'
zq_and_super integer.spq 'sk_max(-3,8)' '8'

zq_and_super integer.spq 'sk_max(12,sk_min(24,48))' '24'
