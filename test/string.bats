#!/usr/bin/env bats

setup() {
  load test_helper
}

# --- sk_slice ---

@test "slice: exact range" {
  sk_assert string.spq,integer.spq 'values sk_slice("hey", 0, 3)' '"hey"'
}

@test "slice: end beyond length" {
  sk_assert string.spq,integer.spq 'values sk_slice("hey", 0, 4)' '"hey"'
}

@test "slice: negative end -1" {
  sk_assert string.spq,integer.spq 'values sk_slice("hey", 0, -1)' '"he"'
}

@test "slice: negative end -2" {
  sk_assert string.spq,integer.spq 'values sk_slice("hey", 0, -2)' '"h"'
}

@test "slice: negative end -3 empty" {
  sk_assert string.spq,integer.spq 'values sk_slice("hey", 0, -3)' '""'
}

@test "slice: negative end beyond length" {
  sk_assert string.spq,integer.spq 'values sk_slice("hey", 0, -4)' '""'
}

@test "slice: start equals end" {
  sk_assert string.spq,integer.spq 'values sk_slice("hey", 3, 3)' '""'
}

@test "slice: start beyond length" {
  sk_assert string.spq,integer.spq 'values sk_slice("hey", 400, 3)' '""'
}

@test "slice: both negative" {
  sk_assert string.spq,integer.spq 'values sk_slice("hey", -2, -1)' '"e"'
}

@test "slice: negative start beyond length" {
  sk_assert string.spq,integer.spq 'values sk_slice("hey", -4, -1)' '"he"'
}

@test "slice: negative start positive end" {
  sk_assert string.spq,integer.spq 'values sk_slice("hey", -4, 4)' '"hey"'
}

# --- sk_capitalize ---

@test "capitalize: simple" {
  sk_assert string.spq,integer.spq 'sk_capitalize("hey")' '"Hey"'
}

@test "capitalize: multi-word" {
  sk_assert string.spq,integer.spq 'sk_capitalize("hey you")' '"Hey you"'
}

@test "capitalize: with this" {
  sk_assert string.spq,integer.spq 'values "hey you" | sk_capitalize(this)' '"Hey you"'
}

# --- sk_titleize ---

@test "titleize: two words" {
  sk_assert string.spq,integer.spq 'sk_titleize("hey you")' '"Hey You"'
}

@test "titleize: double space preserved" {
  sk_assert string.spq,integer.spq 'sk_titleize("hey  you")' '"Hey  You"'
}

@test "titleize: mixed case normalized" {
  sk_assert string.spq,integer.spq 'sk_titleize("HEY yOu")' '"Hey You"'
}

# --- sk_pad_right ---

@test "pad_right: already at target" {
  sk_assert string.spq,integer.spq 'values sk_pad_right("hey", " ", 3)' '"hey"'
}

@test "pad_right: pad one" {
  sk_assert string.spq,integer.spq 'values sk_pad_right("hey", " ", 4)' '"hey "'
}

@test "pad_right: below length no-op" {
  sk_assert string.spq,integer.spq 'values sk_pad_right("hey", " ", 2)' '"hey"'
}

@test "pad_right: negative target no-op" {
  sk_assert string.spq,integer.spq 'values sk_pad_right("hey", " ", -1)' '"hey"'
}

@test "pad_right: long pad" {
  sk_assert string.spq,integer.spq 'values sk_pad_right("foo", "-", 100)' \
    '"foo-------------------------------------------------------------------------------------------------"'
}
