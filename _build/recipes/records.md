---
title: Records
layout: default
nav_order: 6
parent: Recipes
---

# Record Recipes

Source: `records.spq` (includes `array.spq`)

---

## sk_keys

Returns the keys of the top-level fields in a record. This does not go deep
into nested records.

**Type:** operator

```supersql
{a:1,b:{c:333}} | sk_keys
-- => ['a','b']

{x:10,y:20,z:30} | sk_keys
-- => ['x','y','z']
```

---

## sk_merge_records

Merges an array of records into a single record by combining the fields. If
there are duplicate keys, the last one wins.

**Type:** operator

```supersql
[{a:1},{b:{c:333}}] | sk_merge_records
-- => {a:1,b:{c:333}}
```

---

## sk_add_ids

Prepends an incrementing id field to each record. Always returns an array.

**Type:** operator

```supersql
[{a:3},{b:4}] | sk_add_ids
-- => [{id:1,a:3},{id:2,b:4}]
```
