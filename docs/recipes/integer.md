---
title: Integer
layout: default
nav_order: 3
parent: Recipes
---

# Integer Recipes

Source: `integer.spq`

---

## sk_clamp

Clamps a value between min and max.

**Type:** function

| Argument | Description |
|----------|-------------|
| `i` | The value to clamp. |
| `min` | The minimum value. |
| `max` | The maximum value. |

```supersql
sk_clamp(1, 2, 3)
-- => 2

sk_clamp(4, 2, 3)
-- => 3

sk_clamp(2, 2, 3)
-- => 2
```

**Implementation:**

```supersql
fn sk_clamp(i, min, max): (
  i < min ? min : i > max ? max : i
)
```

---

## sk_min

Returns the minimum of two values.

**Type:** function

| Argument | Description |
|----------|-------------|
| `a` | The first value. |
| `b` | The second value. |

```supersql
sk_min(1, 2)
-- => 1

sk_min(3, 2)
-- => 2
```

**Implementation:**

```supersql
fn sk_min(a, b): (
  a < b ? a : b
)
```

---

## sk_max

Returns the maximum of two values.

**Type:** function

| Argument | Description |
|----------|-------------|
| `a` | The first value. |
| `b` | The second value. |

```supersql
sk_max(1, 2)
-- => 2

sk_max(3, 2)
-- => 3
```

**Implementation:**

```supersql
fn sk_max(a, b): (
  a > b ? a : b
)
```
