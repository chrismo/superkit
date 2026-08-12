---
title: Text
layout: default
nav_order: 8
parent: Recipes
---

# Text Recipes

Source: `text.spq`

Field-extraction functions that stand in for `awk` and `cut` when you are
processing plain text with SuperDB. See the
[Plain Text Without the Bashisms]({% link docs/tutorials/plain_text.md %})
tutorial for the pipelines these are meant to slot into.

Two things these smooth over:

- **`awk` and `cut` number fields from 1; SuperDB arrays index from 0.** These
  take the 1-based number you already know from the shell, so translating a
  pipeline is mechanical instead of an off-by-one hunt.
- **An out-of-range field returns `""`,** the way `awk` treats `$9` on a
  3-field line, rather than raising `error("missing")` and poisoning the record.

---

## sk_fields

Splits a line into fields on runs of whitespace, the way `awk` does. Leading and
trailing whitespace is ignored, and repeated spaces or tabs collapse into a
single separator. Returns an empty array for a blank line.

Use this instead of `split(s, " ")`, which treats every space as its own
separator and hands back empty strings between them.

**Type:** function

| Argument | Description |
|----------|-------------|
| `s` | The line to split |

```supersql
join(sk_fields('  alpha   beta\tgamma  '), '|')
-- => 'alpha|beta|gamma'

len(sk_fields('   '))
-- => 0
```

**Implementation:**

```supersql
fn sk_fields(s): (
  trim(s) == "" ? [] : split(regexp_replace(trim(s), "\\s+", " "), " ")
)
```

---

## sk_nf

Counts whitespace-separated fields in a line, the equivalent of `awk`'s `NF`.
Blank lines count as zero.

**Type:** function

| Argument | Description |
|----------|-------------|
| `s` | The line to count fields in |

```supersql
sk_nf('a b  c')
-- => 3

sk_nf('')
-- => 0
```

**Implementation:**

```supersql
fn sk_nf(s): (len(sk_fields(s)))
```

---

## sk_field

Extracts a single whitespace-separated field by 1-based position, the equivalent
of `awk`'s `$n`. Returns `""` when `n` is out of range or less than 1, so a short
line does not raise `error("missing")`.

**Type:** function

| Argument | Description |
|----------|-------------|
| `s` | The line to extract from |
| `n` | 1-based field number, as in `awk` |

```supersql
sk_field('alpha beta gamma', 2)
-- => 'beta'

sk_field('alpha beta gamma', 9)
-- => ''
```

**Implementation:**

```supersql
fn sk_field(s, n): (
  n >= 1 and n <= len(sk_fields(s)) ? sk_fields(s)[n - 1] : ""
)
```

---

## sk_cut

Extracts a single delimited field by 1-based position, the equivalent of
`cut -d DELIM -f N`. Unlike `sk_field`, the delimiter is literal and repeats are
not collapsed, so consecutive delimiters yield empty fields — matching `cut`.
Returns `""` when `n` is out of range.

**Type:** function

| Argument | Description |
|----------|-------------|
| `s` | The line to extract from |
| `delim` | Literal field delimiter, not a regular expression |
| `n` | 1-based field number, as in `cut -f` |

```supersql
sk_cut('root:x:0:0', ':', 1)
-- => 'root'

sk_cut('root:x:0:0', ':', 3)
-- => '0'
```

**Implementation:**

```supersql
fn sk_cut(s, delim, n): (
  n >= 1 and n <= len(split(s, delim)) ? split(s, delim)[n - 1] : ""
)
```

---

## Picking between them

`sk_field` and `sk_cut` look interchangeable but split on different rules, the
same way `awk` and `cut` do:

| Input | `sk_field(s, 2)` | `sk_cut(s, ' ', 2)` |
|---|---|---|
| `'a b c'` | `'b'` | `'b'` |
| `'a  b  c'` | `'b'` | `''` |
| `'  a b'` | `'b'` | `''` |

Whitespace-aligned output — `ps`, `ls -l`, `df` — wants `sk_field`. Genuinely
delimited data — `/etc/passwd`, a `:` or `,` separated file — wants `sk_cut`,
because there an empty field is real data rather than padding.
