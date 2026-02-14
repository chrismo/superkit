#!/usr/bin/env bash

set -euo pipefail

super_test array.spq '[1,2]   | sk_array_flatten' '[1,2]'
super_test array.spq '[1,[2]] | sk_array_flatten' '[1,2]'
super_test array.spq '[[1]]   | sk_array_flatten' '[1]'
super_test array.spq '[[[1]]] | sk_array_flatten' '[1]'

super_test array.spq '[
  [
    [
      {a:1}
    ],
    4
  ]] | sk_array_flatten' '[{a:1},4]'
