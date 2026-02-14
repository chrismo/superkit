#!/usr/bin/env bats

setup() {
  load test_helper
}

# --- sk_array_flatten ---

@test "flatten: already flat" {
  sk_assert array.spq '[1,2] | sk_array_flatten' '[1,2]'
}

@test "flatten: one nested" {
  sk_assert array.spq '[1,[2]] | sk_array_flatten' '[1,2]'
}

@test "flatten: double nested" {
  sk_assert array.spq '[[1]] | sk_array_flatten' '[1]'
}

@test "flatten: triple nested" {
  sk_assert array.spq '[[[1]]] | sk_array_flatten' '[1]'
}

@test "flatten: mixed nested with records" {
  sk_assert array.spq '[[[{a:1}],4]] | sk_array_flatten' '[{a:1},4]'
}

# --- sk_in_array ---

@test "in_array: record becomes array" {
  sk_assert array.spq '{a:1} | sk_in_array(this)' '[{a:1}]'
}

@test "in_array: array stays array" {
  sk_assert array.spq '[{a:1}] | sk_in_array(this)' '[{a:1}]'
}

@test "in_array: nested array stays" {
  sk_assert array.spq '[[1]] | sk_in_array(this)' '[[1]]'
}

@test "in_array: scalar becomes array" {
  sk_assert array.spq 'values 1 | sk_in_array(this)' '[1]'
}

@test "in_array: string becomes array" {
  sk_assert array.spq 'values "a" | sk_in_array(this)' '["a"]'
}

@test "in_array: map becomes array" {
  sk_assert array.spq '|{"a":1}| | sk_in_array(this)' '[|{"a":1}|]'
}

@test "in_array: empty array stays empty" {
  sk_assert array.spq '[] | sk_in_array(this)' '[]'
}

@test "in_array: no match where returns nothing" {
  # https://github.com/brimdata/super/issues/4708
  sk_assert array.spq '[] | unnest this | where a==1 | sk_in_array(this)' ''
}
