---
title: Array
layout: default
nav_order: 2
parent: Recipes
---

# Array Recipes

Source: `array.spq`

---

## sk_in_array

Puts value in an array if value isn't an array itself.

**Type:** function

| Argument | Description |
|----------|-------------|
| `value` | any |

```supersql
sk_in_array(1)
-- => [1]

sk_in_array([1])
-- => [1]
```

**Implementation:**

```supersql
fn sk_in_array(value): (
  kind(value) == "array" ? value : [value]
)
```

---

## sk_array_flatten

Flattens an array of arrays into a single array.

**Type:** operator

```supersql
[1,2,[3,4],5] | sk_array_flatten
-- => [1,2,3,4,5]

[[1,2],[3,4]] | sk_array_flatten
-- => [1,2,3,4]
```

**Implementation:**

```supersql
op sk_array_flatten: (
  this::string
  | this[1:-1]
  | replace(this,'[','')
  | replace(this, ']','')
  | parse_sup(f'[{this}]')
)
```

---

## sk_array_append

Appends a value to the end of an array.

**Type:** function

| Argument | Description |
|----------|-------------|
| `arr` | The array to append to. |
| `val` | The value to append. |

```supersql
sk_array_append([1,2,3], 4)
-- => [1,2,3,4]

sk_array_append([], "a")
-- => ["a"]
```

**Implementation:**

```supersql
fn sk_array_append(arr, val): ([...arr, val])
```

---

## sk_array_remove

Removes all occurrences of a value from an array.

**Type:** operator

| Argument | Description |
|----------|-------------|
| `val` | The value to remove. |

```supersql
[1,2,3,2,1] | sk_array_remove 2
-- => [1,3,1]

["a","b","c"] | sk_array_remove "b"
-- => ["a","c"]
```

**Implementation:**

```supersql
op sk_array_remove val: (
  [unnest this | where this != val]
)
```

---

## sk_deep_flatten

Recursively flattens nested arrays into a single flat array.

Unlike `sk_array_flatten` which only flattens one level, `sk_deep_flatten` recursively processes all nested arrays regardless of depth.

**Type:** operator

```supersql
[[1,[2,3]],[4,[5,[6]]]] | sk_deep_flatten
-- => [1,2,3,4,5,6]

[1,[2],[[3]]] | sk_deep_flatten
-- => [1,2,3]
```

**Implementation:**

```supersql
op sk_deep_flatten: (
  fn _df(v): (
    case kind(v)
    when "array" then (
      [unnest [unnest v | _df(this)] | unnest this]
    )
    else [v]
    end
  )
  _df(this)
)
```
