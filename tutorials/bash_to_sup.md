---
title: "Getting Bash Text into SuperDB"
description: "Getting raw text safely from Bash into SuperDB without manual escaping."
layout: default
nav_order: 1
parent: Tutorials
superdb_version: "0.1.0"
last_updated: "2026-02-17"
---

# Getting Bash Text into SuperDB

The companion to [sup_to_bash](sup_to_bash.md), this covers the reverse: safely
getting raw text from Bash into SuperDB.

## The Problem

When building `.sup` records from Bash, you need to escape text before embedding
it in SUP strings. A common approach is manual escaping with sed:

```bash
# Manual escaping — fragile and error-prone
escape_for_sup() {
  echo "$1" | sed 's/\\/\\\\/g' | sed 's/"/\\"/g' | sed "s/'/\'/g"
}

text='She said "hello" and it'\''s a back\slash'
record="{body:\"$(escape_for_sup "$text")\"}"
echo "$record" >> data.sup
```

This works but is brittle — each special character needs its own sed pass, and
it's easy to miss edge cases or get the escaping order wrong.

## Let Super Handle It

Instead of escaping text yourself, pipe it through `super` and let the
serializer do the work. The `-i line` flag reads each line of stdin as a string
value.

### Single-Line Text

```bash
text='She said "hello" and it'\''s a back\slash'
echo "$text" | super -s -i line -c "values this" -
# => "She said \"hello\" and it's a back\\slash"
```

Super's SUP output automatically escapes backslashes and double quotes. No sed
needed.

### Multiline Text to a Single String

With `-i line`, each input line becomes a separate string value. To collapse
multiline text into a single string with embedded `\n`:

```bash
printf 'line one\nline two\nline three' |
  super -s -i line -c 'aggregate s:=collect(this) | values join(s, "\n")' -
# => "line one\nline two\nline three"
```

The pattern: `collect()` gathers all lines into an array, then `join()` merges
them with literal newline characters.

### Building Records with Raw Text

Combine `-i line` with record construction to safely embed text into `.sup`
records:

```bash
# Single-line field
msg='User said "goodbye" & left'
body=$(echo "$msg" | super -f line -i line -c "values this" -)
echo "{type:'message',body:'$body'}" | super -s -c "values this" -

# Or build the whole record in one shot
echo "$msg" | super -s -i line -c "values {type:'message', body: this}" -
```

The second form is cleaner — super constructs the full record, so the text never
passes through Bash string interpolation at all.

### Multiline Record Fields

```bash
notes="first line
second line
third line"

echo "$notes" |
  super -s -i line -c '
    aggregate s:=collect(this)
    | values {type: "note", body: join(s, "\n")}
  ' -
# => {type:"note",body:"first line\nsecond line\nthird line"}
```

## Appending to .sup Files

A common pattern in scripts that maintain `.sup` files:

```bash
append_record() {
  local file="$1"
  local msg="$2"
  echo "$msg" |
    super -s -i line -c "values {ts: now(), body: this}" - >> "$file"
}

append_record "log.sup" 'User clicked "submit" at /path?q=1&r=2'
```

## Why This Is Better

| Approach | Handles `"` | Handles `\` | Handles `'` | Handles newlines | Handles unicode |
|---|---|---|---|---|---|
| Manual sed chains | One sed per char | Easy to mis-order | Another sed | Yet another sed | Hope for the best |
| `super -i line` | Yes | Yes | Yes | With collect/join | Yes |

One pipeline replaces an entire family of escape functions. Super knows its own
serialization format — let it do the work.
