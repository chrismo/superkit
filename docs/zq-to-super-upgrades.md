---
title: "Upgrade Guide"
name: zq-to-super-upgrades
description: "Migration guide from zq to SuperDB. Covers all breaking changes and syntax updates."
layout: default
nav_order: 3
superdb_version: "0.4.0"
last_updated: "2026-10-31"
---

# Upgrading zq to super

SuperDB Version 0.4.0

This guide covers all breaking changes between zq and the current SuperDB
release.

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
| BSUP format      | BSUP v1                     | BSUP v2 (v1 no longer readable)          |
| collect (empty)  | no output on empty stream   | returns `[]` (was `null` in 0.1–0.3)     |
| concat/f-strings | errors propagate            | `null` values ignored                    |
| Binary formats   | BSUP v2 / CSUP              | unified BSUP (0.4.0 can't read old files)|
| Database         | pools                       | tables (old databases can't be opened)   |
| Database         | `db auth`/`login`, `SUPER_DB` | `db attach`/`detach`                   |
| Input format     | auto-detected               | from file extension, or `-i` (see section)|
| Missing field    | `error("missing")`          | "no such field" error / `none`           |
| Function         | `has(x)` / `missing(x)`     | `is_ok(x)` / `not is_ok(x)`              |
| Function         | `quiet(x)`                  | Removed — use `ok(x)`                    |
| Function         | `max(a,b)` / `min(a,b)`     | `greatest(a,b)` / `least(a,b)`           |
| Function         | `fields(r)`                 | `paths(r)` (or `keys(r)` for top level)  |
| flatten()        | `{key,value}`               | `{path,value}`                           |
| Type             | `time`                      | `timestamp`                              |
| Fusion           | `blend` / `unblend()`       | `fuse` / `defuse()`                      |
| Fusion           | `fuse` / `defuse()`         | `superfuse` / `superdefuse()`            |
| SUP set/map      | `\|[1,2]\|` / `\|{"a":1}\|`    | `set[1,2]` / `map{"a":1}`                |
| SUP named type   | `80::(port=uint16)`         | `type port=uint16` then `80::port`       |
| SUP none         | `_`                         | `none`                                   |
| SQL joins        | unmatched = `error("missing")` | unmatched = `null`                    |
| Switches         | `-sam`/`-vam`/`-samplesize`/`-persist`/`-fusemem`/`-bsup.*` | Removed |
| Formats          | `csup`, `jsup`, `table`     | Removed                                  |

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

## Changes in v0.4.0

v0.4.0 (2026-10-31) is a large release: the vector runtime is now the only
runtime, the binary formats are unified, and the persistent database is back
with SQL tables. Expect to regenerate saved binary files and databases, and to
update some queries. The full list is in the
[upstream CHANGELOG](https://github.com/superdb/super/blob/main/CHANGELOG.md#040---2026-10-31).
The GitHub organization moved too: it's now `github.com/superdb/super`.

### Binary files and databases must be regenerated (breaking)

The old column-oriented CSUP format is now called BSUP, and the old
row-oriented BSUP lives on as row frames inside the new BSUP. v0.4.0 can't read
BSUP or CSUP files from earlier releases, and can't open databases created by
them. BSUP output is columnar by default (`-rows` writes row frames).

Convert old files **with the old binary** before upgrading. SUP works as an
interchange format unless the data uses sets, maps, named types, or `_`, whose
SUP syntax changed (see below). Arrow IPC or Parquet survive the jump, but sets
become arrays and named types lose their names:

```bash
# Plain data: old binary to SUP, new binary back to BSUP
super-0.3.0 -s data.bsup > data.sup
super -o data.bsup data.sup

# Data with sets/maps/named types: go through Arrow instead. Arrow needs a
# single schema, so merge mixed record types with the OLD binary's `blend`
super-0.3.0 -f arrows -c "blend" data.bsup > data.arrows
super -o data.bsup data.arrows
```

Merging types this way makes fields that are absent from some records `null`
in every record, so prefer the SUP route when it works.

For a database, export each pool with the old binary
(`super-0.3.0 db -s -c "from mypool" > mypool.sup`), then `super db init` a new
database and `super db load` the data into new tables.

### Database: pools are now tables

- _Pools_ are now called _tables_ in commands, flags, help text, and queries.
  `super db create`, `drop`, `rename`, `ls`, and `-use table@branch` keep
  their names
- `super db auth` and `super db login` are replaced by `super db attach` and
  `super db detach`, and the `SUPER_DB` environment variable is gone.
  Commands use the attached database, or the one named by `-attach`
- `super db vector` commands were removed
- Tables are unsorted by default (`-orderby` is optional)
- New SQL statements: `CREATE TABLE`, `CREATE SUPER TABLE`, `INSERT INTO`, and
  `DROP TABLE`. A query can be a script of `;`-separated statements

```bash
# OLD (v0.3.0)
export SUPER_DB=./lake
super db init
super db create -orderby ts:desc logs

# NEW (v0.4.0)
super db init ./mydb
super db attach ./mydb
super db -s -c "CREATE TABLE logs (ts timestamp, msg string) ORDER BY ts DESC"
```

### Vector runtime only

`-sam`, `-vam`, and the `SUPER_RUNTIME` environment variable were removed.
Output order of parallel queries can vary from run to run, so add `sort` /
`order by` where you depend on order.

### Input format comes from the file extension (breaking)

The format of a **local file** is determined by its extension (including
`.gz`), not by sniffing its contents. A file with a missing or unrecognized
extension now needs `-i` (use `-i auto` to ask for auto-detection, or
`format auto` on a `from` operator). Stdin and HTTP/HTTPS/S3 URLs without a
recognized extension are still auto-detected.

```bash
# OLD: worked
super -s data
# NEW
super -s -i json data
super -s -i auto data
```

The output format now follows the extension given to `-o` when `-f` isn't
set, and `-i` now takes precedence over a file's extension.

### Static type checking (breaking)

`-samplesize` was removed. BSUP, Parquet, Arrow, and SUP inputs are statically
type-checked by default; `-static` extends this to all inputs and `-dynamic`
turns it off. Type checking is strict about unions and possibly missing fields:

```
values y   -- over static input where y is absent from some values:
-- error: field may be missing (consider ok())
```

SQL on JSON (dynamic) input may now fail with `the all-columns (*) pattern
cannot be used for dynamic inputs` or `join on dynamic column "l" requires
table-qualified reference`. Add `-static`:

```bash
super -static -s -c 'select * from "data.json"'
```

### Missing fields, `has()`, `missing()`, and `quiet()` (breaking)

Referencing a missing field is now a `no such field` error rather than
`error("missing")`. On statically typed input it's a compile-time error.

| Removed         | Replacement                        |
|-----------------|------------------------------------|
| `has(x)`        | `is_ok(x)`                         |
| `missing(x)`    | `not is_ok(x)`                     |
| `quiet(x)`      | `ok(x)` (returns `none` on error)  |
| `error("quiet")`| no special handling any more       |

```
-- OLD
where has(a)
values coalesce(quiet(a.b), "default")
-- NEW
where is_ok(a)
values ok(a.b) ?? "default"
```

In SQL, a reference to a missing field now evaluates to `null`. This changes
outer-join results: unmatched columns are `null`, so use `where x is null`
instead of `where is_error(x)`.

### Option types, `none`, `??`, and `?.` (new)

`none` replaces `error("missing")` as the "no value" value, with option types
(`option(int64)`) to hold it. `??` replaces `none` or `null` with its
right-hand side, and `?.` chains through optional values. JSON output omits
fields whose value is `none`.

```
values {x:1, y?:2}, {x:1, y?:none::int64} | values y ?? 0
-- => 2
-- => 0
```

### SUP syntax changes (breaking)

| Old SUP                  | New SUP                                 |
|--------------------------|-----------------------------------------|
| `80::(port=uint16)`      | `type port=uint16` then `80::port`      |
| `\|[1,2]\|`                | `set[1,2]`                              |
| `\|{"a":1}\|`              | `map{"a":1}`                            |
| `_` (none)               | `none`                                  |

The `-persist` flag was removed, since named types can no longer be redefined.
Anonymous unions are flat: one can't contain another anonymous union (a named
union still can). The same set/map syntax applies in queries, e.g.
`collect_map(map{k:v})`.

### Renamed functions and types (breaking)

- **`max(a,b)` / `min(a,b)`** (non-aggregate) → **`greatest(a,b)` /
  `least(a,b)`**. The `max()` / `min()` aggregates are unchanged
- **`time` → `timestamp`.** `x::time` now errors with "type not yet
  implemented", because `time` now means the SQL time-of-day type
- **Fusion names swapped:** `blend` → `fuse`, `fuse` → `superfuse`,
  `unblend()` → `defuse()`, `defuse()` → `superdefuse()`. A query that uses
  `fuse` or `defuse()` still runs but now does what `blend` / `unblend()` did
- **`fields()` → `paths()`**, which descends into arrays, sets, and maps.
  For jq-style top-level keys, use the new `keys()`
- **`flatten()`** returns `{path,value}` instead of `{key,value}` and descends
  into arrays, sets, and maps; `unflatten()` takes the new form

```
-- OLD
values max(a, b), fields({a:1})
put ts := ts_str::time
unflatten([unnest flatten(r) | {key, value: f(value)}])
-- NEW
values greatest(a, b), keys({a:1})
put ts := ts_str::timestamp
unflatten([unnest flatten(r) | {path, value: f(value)}])
```

### Other behavior changes

- `collect()` returns `[]` (not `null`) when there's nothing to collect.
  `collect()`, `array_agg()`, and `union()` keep `null` values, and `collect()`
  and `array_agg()` preserve input order
- `join` no longer treats two `null` keys as matching
- `grep()` and search expressions no longer match field names
- `typeof()` returns the subtype of a fusion value. Fusion values are
  auto-defused in every output format except BSUP (use `-fusion` to see them)
- Type fusion: a field absent from some inputs gets a `T|missing` union
  instead of becoming optional (`optionize()` converts it). An empty array,
  set, or map has element type `none` (`typeof([])` is `<[none]>`)
- `under()` of a type value unwraps one level (`under(<[int64]>)` is `<int64>`)
- The JSON reader errors on duplicate field names (it used to keep the last)
- Out-of-range array indexing gives `error({message:"index out of range",...})`
- File paths in output and messages no longer have a `file://` prefix
- `AWS_S3_ENDPOINT` is now `AWS_ENDPOINT_URL_S3`
- Removed: the JSUP format, the `table` output format, and `-fusemem`. The
  Python client moved to [superdb-python](https://github.com/superdb/superdb-python)
- Homebrew: `brew install super` (core casks, not the brimdata tap)

### New features in v0.4.0

- Method-style calls: `s.trim().upper()`, `s.split(",")`
- Shell args after `--` become the `args` string-array constant:
  `super -c 'values args[0]' -- hello`
- `array_agg` aggregate, including `distinct`
- `keys()` and `values()` for records and maps
- `optionize()` and `sum_type()` type functions
- Native `uuid` type, recursive types, and the `any` type
- `type T = (query)` binds a type computed by a query
- Dot and index navigation into type values: `<{a:{b:string}}>.a.b`
- `from` can have a parent operator, and expression-based `from` works in
  `super db` queries
- `super compile` accepts `-i`
- Parquet reader supports maps

### Known issues in v0.4.0

These were observed while updating this guide and may be upstream bugs:

- Subtracting two timestamps returns a `timestamp` (`1970-01-01T00:00:04Z`)
  instead of a `duration` (`4s`). Cast it: `(end - start)::duration`
- A record literal with an untyped optional `none` (`{x:1, y?:none}`) panics.
  Write `y?:none::int64` instead
- Auto-detecting a large stream on stdin can split values at buffer
  boundaries (`seq 1 1000000 | super -c 'count()' -` gives 1000010). Pass
  `-i` (e.g. `-i sup` or `-i line`) for large piped input
- `full outer join` still behaves like a left join

## Changes in v0.3.0

### BSUP v2 format (breaking)

As of v0.3.0, the BSUP binary format has been advanced to v2. `super` will no
longer read BSUP v1 format as input. If you have valuable data stored in BSUP v1
files, convert them using a v0.2.0 binary before upgrading:

```bash
# Convert v1 BSUP to SUP (using old binary), then back to v2 BSUP (using new binary)
super-0.2.0 -s data.bsup > data.sup
super -f bsup data.sup > data-v2.bsup
```

### collect on empty stream returns null

> **Superseded in v0.4.0:** `collect()` on an empty stream now returns `[]`.

In 0.1.0 through 0.3.0, `collect()` on an empty stream returns `null` instead of producing
no output. This can cause subtle downstream bugs — `this in null` drops all
records instead of preserving them:

```
-- Empty collect returns null:
values [1,2,3] | unnest this | where false | collect(this)
-- Returns: null

-- Downstream gotcha: "not in null" filters out everything:
values ["a","b","c"] | unnest this | where not (this in null) | collect(this)
-- Returns: null  (all records dropped!)

-- Guard with coalesce or check for empty array:
values ["a","b","c"] | unnest this
  | where not (this in coalesce(null, []))
  | collect(this)
-- Returns: ["a","b","c"]
```

### collect and union drop quiet errors

> **Superseded in v0.4.0:** `quiet()` and `error("quiet")` were removed.

In `collect` and `union` aggregate functions, `error("quiet")` values are now
dropped. `error("missing")` values are still preserved.

### null values ignored in concat and f-strings

The `concat` function and f-string interpolation now silently ignore `null`
values instead of propagating them.

### New features in v0.3.0

#### `debug` operator

Tap into a pipeline to emit debugging values to stderr without affecting the
main output. Supports an optional expression and filter clause:

```
values 1,2,3 | debug f'val={this}' filter (this > 1) | pass
```

Debug output goes to stderr in SUP format. See the `tutorial:debug` topic for
detailed usage including `fork`-based patterns and subquery aggregation.

#### `infer` operator

Samples input and auto-detects native types for string values, casting them
to the inferred type. Useful for cleaning up CSV or other string-heavy data:

```
infer [ <limit> ]
```

Candidate types: `int64`, `float64`, `ip`, `net`, `time`, `bool`. Default
sample size is 100 records; set to 0 to analyze all input.

#### `defuse` and `unblend` functions

> **Renamed in v0.4.0:** these are now `superdefuse()` and `defuse()`
> respectively (see [Changes in v0.4.0](#changes-in-v040)).

`defuse(val)` reverses the effects of `fuse` — converts fusion types back to
their original types by downcasting union values to their subtype equivalent.

`unblend(val)` reverses the effects of `blend` — removes union types and
eliminates optional fields without values from records.

#### Other new features

- **`db vacate` command** — vacate database pools (tables, as of v0.4.0)
- **Optional fields in record expressions** — record fields can now be marked
  optional with `?` syntax
- **Fusion types** — new type system feature for complete type fusion
- **Named types in `upcast` function** — upcast now supports named types

## Formatting Conventions

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
