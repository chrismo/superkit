---
title: "Upgrade Guide"
description: "Migration guide from zq to SuperDB. Covers all breaking changes and syntax updates."
layout: default
nav_order: 3
superdb_version: "0.1.0"
last_updated: "2026-01-31"
---

# Upgrading zq to super

SuperDB Version 0.1.0

This document is designed for AI assistants performing automated upgrades of zq
scripts to SuperDB. It covers all breaking changes between zq and the current
SuperDB release.

## Quick Reference

This table covers ALL breaking changes. Complex items reference detailed sections below.

| Category         | zq                          | super                                    |
|------------------|-----------------------------|------------------------------------------|
| Keyword          | `yield`                     | `values`                                 |
| Function         | `parse_zson`                | `parse_sup`                              |
| Function         | `func`                      | `fn`                                     |
| Operator         | `over`                      | `unnest`                                 |
| Operator def     | `op name(a, b):`            | `op name a, b:`                          |
| Operator call    | `name(x, y)`                | `name x, y`                              |
| Switch           | `-z` / `-Z`                 | `-s` / `-S`                              |
| Switch           | `-f text`                   | `-f line`                                |
| Switch           | (implicit)                  | `-c` required before query               |
| Comments         | `//`                        | `--` or `/* */`                          |
| Regexp           | `/pattern/`                 | `'pattern'` (string)                     |
| Cast             | `type(value)`               | `value::type`                            |
| Agg filter       | `count() where x`           | `count() filter (x)`                     |
| Indexing         | 0-based                     | 0-based & 1-based (see Indexing section) |
| Scoped unnest    | `over x => (...)`           | `unnest x into (...)`                    |
| Unnest with      | `over a with b`             | `unnest {b,a}` (see section)             |
| grep             | `grep(/pat/)`               | `grep('pat', this)`                      |
| is()             | `is(<type>)`                | `is(this, <type>)`                       |
| nest_dotted      | `nest_dotted()`             | `nest_dotted(this)`                      |
| Lateral subquery | `{ a: (subquery) }`         | `{ a: [subquery] }` (see section)        |
| Nested FROM      | `from (from x)`             | `select * from (select * from x)`        |
| Streaming agg    | `put x:=sum(y)`             | Removed (see section)                    |
| Functions        | `crop/fill/fit/order/shape` | Removed — use cast                       |
| Globs            | `grep(foo*)`                | Removed — use regex                      |
| String concat    | `"a" + "b"`                 | `f'{a}{b}'`, `a \|\| b`, or `concat`     |
| count type       | returns `uint64`            | returns `int64`                          |
| Dynamic from     | `from pool`                 | `from f'{pool}'` (see section)           |

## CLI Changes

### The `-c` switch is now required

`super` requires a `-c` switch before any query string. `zq` accepted the query
string as a positional argument.

**OLD:**
```bash
echo '{"a":1}' | zq 'yield a' -
```

**NEW:**
```bash
echo '{"a":1}' | super -c 'values a' -
```

### The `-c` switch must immediately precede the query string

The query must come directly after `-c`. Other flags go before `-c`.

**CORRECT:**
```bash
echo '{"a":1}' | super -s -c 'values a' -
```

**INCORRECT:**
```bash
-- This is ILLEGAL - flags cannot go between -c and the query
echo '{"a":1}' | super -c -s 'values a' -
```

### When there is no query, do NOT use `-c`

If you're just reformatting data without a query, omit `-c` entirely.

**OLD:**
```bash
zq -j input.json
```

**NEW:**
```bash
super -j input.json
```

**INCORRECT:**
```bash
-- This is ILLEGAL - -c requires a query string to follow it
super -c -j input.json
```

### Output format switches

- `-f text` → `-f line`
- `-z` → `-s` (line-oriented Super JSON)
- `-Z` → `-S` (formatted Super JSON)

### Comments

zq used `//` for single-line comments. SuperDB uses PostgreSQL-compatible syntax:
- `--` for single-line comments
- `/* ... */` for multi-line comments

## Simple Renames

### yield → values

```bash
-- OLD
zq 'yield {a:1}'

-- NEW
super -c 'values {a:1}'
```

### parse_zson → parse_sup

```bash
-- OLD
zq 'parse_zson(s)'

-- NEW
super -c 'parse_sup(s)'
```

### func → fn

