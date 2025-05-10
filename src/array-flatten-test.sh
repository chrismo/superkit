#!/usr/bin/env bash

set -euo pipefail

zq_and_super array.spq '[1,2]   | sk_array_flatten()' '[1,2]'
zq_and_super array.spq '[1,[2]] | sk_array_flatten()' '[1,2]'
zq_and_super array.spq '[[1]]   | sk_array_flatten()' '[1]'
zq_and_super array.spq '[[[1]]] | sk_array_flatten()' '[1]'

zq_and_super array.spq '[
  [
    [
      {a:1}
    ],
    4
  ]] | sk_array_flatten()' '[{a:1},4]'
