---
title: Escape
layout: default
nav_order: 7
parent: Recipes
---

# Escape Recipes

Source: `escape.spq`

Functions for safely escaping values for CSV, TSV, and shell contexts, plus
patterns for safe text ingestion from shell pipelines.

---

## sk_csv_field

Escapes a string for use as a CSV field per RFC 4180. Wraps in double quotes
and doubles internal quotes when the value contains commas, quotes, or
newlines. Plain values pass through unchanged.

**Type:** function

| Argument | Description |
|----------|-------------|
| `s` | The string to escape |

```supersql
sk_csv_field('plain')
-- => 'plain'

sk_csv_field('hello, world')
-- => quoted and wrapped
```

---

## sk_csv_row

Builds a CSV row from an array of values. Each element is cast to string and
escaped with sk_csv_field, then joined with commas.

**Type:** function

| Argument | Description |
|----------|-------------|
| `arr` | Array of values to format as a CSV row |

---

## sk_shell_quote

Wraps a string in POSIX shell single quotes. Internal single quotes are escaped
so the result is safe for shell interpolation. Protects against injection of `$`,
backticks, and other shell metacharacters.

**Type:** function

| Argument | Description |
|----------|-------------|
| `s` | The string to quote |

```supersql
sk_shell_quote('hello world')
-- => single-quoted string

sk_shell_quote('has $var')
-- => single-quoted, $ not expanded
```

---

## sk_tsv_field

Escapes a value for use in a TSV field. Casts to string, then replaces literal
tab and newline characters with their backslash-escaped forms.

**Type:** function

| Argument | Description |
|----------|-------------|
| `s` | The value to escape |

---

## Shell Patterns for Safe Text Ingestion

The key insight: never interpolate untrusted text into a SuperQL string literal.
Pipe raw text through `super` with `-i line` and let the serializer handle
escaping. These patterns work from any language that can spawn a subprocess.

### safe_text_to_record

Pipe raw text into super to build a record without string interpolation.

```bash
echo "$text" | super -s -i line -c "values {body: this}" -
```

### safe_text_to_string

Pipe raw text through super to get a properly escaped SUP string literal.

```bash
echo "$text" | super -s -i line -c "values this" -
```

### safe_multiline_to_record

Collapse multiline text into a single record field.

```bash
echo "$text" | super -s -i line \
  -c 'aggregate s:=collect(this) | values {body: join(s, "\n")}' -
```

### safe_append_to_sup_file

Append a timestamped record with raw text to a `.sup` file.

```bash
echo "$text" | super -s -i line \
  -c "values {ts: now(), body: this}" - >> data.sup
```

---

## Implementation

```supersql
fn sk_csv_field(s): (
  grep("[,\"\n]", s)
    ? f"\"{replace(s, "\"", "\"\"")}\""
    : s
)

fn sk_csv_row(arr): (
  join([unnest arr | values sk_csv_field(cast(this, <string>))], ",")
)

fn sk_shell_quote(s): (
  f"'{replace(s, "'", "'\\''")}'"
)

fn sk_tsv_field(s): (
  replace(replace(cast(s, <string>), "\t", "\\t"), "\n", "\\n")
)
```
