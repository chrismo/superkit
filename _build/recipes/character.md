---
title: Character
layout: default
nav_order: 4
parent: Recipes
---

# Character Recipes

Source: `character.spq` (includes `string.spq`)

---

## sk_seq

Generates a sequence 0..n-1 (like generate_series).

**Type:** operator

| Argument | Description |
|----------|-------------|
| `n` | Number of elements to generate |

```supersql
sk_seq(3)
-- => 0, 1, 2
```

---

## sk_hex_digits

Returns the 16 hex digit characters as an array.

**Type:** function

```supersql
sk_hex_digits()
-- => ["0","1","2","3","4","5","6","7","8","9","a","b","c","d","e","f"]
```

---

## sk_chr

Converts an integer (0-127) to its ASCII character.

**Type:** function

| Argument | Description |
|----------|-------------|
| `code` | ASCII code (0-127) |

```supersql
sk_chr(65)
-- => 'A'
```

---

## sk_alpha

Converts 1-26 to A-Z.

**Type:** function

| Argument | Description |
|----------|-------------|
| `n` | Number 1-26 |

```supersql
sk_alpha(3)
-- => 'C'
```

---

## Implementation

```supersql
-- includes string.spq

op sk_seq(n): (
  split(sk_pad_left('', '0', n), '')
  | unnest this
  | count
  | values count - 1
)

fn sk_hex_digits(): (
  split("0123456789abcdef", "")
)

fn sk_chr(code): (
  let d = sk_hex_digits() |
  hex(f'{d[code/16]}{d[code%16]}')::string
)

fn sk_alpha(n): (
  sk_chr(64 + n)
)
```
