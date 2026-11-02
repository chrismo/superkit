#!/usr/bin/env bash

set -euo pipefail

export ASDF_SUPERDB_VERSION=0.4.0

super --version

# fresh tour/keys: fresh --cmd help tour

# super -s -c "" zz.json
# super -s -c "" zz.sup
# echo {foo:1} | super -s -c "" -

# seq 1 89239 | super -s -c 'where this >= 89230' -

$ seq 1 100000 | super -s -c 'values this' - | diff <(seq 1 100000) -
89233c89233,89234
< 89233
---
> 89
> 233