As of [commit aab15e0d](https://github.com/brimdata/super/commit/aab15e0d):

```bash
-- OLD
func double(x): ( x * 2 )

-- NEW
fn double(x): ( x * 2 )
```

### over → unnest (basic usage)

Simple uses are a direct replacement:

```bash
-- OLD
zq 'yield [1,2,3] | over this'

-- NEW
super -c 'values [1,2,3] | unnest this'
```

## Behavioral Changes

### Indexing is 0-based (with pragma for 1-based)

As of [PR 6348](https://github.com/brimdata/super/pull/6348) on Nov 10, 2025,
0-based indexing is the default. Use `pragma index_base = 1` for SQL-style
1-based indexing when needed.

```bash
-- 0-based indexing (default)
super -s -c "values ['a','b','c'][0]"
"a"
```

```bash
-- 1-based indexing via pragma
super -s -c "
pragma index_base = 1
values ['a','b','c'][1]
"
"a"
```

The pragma affects array/string indexing, slicing, and functions like `SUBSTRING()`.

### unnest with `into` (formerly `=>`)

`over this => (...)` becomes `unnest this into (...)`:

```bash
-- OLD
zq 'over arr => ( yield this * 2 )'

-- NEW
super -c 'unnest arr into ( values this * 2 )'
```

### unnest with multiple values (formerly `with`)

`over a with b => (...)` becomes `unnest {b,a} into (...)`.

**Warning:** This has behavioral changes. Inside the parentheses, `this` used to
be just `a` in zq, but now `this` is the record `{b,a}` in super.

### grep requires explicit `this` argument

As of [PR 6115](https://github.com/brimdata/super/pull/6115) on Aug 15, 2025:
- Inline regexp (`/.../`) syntax removed — use strings
- Globs no longer supported in grep
- `this` must be passed explicitly

```bash
-- OLD (no longer works)
zq -z "grep(/a*b/,s)"
zq -z "yield ['a','b'] | grep(/b/)"

-- NEW
super -s -c "grep('a.*b', s)"
super -s -c "values ['a','b'] | grep('b', this)"
```

### is and nest_dotted require explicit `this`

As of [commit 5075037c](https://github.com/brimdata/super/commit/5075037c) on Aug 27, 2025:

```bash
-- OLD (no longer works)
zq -z "yield 2 | is(<int64>)"

-- NEW
super -s -c "values 2 | is(this, <int64>)"
```

`nest_dotted` follows the same pattern.

### Cast syntax changes

As of [commit ec1c5eee](https://github.com/brimdata/super/commit/ec1c5eee) on Aug 28, 2025:

Function-style casting (`type(value)`) is no longer supported. Use `::` casting:

```bash
-- OLD (no longer works)
zq -z "{a:time('2025-08-28T12:00:00Z')}"

-- NEW (preferred)
super -s -c "{a:'2025-08-28T12:00:00Z'::time}"
{a:2025-08-28T12:00:00Z}
```

Alternative syntaxes (legal but not preferred):
- `cast(value, <type>)`
- `CAST(value AS type)`

As of 0.51029, `::` cast and `CAST AS` only accept types, not expressions.

### Lateral subqueries require array wrapping

As of [PR 6100](https://github.com/brimdata/super/pull/6100) and
[PR 6243](https://github.com/brimdata/super/pull/6243):

Lateral subqueries that produce multiple values must be wrapped in `[...]`:

```bash
-- OLD (no longer works - produces error)
super -s -c "[3,2,1] | { a: ( unnest this | values this ) }"
{a:error("query expression produced multiple values (consider [subquery])")}

-- NEW
super -s -c "[3,2,1] | { a: [unnest this | values this] }"
{a:[3,2,1]}
```

### User-defined operator syntax

As of [PR 6181](https://github.com/brimdata/super/pull/6181) on Sep 2, 2025:

**Declaration:** Remove parentheses around parameters.

```bash
-- OLD
op myop(a, b): ( ... )

-- NEW
op myop a, b: ( ... )
```

**Invocation:** Use space-separated arguments (or `call` keyword).

```bash
-- OLD
myop(x, y)

-- NEW
myop x, y
-- or: call myop x, y
```

### FROM vs from separation

As of [PR 6405](https://github.com/brimdata/super/pull/6405) on Dec 1, 2025:

Pipe-operator `from` and SQL `FROM` clause are now distinct. Relational FROM
requires a SELECT clause:

```bash
-- OLD (no longer works)
super -c 'from ( from a )'

-- NEW
super -c 'select * from ( select * from a )'
```

### String concatenation with `+` removed

As of [PR 6486](https://github.com/brimdata/super/pull/6486) on Jan 5, 2026:

The `+` operator no longer concatenates strings. Use f-string interpolation
(preferred), `||`, or `concat()`:

```bash
-- OLD (no longer works)
super -s -c "values 'hello' + ' world'"

-- Preferred (f-string interpolation, also worked in zq)
super -s -c "values f'{'hello'} {'world'}'"
"hello world"

-- Also works
super -s -c "values 'hello' || ' world'"
"hello world"

-- Also works
super -s -c "values concat('hello', ' world')"
"hello world"
```

### Aggregate filter clause

As of [PR 6465](https://github.com/brimdata/super/pull/6465) on Dec 23, 2025:

The `where` clause on aggregates changed to SQL-standard `filter`:

```bash
-- OLD
count() where grep('bar', this)

-- NEW
count() filter (grep('bar', this))
```

### Dynamic from requires f-string syntax

As of [PR 6450](https://github.com/brimdata/super/pull/6450) on Dec 16, 2025:

Bare dynamic `from` no longer works. Use f-string interpolation:

```bash
-- OLD (no longer works)
from pool_name

-- NEW
from f'{pool_name}'
```

Note: f-strings are general-purpose string interpolation and work anywhere a
string is accepted, not just in `from` clauses.

## Removed Features

### Streaming aggregation functions

As of [PR 6355](https://github.com/brimdata/super/pull/6355), per-record
cumulative aggregations are removed.

**Row numbering** — use the `count` operator:

```bash
-- OLD: put row_num:=count(this)
-- NEW:
super -s -c 'values {a:1},{b:2},{c:3} | count | {row:count,...that}'
{row:1,a:1}
{row:2,b:2}
{row:3,c:3}
```

**Other aggregations** (`sum`, `avg`, `min`, `max`, `collect`) — use `aggregate`,
but note it collapses all records:

```bash
super -s -c 'values {v:10},{v:20},{v:30} | aggregate total:=sum(v)'
{total:60}
```

**No replacement exists** for progressive patterns like streaming `collect`:

```bash
-- OLD (no longer works): yield 1,2,3 | yield collect(this)
-- produced: [1], [1,2], [1,2,3]
```

Grouped aggregation (`collect(x) by key`) still works.

### Removed functions

The functions `crop()`, `fill()`, `fit()`, `order()`, and `shape()` have been
removed. Use cast instead — see [Cast syntax changes](#cast-syntax-changes).

### Inline regexp syntax

`/pattern/` is no longer supported. Use string patterns: `'pattern'`

### Globs in grep

Globs are no longer supported in the `grep` function. Use regex patterns.

## Type Changes

### Count functions return int64

As of Dec 24-29, 2025 ([PR 6466](https://github.com/brimdata/super/pull/6466),
[PR 6467](https://github.com/brimdata/super/pull/6467),
[PR 6472](https://github.com/brimdata/super/pull/6472)):

These now return `int64` instead of `uint64`:
- `count()` function
- `dcount()` function
- `uniq` operator count field
- `count` operator output field

```bash
-- OLD: returned uint64
super -s -c "values 1,2,3 | aggregate cnt:=count() | typeof(cnt)"
<uint64>

-- NEW: returns int64
super -s -c "values 1,2,3 | aggregate cnt:=count() | typeof(cnt)"
<int64>
```

## Formatting Conventions for AI Upgraders

When performing upgrades, follow these formatting conventions for consistency:

### Use double quotes for query strings

Single-quoted strings are valid SuperDB syntax, so use double quotes for the
shell query string to avoid confusion:

```bash
-- GOOD
super -s -c "values 'hello'"

-- AVOID (works but confusing)
super -s -c 'values "hello"'
```

### Multi-line query formatting

For multi-line queries, use this format:

```bash
super -j -c "
  unnest this
  | cut Id,Name
" -
```

- Opening double-quote ends the first line
- Query content starts on new line, indented 2 spaces from `super`
- Closing double-quote on its own line, aligned with `super`

### Switch ordering

Place `-c` last, with all other switches before it:

```bash
super -s -f json -c "values this" input.json
```
