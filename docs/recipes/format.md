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

**Implementation:**

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

---

## sk_format_epoch

Converts Unix epoch milliseconds to a time value with timezone offset applied.

**Type:** function

| Argument | Description |
|----------|-------------|
| `epoch_ms` | Milliseconds since 1970-01-01 00:00:00 UTC. |
| `tz_offset` | Timezone offset string like '-0500' or '+0530'. |

```supersql
sk_format_epoch(0, '+0000')
-- => 1970-01-01T00:00:00Z

sk_format_epoch(1704067200000, '-0500')
-- => 2023-12-31T19:00:00Z
```

**Note:** SuperDB has no timezone-aware time type. The returned time value
displays as UTC but represents the local time with the offset already applied.
For display purposes only — do not use the result in further time arithmetic
that assumes UTC.

**Implementation:**

```supersql
fn sk_format_epoch(epoch_ms, tz_offset): (
  {
    sign: tz_offset[0:1],
    hours: tz_offset[1:3]::int64,
    mins: tz_offset[3:5]::int64,
    base_time: (epoch_ms * 1000000)::time
  }
  | this.base_time + f'{this.sign == "-" ? "-" : ""}{this.hours}h{this.mins > 0 ? f"{this.mins}m" : ""}'::duration
)
```
