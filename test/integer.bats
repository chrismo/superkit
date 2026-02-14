#!/usr/bin/env bats

setup() {
  load test_helper
}

# --- sk_clamp ---

@test "clamp: below min" {
  sk_assert integer.spq 'sk_clamp(1,2,3)' '2'
}

@test "clamp: above max" {
  sk_assert integer.spq 'sk_clamp(4,2,3)' '3'
}

# --- sk_min ---

@test "min: first smaller" {
  sk_assert integer.spq 'sk_min(1,2)' '1'
}

@test "min: second smaller" {
  sk_assert integer.spq 'sk_min(2,1)' '1'
}

@test "min: negative" {
  sk_assert integer.spq 'sk_min(-3,8)' '-3'
}

# --- sk_max ---

@test "max: second larger" {
  sk_assert integer.spq 'sk_max(1,2)' '2'
}

@test "max: first larger" {
  sk_assert integer.spq 'sk_max(2,1)' '2'
}

@test "max: negative" {
  sk_assert integer.spq 'sk_max(-3,8)' '8'
}

# --- composed ---

@test "max of min composition" {
  sk_assert integer.spq 'sk_max(12,sk_min(24,48))' '24'
}
