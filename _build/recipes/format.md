---
title: Format
layout: default
nav_order: 5
parent: Recipes
---

# Format Recipes

Source: `format.spq`

---

## sk_format_bytes

Returns the size in bytes in human readable format.

**Type:** function

| Argument | Description |
|----------|-------------|
| `value` | Must be castable to uint64 |

```supersql
sk_format_bytes(1048576)
-- => '1 MB'

sk_format_bytes(0)
-- => '0 B'
```

Supports units up to EB (exabytes). The full unit list: B, KB, MB, GB, TB, PB, EB.

---

## Implementation

```supersql
const sk_bytes_units=["B", "KB", "MB", "GB", "TB", "PB", "EB"]
const sk_bytes_divisor=1024

fn _sk_bytes_unit_index(value): (
  floor(log(value) / log(sk_bytes_divisor))::uint64
)

fn _sk_format_nonzero_bytes(value): (
  f"{(value / pow(sk_bytes_divisor, _sk_bytes_unit_index(value)))::uint64} {sk_bytes_units[_sk_bytes_unit_index(value)]}"
)

fn sk_format_bytes(value): (
  (value == 0) ? "0 B" : _sk_format_nonzero_bytes(value)
)
```
