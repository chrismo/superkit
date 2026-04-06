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

---

## sk_last_day_of_month

Returns the last day number (28-31) of the given month and year. Correctly handles leap years.

**Type:** function

| Argument | Description |
|----------|-------------|
| `year` | The year (e.g. 2024). |
| `month` | The month number (1-12). |

```supersql
sk_last_day_of_month(2024, 2)
-- => 29

sk_last_day_of_month(2023, 2)
-- => 28

sk_last_day_of_month(2024, 12)
-- => 31

sk_last_day_of_month(2024, 4)
-- => 30
```

Works by constructing the first day of the next month as a time value, subtracting one day, then extracting the day number from the resulting date string.

**Implementation:**

```supersql
fn sk_last_day_of_month(year, month): (
  -- Returns the last day number of the given month
  {
    nm: month == 12 ? 1 : month + 1,
    ny: month == 12 ? year + 1 : year
  }
  | ((f'{this.ny}-{this.nm > 9 ? "" : "0"}{this.nm}-01T00:00:00Z'::time - 1d)::string)[8:10]::uint8
)
```
