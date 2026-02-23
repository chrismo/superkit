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
