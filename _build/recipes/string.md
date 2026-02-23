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
