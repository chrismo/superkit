#!/usr/bin/env bats

setup() {
  load test_helper
}

# --- sk_keys ---

@test "keys: simple record" {
  sk_assert records.spq '{a:1,b:2,c:3,d:4} | sk_keys' '["a","b","c","d"]'
}

@test "keys: array of records unnested" {
  sk_assert records.spq '[{a:1},{b:2},{c:3},{d:4}] | unnest this | sk_keys' '["a","b","c","d"]'
}

@test "keys: preserves order" {
  sk_assert records.spq '{d:1,b:2,a:3,c:4} | sk_keys' '["d","b","a","c"]'
}

@test "keys: nested record top-level only" {
  sk_assert records.spq '{a:{b:1,c:2}} | sk_keys' '["a"]'
}

# --- sk_merge_records ---

@test "merge: simple records" {
  sk_assert records.spq '[{a:1},{b:2},{c:3},{d:4}] | sk_merge_records' '{a:1,b:2,c:3,d:4}'
}

@test "merge: duplicate keys" {
  sk_assert records.spq '[{a:1},{a:1}] | sk_merge_records' '{a:1}'
}

@test "merge: mixed types" {
  sk_assert records.spq '[{a:1},{b:"sandwich",c:333}] | sk_merge_records' '{a:1,b:"sandwich",c:333}'
}

@test "merge: nested record" {
  sk_assert records.spq '[{a:1},{b:{c:333}}] | sk_merge_records' '{a:1,b:{c:333}}'
}

@test "merge: nested with arrays" {
  sk_assert records.spq '[{a:1},{b:{c:3, d:4}},{e:[5, {f:6}]}] | sk_merge_records' '{a:1,b:{c:3,d:4},e:[5,{f:6}]}'
}

@test "merge: array of records in value" {
  sk_assert records.spq '[{a:1},{b:{c:3, d:4}},{e:[{f:6},{g:7}]}] | sk_merge_records' '{a:1,b:{c:3,d:4},e:[{f:6,g:7}]}'
}

@test "merge: deeply nested" {
  sk_assert records.spq '[{a:1},{b:{c:{d:2}}}] | sk_merge_records' '{a:1,b:{c:{d:2}}}'
}

@test "merge: map to record" {
  sk_assert records.spq '|{"a":1,"b":2}| | sk_merge_records' '{a:1,b:2}'
}

# --- sk_add_ids ---

@test "add_ids: single record" {
  sk_assert records.spq,array.spq '{foo:"bar"} | sk_add_ids' '[{id:1,foo:"bar"}]'
}

@test "add_ids: array unnested" {
  sk_assert records.spq,array.spq '[{foo:"bar"}] | unnest this | sk_add_ids' '[{id:1,foo:"bar"}]'
}

@test "add_ids: multiple records" {
  sk_assert records.spq,array.spq '[{a:"a"},{b:"b"}] | unnest this | sk_add_ids' '[{id:1,a:"a"},{id:2,b:"b"}]'
}

@test "add_ids: existing id preserved" {
  sk_assert records.spq,array.spq '[{id:1}] | sk_add_ids' '[{id:1}]'
}

@test "add_ids: existing id reordered to front" {
  sk_assert records.spq,array.spq '[{foo:"bar",id:2}] | sk_add_ids' '[{id:2,foo:"bar"}]'
}

@test "add_ids: scalar input" {
  sk_assert records.spq,array.spq 'values 1 | sk_add_ids' '[{id:1}]'
}
