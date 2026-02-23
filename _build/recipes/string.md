---
title: String
layout: default
nav_order: 1
parent: Recipes
---

# String Recipes

Source: `string.spq` (includes `integer.spq`)

---

## sk_slice

Returns a slice of the string passed in, even if indexes are out of range.

**Type:** function

| Argument | Description |
|----------|-------------|
| `s` | The string to slice. |
| `start` | Starting index, zero-based, inclusive. |
| `end` | Ending index, exclusive. |

```supersql
sk_slice('howdy')
-- => 'Howdy'
```

**Implementation:**

```supersql
fn sk_slice(s, start, end): (
  s[sk_clamp(start, -len(s), len(s)):sk_clamp(end, -len(s), len(s))]
)
```

---

## sk_capitalize

Upper the first character of the string, lower the remaining string.

**Type:** function

| Argument | Description |
|----------|-------------|
| `s` | The string to capitalize. |

```supersql
sk_capitalize('hoWDy')
-- => 'Howdy'
```

**Implementation:**

```supersql
fn sk_capitalize(s): (
  f"{upper(sk_slice(s, 0, 1))}{lower(sk_slice(s,1,len(s)))}"
)
```

---

## sk_titleize

Splits string by space and capitalizes each word.

**Type:** function

| Argument | Description |
|----------|-------------|
| `s` | The string to titleize |

```supersql
sk_titleize('once uPON A TIME')
-- => 'Once Upon A Time'
```

**Implementation:**

```supersql
fn sk_titleize(s): (
  [unnest split(s, " ") | values sk_capitalize(this)] | join(this, " ")
)
```

---

## sk_pad_left

Inserts pad_char to the left of the string until it reaches target_length.

**Type:** function

| Argument | Description |
|----------|-------------|
| `s` | The string to pad |
| `pad_char` | The character to pad with |
| `target_length` | The target length of the string |

```supersql
values sk_pad_left('abc', ' ', 5)
-- => '  abc'
```

**Implementation:**

```supersql
fn sk_pad_left(s, pad_char, target_length): (
  len(s) < target_length ? sk_pad_left(f'{pad_char}{s}', pad_char, target_length) : s
)
```

---

## sk_pad_right

Inserts pad_char to the right of the string until it reaches target_length.

**Type:** function

| Argument | Description |
|----------|-------------|
| `s` | The string to pad |
| `pad_char` | The character to pad with |
| `target_length` | The target length of the string |

```supersql
values sk_pad_right('abc', ' ', 5)
-- => 'abc  '
```

**Implementation:**

```supersql
fn sk_pad_right(s, pad_char, target_length): (
  len(s) < target_length ? sk_pad_right(f'{s}{pad_char}', pad_char, target_length) : s
)
```

---

## sk_urldecode

URL decoder for SuperDB. Splits on `%`, decodes each hex-encoded segment, and joins back together.

**Type:** operator

| Argument | Description |
|----------|-------------|
| `url` | The URL-encoded string to decode |

```bash
super -I string.spq -s -c 'values sk_urldecode("%2Ftavern%20test")' -
```

**Implementation:**

```supersql
op sk_decode_seg s: (
  len(s) == 0
    ? s
    : (is_error(hex(s[1:3]))
        ? s
        : hex(s[1:3])::string + s[3:])
)

op sk_urldecode url: (
  split(url, "%")
    | unnest this
    | decode_seg this
    | collect(this)
    | join(this, "")
)
```
