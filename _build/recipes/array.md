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
