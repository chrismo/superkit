---
title: "Expert Guide"
name: superdb-expert
description: "Expert guide for SuperDB queries and data transformations. Covers syntax, patterns, and best practices."
layout: default
nav_order: 2
superdb_version: "0.4.0"
last_updated: "2026-10-31"
---

# SuperDB Expert Guide

SuperDB is a command-line tool and query engine that puts JSON and relational
tables on equal footing with a super-structured data model. It uses a
Unix-inspired pipeline syntax similar to jq but with its own distinct language
and semantics. This guide covers SuperDB's query syntax, patterns, and best
practices.

## Note on Zed/zq Compatibility

**SuperDB replaces the older Zed/zq toolchain and has breaking changes.**
The Zed language documentation at zed.brimdata.io is outdated and incompatible
with current SuperDB syntax. Use SuperDB documentation at superdb.org and
GitHub examples instead. When in doubt, test syntax with the actual `super`
binary rather than relying on old Zed/zq examples.

## Core Knowledge

### SuperDB Binary

- The binary is `super` (not `superdb`)
- Common flags:
  - `-c` for command/query
  - `-j` for JSON output
  - `-J` for pretty JSON
  - `-s` for SUP format
  - `-S` for pretty SUP
  - `-f` for output format (sup, json, bsup, arrows, parquet, csv, tsv, line,
    zeek, db). BSUP output is columnar by default; add `-rows` for row frames
  - `-i` for input format (`-i auto` requests auto-detection)
  - `-o file.ext` writes to a file; without `-f`, the output format follows the
    extension (e.g. `-o out.json`)
  - `-f line` for clean number formatting without type decorators
  - `-static` statically type-checks all inputs; `-dynamic` turns it off
  - `-unbuffered` flushes each result as soon as it's ready
  - `-fusion` shows fusion values in SUP output (otherwise auto-defused)

#### Input format comes from the file extension (v0.4.0+)

The format of a **local file** is determined by its extension (`.json`,
`.sup`, `.csv`, `.parquet`, `.bsup`, ..., including `.gz`-compressed versions),
not by sniffing its contents. A file with no extension or an unrecognized one
needs `-i`:

```bash
super -s data.json        # JSON, from the extension
super -s -i json noext    # no extension: format required
super -s -i auto noext    # ask for auto-detection explicitly
```

Auto-detection is still the default for stdin (`-`) and for HTTP, HTTPS, and
S3 URLs without a recognized extension. A format argument on a `from`
operator takes precedence, then `-i`, then the extension.

#### Static type checking

BSUP, Parquet, Arrow, and SUP inputs are statically type-checked by default.
JSON, CSV, and stdin inputs are *dynamic* unless you pass `-static`. Some SQL
features need static types, so on JSON input you may see:

- `the all-columns (*) pattern cannot be used for dynamic inputs`
- `join on dynamic column "l" requires table-qualified reference`

Add `-static` to fix both:

```bash
super -static -s -c 'select * from "data.json"'
super -static -s -c 'select l.id, r.name from "a.json" l join "b.json" r on l.id=r.id'
```

On statically typed input, referencing a field that may be absent is a
compile-time error (`field may be missing (consider ok())`); see
[Missing Fields, `ok()`, and None](#missing-fields-ok-and-none).

#### Removed switches

- `-z` for deprecated ZSON name. **Removed** — no longer accepted.
- `-Z` for deprecated ZSON name. **Removed** — no longer accepted.
- `-sam`, `-vam`, and `SUPER_RUNTIME`: **Removed** in v0.4.0 (vector runtime only).
- `-samplesize`, `-persist`, `-fusemem`, and `-bsup.*`: **Removed** in v0.4.0.
- `-f csup`, `-f jsup`, and `-f table`: **Removed** in v0.4.0 (CSUP merged into BSUP).

### Critical Rules

1. **Trailing dash**: ONLY use `-` at the end of a super command when piping
   stdin. Never use it without stdin or super returns empty.

- Bad: `super -j -c "values {token: \"$token\"}" -` (no stdin)
- Good: `super -j -c "values {token: \"$token\"}"` (no stdin, no dash)
- Good: `echo "$data" | super -j -c "query" -` (has stdin, has dash)

2. **Syntax differences from JavaScript**:

- Use `values` instead of `yield`
- Use `unnest` instead of `over`
- Type casting: `cast(myvar, <int64>)` may require either `-s` or `-f line` for clean output.
- Method-style calls work (v0.4.0+): `s.trim().upper()` is `upper(trim(s))`,
  and `s.split(",")` is `split(s, ",")`

## Language Syntax Reference

### Pipeline Pattern

SuperDB uses Unix-inspired pipeline syntax:

```
command | command | command | ...
```

### Fork Operations (Parallel Processing)

SuperDB supports fork operations for parallel data processing:

```
from source
| fork
  ( operator | filter | transform )
  ( operator | different_filter | transform )
| join on condition
```

- Each branch runs in parallel using parentheses syntax
- Branches can be combined, merged, or joined
- Without explicit join/merge, an implied "combine" operator forwards values
- **Note:** The `=>` fat arrow syntax from the old Zed language is not supported.

## PostgreSQL Compatibility & Traditional SQL

SuperDB is rapidly evolving toward full PostgreSQL compatibility while maintaining
its unique pipe-style syntax. You can use either traditional SQL or pipe syntax.

### SQL Compatibility Features

- **Backward compatible**: Any SQL query is also a SuperSQL query
- **Embedded SQL**: SQL queries can appear as pipe operators anywhere
- **Mixed syntax**: Combine pipe and SQL syntax in the same query
- **SQL scoping**: Traditional SQL scoping rules apply inside SQL operators

### Common Table Expressions (CTEs)

SuperDB supports CTEs using standard WITH clause syntax:

```sql
with user_stats as (select user_id, count(*) as total_actions
                    from events
                    where date >= '2024-01-01'
                    group by user_id),
     active_users as (select user_id
                      from user_stats
                      where total_actions > 10)
select *
from active_users;
```

### Traditional SQL Syntax

Standard SQL operations work alongside pipe operations:

```sql
-- Basic SELECT
select id, name, email
from users
where active = true;

-- JOINs
select u.name, p.title
from users u
         join projects p on u.id = p.owner_id;

-- Subqueries
select name
from users
where id in (select user_id from projects where status = 'active');
```

### SQL + Pipe Hybrid Queries

Combine SQL and pipe syntax for maximum flexibility:

```sql
select union(type) as kinds, network_of(srcip) as net
from ( from source | ? "example.com" and "urgent")
where message_length > 100
group by net;
```

### PostgreSQL-Compatible Features

- Window functions are **not yet implemented** (planned post-GA, see [#5921](https://github.com/brimdata/super/issues/5921))
- Advanced JOIN types (LEFT, RIGHT, FULL OUTER, CROSS)
- Aggregate functions (COUNT, SUM, AVG, MIN, MAX, STRING_AGG)
- CASE expressions and conditional logic
- Date/time functions and operations
- Array and JSON operations
- Regular expressions (SIMILAR TO, regexp functions)

**Note**: PostgreSQL compatibility is actively being developed. Some features
may have subtle differences from pure PostgreSQL behavior.

### Core Operators

#### unnest

Flattens arrays into individual elements:

```
# Input: [1,2,3]
# Query: unnest this
# Output: 1, 2, 3
```

#### switch

Conditional processing with cases:

```
switch
  case a == 2 ( put v:='two' )
  case a == 1 ( put v:='one' )
  case a == 3 ( values null )
  case true ( put a:=-1 )
```

**Adding fields with switch:**
Use `put field:='value'` to add new fields to records:

```
| switch
    case period=='today' ( put prefix:='Daily milestone' )
    case period=='week' ( put prefix:='Weekly milestone' )
    case true ( put prefix:='All time milestone' )
```

#### cut

Select specific fields (like SQL SELECT):

```
cut field1, field2, nested.field, new_name:=old_name
```

NOTE: you can REORDER the output with cut as well.

#### drop

Remove specific fields:

```
drop unwanted_field, nested.unwanted
```

#### put

Add or modify fields:

```
put new_field:=value, computed:=field1+field2
```

#### join

Combine data streams:

```
join on key=key other_stream
```

#### search

Pattern matching:

```
search "keyword"
search /regex_pattern/
? "keyword"  # shorthand for search
```

#### where

Filter records:

```
where field > 100 AND status == "active"
```

#### aggregate/summarize

Group and aggregate data:

```
aggregate count:=count(), sum:=sum(amount) by category
summarize avg(value), max(value) by group
```

#### sort

Order results:

```
sort field
sort -r field  # reverse
sort field1, -field2  # multi-field
```

#### head/tail

Limit results:

```
head 10
tail 5
```

#### uniq

Remove duplicates:

```
uniq
uniq -c  # with count
```

## Practical Query Patterns

### Basic Transformations

```bash
# Convert JSON to SUP
super -s data.json

# Filter and transform
echo '{"a":1,"b":2}' | super -s -c "put c:=a+b | drop a" -

# Type conversion with clean output
super -f line -c "int64(123.45)"
```

### Complex Pipelines

```bash
# Search, filter, and aggregate - return JSON
super -j -c '
  search "error"
  | where severity > 3
  | aggregate count:=count() by type
  | sort -count
' logs.json

# Fork operation with parallel branches - return SuperJSON text
super -s -c '
  from data.json
  | fork
    ( where type=="A" | put tag:="alpha" )
    ( where type=="B" | put tag:="beta" )
  | sort timestamp
'
```

### Data Type Handling

```bash
# Mixed-type arrays - return pretty-printed JSON
echo '[1, "foo", 2.3, true]' | super -J -c "unnest this" -

# Type switching - return pretty-printed SuperJSON
super -S -c '
  switch
    case typeof(value) == <int64> ( put category:="number" )
    case typeof(value) == <string> ( put category:="text" )
    case true ( put category:="other" )
' mixed.json
```

### SQL Syntax Examples

Traditional SQL syntax works seamlessly with SuperDB:

#### Traditional SELECT queries
```bash
super -s -c "SELECT * FROM users WHERE age > 21" users.json
```

#### CTEs (Common Table Expressions)
```bash
super -s -c "
WITH recent_orders AS (
  SELECT customer_id, order_date, total
  FROM orders
  WHERE order_date >= '2024-01-01'
),
customer_totals AS (
  SELECT customer_id, SUM(total) as yearly_total
  FROM recent_orders
  GROUP BY customer_id
)
SELECT c.name, ct.yearly_total
FROM customers c
JOIN customer_totals ct ON c.id = ct.customer_id
WHERE ct.yearly_total > 1000;
" orders.json
```

#### Mixed SQL and pipe syntax
```bash
super -s -c "
SELECT name, processed_date
FROM ( from logs.json | ? 'error' | put processed_date:=now() )
WHERE processed_date IS NOT NULL
ORDER BY processed_date DESC;
" logs.json
```

#### Joins
```bash
echo '{"id":1,"name":"foo"}
{"id":2,"name":"bar"}' > people.json

echo '{id:1,person_id:1,exercise:"tango"}
{id:2,person_id:1,exercise:"typing"}
{id:3,person_id:2,exercise:"jogging"}
{id:4,person_id:2,exercise:"cooking"}' > exercises.sup

# joins supported: left, right, inner, anti (full outer still behaves like left)
# -static is needed because people.json is a dynamic (JSON) input
super -static -s -c "
  select * from people.json people
  join exercises.sup exercises
  on people.id=exercises.person_id
"

# unmatched columns are null (v0.4.0+; earlier releases gave error("missing"))
super -static -s -c "
  select * from people.json people
  left join exercises.sup exercises
  on people.id=exercises.person_id
  where exercises.exercise is null
"
```

#### WHERE Clause Tips

##### Negation

`where !(this in $json)` is invalid!

`where not (this in $json)` is valid!

### Tips

- Merge together `super` calls whenever you can.

**Not as Good**

```bash
_current_tasks "| where done==true" | super -s -c "count()" -
```

**Better**

```bash
_current_tasks | super -s -c "where done==true | count()" -
```

## Advanced Patterns

### Finding Syntax Errors in .sup Files

Read each line as a raw string and test it individually with `parse_sup()`.
The first error reported is the real problem:

```
super -i line -j -c '
  values {raw: this, parsed: parse_sup(this)}
  | where is_error(parsed)
  | cut raw
' broken-file.sup
```

### Crosstab Pattern

SQL crosstab using CASE/WHEN to pivot rows into columns:

```sql
SELECT
  coalesce(category, 'Total') as _,
  SUM(CASE WHEN win = true THEN count ELSE 0 END) AS win,
  SUM(CASE WHEN win = false THEN count ELSE 0 END) AS loss
GROUP BY _
```

### Fork and Join for Inline Data

Use `fork` with inline structured data to split and rejoin streams:

```
values {
  data:[{id:1,s:'a'},{id:2,s:'b'},{id:3,s:'c'}],
  match:[{id:2},{id:3}]
}
| fork
  ( unnest data )
  ( unnest match )
| inner join on left.id=right.id
```

See the [Subqueries tutorial](tutorials/subqueries) for fork-and-join as a
streamable alternative to `collect`-based correlated subqueries, and
[Moar Subqueries](tutorials/moar_subqueries) for the collect-first "go up
before drilling down" pattern.

### Aggregate Filters

Use `filter (expr)` on aggregate functions for conditional aggregation.
Non-matches produce a count of 0 instead of empty output:

```
-- Count of 0 for non-matches:
values 1, 2 | count() filter (this == 3)
-- => 0

-- Conditional collection:
unnest [{dir:"out",v:"90"},{dir:"in",v:"561"},{dir:"in",v:"306"}]
| in_vals:=collect(v) filter (dir=="in"),
  out_vals:=collect(v) filter (dir=="out")
```

### Record vs Map Types

Key distinction between Records and Maps:

- `{a:1}` is a Record (unquoted keys)
- `map{"a":1}` is a Map (literal primitive keys). Before v0.4.0 this was
  written `|{"a":1}|`
- `set[1,2]` is a Set. Before v0.4.0 this was written `|[1,2]|`
- `put` and spread only work with Records, not Maps or Unions
- Map keys must be literal primitive types
- `collect_map` requires a Map Expression argument — use `map{key:val}` syntax,
  not a Record expression
- `keys()` and `values()` return the keys and values of a record or a map

### Converting Map to Record

Maps and Records are separate types. To build a Record from key/value rows,
collect `{path,value}` pairs and `unflatten` them:

```
-- collect_map produces a Map:
values {k:"a",v:1}, {k:"b",v:2} | collect_map(map{k:v})
-- => map{"a":1,"b":2}

-- Build a Record directly:
values {k:"a",v:1}, {k:"b",v:2}
| aggregate r:=collect({path:[k],value:v})
| values unflatten(r)
-- => {a:1,b:2}

-- Or convert an existing Map by stripping the "map" prefix and re-parsing:
values map{"a":1,"b":2}
| values parse_sup((this::string)[3:])
-- => {a:1,b:2}
```

### Which Builtins Need Explicit `this`

Most aggregate functions need `this` passed in explicitly:

- **Implicit** (no argument): `count()`
- **Explicit**: `and(this)`, `any(this)`, `array_agg(this)`, `avg(this)`,
  `collect(this)`, `dcount(this)`, `fuse(this)`, `max(this)`, `min(this)`,
  `or(this)`, `sum(this)`, `union(this)`
- **Oddball**: `collect_map(map{key:val})` — needs a Map Expression, not `this`

`collect()`, `array_agg()`, and `union()` keep `null` values, and `collect()`
and `array_agg()` preserve input order (v0.4.0+). `array_agg(distinct x)` is
supported.

Functions that changed in 0.1.0 to require explicit `this`:
- `grep('pattern', this)` (was `grep(/pattern/)`)
- `is(this, <type>)` (was `is(<type>)`)
- `nest_dotted(this)` (was `nest_dotted()`)

### Expressions Inside `put`

Pipelines work inside `put` expressions — no lateral subquery hack needed:

```
values {arn:"arn:aws:kms:us-east-1:000000000000:key/abc123"}
| put region:=(split(this.arn, ':') | this[3])
-- => {arn:"arn:aws:kms:us-east-1:000000000000:key/abc123",region:"us-east-1"}
```

Direct indexing also works: `put region:=split(this.arn, ':')[3]`

### String Slicing

SuperDB uses exclusive end index (like Python):

```
"aoeusnth"[0:-1]
-- => "aoeusnt" (last char excluded)
"aoeusnth"[0:]
-- => "aoeusnth" (full string)
```

### search vs where for Regex

- `search 'pattern'` — search all fields
- `where grep('pattern', this)` — filter with regex in where clause
- As of v0.4.0, `grep()` and search expressions match values only, not field
  names
- No `=~` operator exists in SuperDB

### Deep Walk (Recursive Transformation)

A recursive function that walks nested structures, applying a
transformation at every leaf:

```
fn walk(v):
  case kind(v)
  when "array" then
    [unnest v | walk(this)]
  when "record" then
    unflatten([unnest flatten(v) | {path,value:walk(value)}])
  else v+1
  end
values walk([{x:[1,2]},{y:3}])
-- => [{x:[2,3]},{y:4}]
```

As of v0.4.0, `flatten()` returns `{path,value}` records (it was
`{key,value}`) and descends into arrays, sets, and maps, using integer
positions and map keys as path elements. `paths()` returns just the paths and
replaces the old `fields()`:

```
values flatten({x:[1,2],y:{z:3}})
-- => [{path:["x",0],value:1},{path:["x",1],value:2},{path:["y","z"],value:3}]
values paths({a:[1,2],b:{c:3}})
-- => [["a",0],["a",1],["b","c"]]
```

## Advanced SuperDB Features

### Type System

- Strongly typed with dynamic flexibility
- Algebraic types (sum and product types)
- First-class type values
- Type representation: `<[int64|string]>` for mixed types
- Unions are flat: an anonymous union can't contain another anonymous union
- Named types are declared with `type` statements, not inline:

```
type port=uint16
values 80::port
-- => 80::port
```

- Recursive types: `type JSON=string|float64|bool|null|[JSON]|map{string:JSON}`
- Native `uuid` type: `'0190a6d4-3e2b-7b3c-8f2a-0a1b2c3d4e5f'::uuid`
- `any` is a type that any value can be cast to (it becomes a `fusion(all)`)
- Reserved SQL types (`date`, `time`, `interval`, `decimal`, `int128`,
  `geometry`, `geography`) exist but casting to them errors with
  "type not yet implemented"
- A type declaration can bind a name to a type computed by a query:
  `type T = (from data.sup | fuse(this))`
- The dot operator navigates into type values: `<{a:{b:string}}>.a.b` is
  `<string>`
- `sum_type(map{"Cat":<{meow:bool}>,"Dog":<{woof:int64}>})` builds a union of
  named types

#### Option types and `none`

v0.4.0 adds option types (`option(int64)`) and the `none` value, which replace
the old `error("missing")`. Optional record fields use `?`, and an absent
optional field holds a *typed* `none`:

```
{x:1, y?:2}               # y is optional and present: option(int64)
{x:1, y?:none::int64}     # y is optional and absent
```

A bare `y?:none` in a record literal crashes v0.4.0 (`panic: (*super.TypeOfNone)`),
so always give `none` a type.

An option value must be unwrapped before you use it. Arithmetic on it fails
with `none not handled (consider ?? or ?.)`. Use `??` (none coalescing) and
`?.` (optional chaining):

```
values {x:1, y?:2}, {x:1, y?:none::int64} | values y ?? 0
-- => 2
-- => 0

values {x:1, y?:{z:1}}, {x:2, y?:none::{z:int64}} | values y?.z ?? -1
-- => 1
-- => -1
```

`??` also replaces `null`: `null ?? 5` is `5`. JSON output omits fields whose
value is `none`.

#### Missing Fields, `ok()`, and None

Referencing a field that doesn't exist is now a `no such field` error, not
`error("missing")`. On statically typed input it's a compile-time error. The
`has()`, `missing()`, and `quiet()` functions are gone. Use:

- `ok(x)`: returns `none` if `x` is an error or `none`, otherwise `x`
- `is_ok(x)`: `true` if `x` exists and isn't an error or `none` (replaces `has()`)
- `not is_ok(x)` replaces `missing(x)`

```
echo '{"a":1}' | super -s -c 'values {has_a:is_ok(a), has_b:is_ok(b)}' -
-- => {has_a:true,has_b:false}

echo '{"user":{}}' | super -s -c 'values ok(user.profile.name) ?? "anon"' -
-- => "anon"
```

`?.` doesn't save you from a missing field: `user?.profile` still errors when
`profile` doesn't exist. Wrap the whole path in `ok()` instead.

In SQL, a reference to a missing field evaluates to `null`.

#### Fusion types

The fusion names were swapped in v0.4.0, restoring what `fuse` meant before
v0.3.0:

| v0.4.0           | v0.3.0 name  | What it does                                     |
|------------------|--------------|--------------------------------------------------|
| `fuse`           | `blend`      | merges types into one common type (unions)       |
| `defuse()`       | `unblend()`  | reverses `fuse`                                  |
| `superfuse`      | `fuse`       | produces fusion values (value + original type)   |
| `superdefuse()`  | `defuse()`   | reverses `superfuse`                             |

A query that still uses `fuse` or `defuse()` runs, but now does what `blend`
and `unblend()` did.

```
values {a:1}, {a:2, b:"hello"} | fuse
-- => {a:1,b:missing::(string|missing)}
-- => {a:2,b:"hello"::(string|missing)}

values {a:1}, {a:2, b:"hello"} | fuse | defuse(this)
-- => {a:1}
-- => {a:2,b:"hello"}
```

A field absent from some inputs gets a union with `missing` (`string|missing`)
rather than becoming an optional field. `optionize()` converts such a type to
one with optional fields:

```
values optionize(<{a:int64,b:string|missing}>)
-- => <{a:int64,b?:string}>
```

Fusion values are auto-defused in every output format except BSUP, so
`superfuse` output looks like its input unless you pass `-fusion`:

```bash
super -fusion -s -c 'values {a:1}, {a:2, b:"hello"} | superfuse'
# => {a:1,b:fusion(missing::(string|missing),<missing>)}
# => {a:2,b:fusion("hello"::(string|missing),<string>)}
```

An empty array, set, or map now has element type `none` (`typeof([])` is
`<[none]>`).

### Nested Field Access

```
# Access nested fields
cut user.profile.name, user.settings.theme

# Nested access that tolerates missing fields
put display_name:=ok(user.profile.name) ?? "Anonymous"
```

### Time Operations

**Type representation:**

- `timestamp`: signed 64-bit integer as nanoseconds from epoch (called `time`
  before v0.4.0; `x::time` now errors with "type not yet implemented")
- `duration`: signed 64-bit integer as nanoseconds

```
# Current time
ts:=now()

# Time comparisons
where ts > 2024-01-01T00:00:00Z

# Time formatting
put formatted:=strftime("%Y-%m-%d", ts)

# Parse a string into a timestamp
put ts:=ts_str::timestamp

# Difference between two timestamps: cast to duration
put elapsed:=(end - start)::duration
```

In v0.4.0, subtracting two timestamps returns a `timestamp` (e.g.
`1970-01-01T00:00:04Z`) instead of a `duration` (`4s`). Cast the result with
`::duration` to get a duration.

### Grok Pattern Parsing

Parse unstructured strings into structured records using predefined grok patterns:

```bash
# Parse log line with predefined patterns
grok("%{TIMESTAMP_ISO8601:timestamp} %{LOGLEVEL:level} %{GREEDYDATA:message}", log_line)

# Common pattern examples
grok("%{IP:client_ip} %{WORD:method} %{URIPATH:path}", access_log)
grok("%{NUMBER:duration:float} %{WORD:unit}", "123.45 seconds")

# With custom pattern definitions (third argument)
grok("%{CUSTOM:field}", input_string, "CUSTOM \\d{3}-\\d{4}")
```

Returns a record with named fields extracted from the input string.

**Using with raw text files:**

```bash
# Parse log file line-by-line
super -i line -s -c 'put parsed:=grok("%{TIMESTAMP_ISO8601:ts} %{LOGLEVEL:level} %{GREEDYDATA:msg}", this)' app.log

# Filter parsed results
super -i line -j -c 'grok("%{IP:ip} %{NUMBER:status:int} %{NUMBER:bytes:int}", this) | where status >= 400' access.log
```

**Using with structured data:**

```bash
# Parse string field from JSON records (no -i line needed)
echo '{"raw_log":"2024-01-15 ERROR Database connection failed"}' |
  super -j -c 'put parsed:=grok("%{TIMESTAMP_ISO8601:ts} %{LOGLEVEL:level} %{GREEDYDATA:msg}", raw_log)' -
```

### Array and Record Concatenation

Use the spread operator.

```bash
super -s -c "{a:[], b:[]} | [...a, ...b]" # => []
super -s -c "{a:[1], b:[]} | [...a, ...b]" # => [1]
super -s -c "{a:[1], b:[2,3]} | [...a, ...b]" # => [1,2,3]
```

```bash
super -s -c "{a:{}, b:{}} | [...a, ...b]" # => {}
super -s -c "{a:{c:1}, b:{}} | [...a, ...b]" # => {c:1}
super -s -c "{a:{c:1}, b:{d:'foo'}} | {...a, ...b}" # => {c:1, d:'foo'}
```

### Method-Style Calls

As of v0.4.0, the value before a dot becomes a function's first argument, and
calls can be chained:

```
values " a,b ".trim().upper().split(",")
-- => ["A","B"]
values "a b c".split(" ").join("-")
-- => "a-b-c"
```

### Passing Shell Arguments

Arguments after `--` are passed to the query as a string array constant named
`args`. This avoids quoting shell values into the query text:

```bash
super -s -c 'values args, args[0]::int64 + 1' -- 41 "hello world"
# => ["41","hello world"]
# => 42
```

## Persistent Database (Tables)

v0.4.0 renamed database _pools_ to _tables_ and added SQL DDL. Databases from
earlier releases can't be opened.

```bash
super db init ./mydb          # create a database
super db attach ./mydb        # make it the default for later commands
                              # (replaces `super db auth`/`login` and SUPER_DB)

# SQL DDL and DML; statements separated by ; share declarations
super db -s -c "
  CREATE TABLE readings (id int64 NOT NULL, foo int64, ts timestamp);
  INSERT INTO readings VALUES (1, 10, '2025-01-01T00:00:00Z'::timestamp)
"

echo '{id:2,foo:20,ts:2025-01-02T00:00:00Z}' | super db load -use readings -
super db -s -c "from readings | sort id"
super db delete -use readings -where 'id==1'
super db ls
super db -attach ./otherdb -s -c "from t"   # one-off database for one command
```

- Each SQL statement outputs a status record (`kind`, `stmt`, `info`, `error`, ...)
- `CREATE TABLE ... ORDER BY col` sets a sort key; tables are unsorted by default
- Values loaded into a typed table are cast to its type, and nothing is
  committed if any value can't be cast
- `CREATE SUPER TABLE` makes a table of any SuperSQL type, such as a sum type
  computed from the data. `super db create -type '{a:int64}' name` does the
  same from the command line:

```bash
super db -s -c "
  type Event = (
    from raw
    | fuse(this) by type
    | collect_map(map{type:optionize(fuse)})
    | sum_type(this)
  )
  create super table events Event;
  insert into events from raw
"
```
- `DROP TABLE` removes a table. `UPDATE` and `DELETE` statements aren't
  supported yet, so use `super db delete -where` (see the
  [Updating Data tutorial](tutorials/super_db_update))
- `super db vector` commands were removed

## Debugging Tips

### Common Issues and Solutions

1. **Empty Results**

- Check for a trailing `-` without stdin
- Check for no trailing `-` with stdin (sometimes you get output anyway but this is usually wrong!)
- Watch for trailing `-` inside bash loops — `while IFS= read -r line` provides
  stdin, so a `super -c "..." -` inside the loop will consume it instead of the
  pipe. Drop the `-` if the command doesn't need stdin input.
- Verify field names match exactly (case-sensitive)
- Check type mismatches in comparisons
- `collect()` on an empty stream returns `[]` as of v0.4.0 (it returned `null`
  before)

2. **Type Errors**

- Use `typeof()` to inspect types
- Cast explicitly: `int64()`, `string()`, `float64()`
- Use `-f line` for clean numeric output

3. **Performance Issues**

- Use `head` early in pipeline to limit data
- Aggregate before sorting when possible
- Store data you query repeatedly as BSUP (columnar by default) or Parquet;
  every query runs in the vector runtime as of v0.4.0

4. **Complex Queries**

- Break into smaller pipelines for debugging
- Use `super -s -c "values this"` to inspect intermediate data
- Add `| head 5` to preview results during development
- Large output may come out in a different order across runs (parallel vector
  runtime). Add an explicit `sort` / `order by` when order matters

### The `debug` operator

The `debug` operator taps into a pipeline to emit values to stderr without
affecting the main output:

```
debug [ <expr> ] [ filter ( <pred> ) ]
```

- With no args, echoes every value to stderr
- `<expr>` transforms what gets emitted (e.g., `debug f'val={this}'`)
- `filter (<pred>)` controls which values trigger debug output
- Output is always SUP format on stderr, regardless of `-f` flag

```bash
# Flag failing scores on stderr while writing results to a file
super -s -c "
  from scores.json
  | put pass:=score >= 70
  | debug f'FAIL: {name} ({score})' filter (pass=false)
  | sort name
" > results.sup
```

See `tutorial:debug` for advanced patterns including `fork`, subqueries, and
`fn`/`op` usage with debug.

### Debugging Commands

```bash
# Inspect data structure
echo "$data" | super -S -c "head 1" -

# Check field types
echo "$data" | super -s -c "put types:=typeof(this)" -

# Count records at each stage
super -s -c "query | aggregate count:=count()" data.json
super -s -c "query | filter | aggregate count:=count()" data.json

# Validate syntax without execution (prints the parsed query)
super compile -C -c "your query"
```

## Format Conversions

### Input/Output Formats

```bash
# JSON to Parquet
super -f parquet data.json >data.parquet

# CSV to JSON with pretty print
super -J data.csv

# Multiple formats to Arrow (Arrow needs one schema, so fuse mixed types first)
super -f arrows -c "fuse" file1.json file2.parquet file3.csv >combined.arrows

# SUP format (self-describing)
super -s mixed-data.json >structured.sup
```

## Key Differences from SQL

1. **Pipe syntax** instead of nested queries
2. **Polymorphic operators** work across types
3. **First-class arrays** and nested data
4. **`none` alongside `NULL`** - missing values are `none` (option types), not
   errors
5. **Type-aware operations** with automatic handling
6. **Streaming architecture** for large datasets

### Date and Time

date_trunc is a valid postgresql function, but it's not supported yet in
superdb. So you can use `bucket(now(), 1d)` instead of `date_trunc('day',
now())` for the time being.

### Duration Type Conversions

Converting numeric values (like milliseconds) to duration types uses f-string interpolation and type casting:

**Basic patterns:**

```bash
# Convert milliseconds to duration
super -s -c "values 993958 | values f'{this}ms'::duration"

# Convert to seconds first, then duration
super -s -c "values 993958 / 1000 | values f'{this}s'::duration"

# Round duration to buckets (e.g., 15 minute chunks)
super -s -c "values 993958 / 1000 | values f'{this}s'::duration | bucket(this, 15m)"
```

**Key points:**

- Use f-string interpolation: `f'{this}ms'` or `f'{this}s'`
- Cast to duration with `::duration` suffix
- Common units: `ms` (milliseconds), `s` (seconds), `m` (minutes), `h` (hours), `d` (days), `w` (weeks), `y` (years)
- **MONTH IS NOT A SUPPORTED UNIT.**
- **WEEKS ARE STRANGE:** You can use `w` in input (e.g., `'1w'::duration`, `bucket(this, 2w)`), but output always shows
  days instead of weeks (e.g., `'1w'::duration` outputs `7d`)
- Use `bucket()` function to round durations into time chunks
- Duration values can be formatted and compared like other types

### Type Casting

SuperDB uses `::type` syntax for type conversions (not function calls):

```bash
# Integer conversion (truncates decimals)
super -s -c "values 1234.56::int64" # outputs: 1234

# String conversion
super -s -c "values 42::string" # outputs: "42"

# Float conversion
super -s -c "values 100::float64" # outputs: 100.

# Chaining casts
super -s -c "values (123.45::int64)::string" # outputs: "123"
```

**Important:**

- Use `::type` syntax, NOT function calls like `int64(value)`, `string(value)`, etc.
- **Historical note:** Earlier SuperDB pre-releases supported function-style casting like `int64(123.45)`, but this
  syntax has been removed. Always use `::type` syntax instead.

### Type Inference with `infer`

The `infer` operator samples input and auto-detects native types for string
values, casting them automatically. Useful for cleaning up CSV or other
string-heavy data:

```bash
# Strings become ints, bools, timestamps, IPs where detected
echo '{"port":"80","active":"true","ts":"Jun 1, 2025"}' |
  super -s -c "infer" -
# => {port:80,active:true,ts:2025-06-01T00:00:00Z}
```

Candidate types: `int64`, `float64`, `ip`, `net`, `timestamp`, `bool`. Default
sample size is 100 records; `infer 0` analyzes all input.

### `defuse` and `superdefuse` functions

These reverse the effects of `fuse` and `superfuse` (the names swapped in
v0.4.0; see [Fusion types](#fusion-types)):

- `defuse(val)` — reverses `fuse` (formerly `unblend()`) by removing union
  types and eliminating optional fields without values
- `superdefuse(val)` — reverses `superfuse` (formerly `defuse()`) by converting
  fusion values back to their original types

### Rounding Numbers

SuperDB has a `round()` function that rounds to the nearest integer:

```bash
# Round to nearest integer (single argument only)
super -s -c "values round(3.14)" # outputs: 3.
super -s -c "values round(-1.5)" # outputs: -2.
super -s -c "values round(1234.567)" # outputs: 1235.

# For rounding to specific decimal places, use the multiply-cast-divide pattern
super -s -c "values ((1234.567 * 100)::int64 / 100.0)" # outputs: 1234.56 (2 decimals)
super -s -c "values ((1234.567 * 10)::int64 / 10.0)" # outputs: 1234.5 (1 decimal)
```

**Key points:**

- `round(value)` only rounds to nearest integer, no decimal places parameter
- For rounding to N decimals: multiply by 10^N, cast to int64, divide by 10^N
- Cast to `::int64` truncates decimals (doesn't round)

### String Interpolation and F-strings

SuperDB supports f-string interpolation for formatting output:

```
# Basic f-string with variable interpolation
| values f'Message: {field_name}'

# Type conversion needed for numbers
| values f'Count: {count::string} items'

# Multiple fields
| values f'{prefix}: {count::string} {grid_type} wins!'
```

**Important:**

- Numbers must be converted to strings using `::string` casting
- F-strings use single quotes with `f'...'` prefix
- Variables are referenced with `{variable_name}` syntax
- `null` values are silently ignored in f-strings (as of v0.3.0):
  `f'hello {null} world'` produces `"hello  world"`

### Avoid jq syntax

There's very little jq syntax that is valid in SuperDB.

- Do not use ` // 0 ` - this is only valid in jq, not in SuperDB. You can use coalesce instead.

- SuperDB uses **0-based indexing** by default. Use `pragma index_base = 1` to switch to 1-based indexing within a scope:

```
-- Default: 0-based
values [10,20,30][0]   -- 10

-- Switch to 1-based in a scope
pragma index_base = 1
values [10,20,30][1]   -- 10

-- Pragmas are lexically scoped
pragma index_base = 1
values {
  a: this[2:3],        -- 1-based: [20]
  b: (
    pragma index_base = 0
    values this[0]     -- 0-based: 10
  )
}
```

## Pragmas

Pragmas control language features and appear in declaration blocks with lexical scoping:

```
pragma <id> [ = <expr> ]
```

If `<expr>` is omitted, it defaults to `true`. Available pragmas:

- **`index_base`** — `0` (default) for zero-based indexing, `1` for one-based indexing
- **`pg`** — `false` (default, Google SQL semantics) or `true` (PostgreSQL semantics for GROUP BY identifier resolution)

## SuperDB Quoting Rules (Bash Integration)

Follow these quoting rules when calling `super` from bash:

- Use double quotes for the `-c` parameter: `super -s -c "..."`
- Use single quotes inside SuperDB queries: `{type:10, content:'$variable'}`
- Avoid escaping double quotes inside SuperDB — use single quotes instead
- This allows bash interpolation while avoiding quote escaping issues
- Single quotes are only valid in *queries*. SUP *data* (files, stdin) must use
  double-quoted strings: `echo "{a:'x'}" | super -` is a syntax error
- To pass shell values without quoting them into the query at all, use
  [`-- args`](#passing-shell-arguments)

**Examples:**

```bash
# CORRECT: Double quotes for -c, single quotes inside
super -j -c "values {type:10, content:'$message'}"

# WRONG: Single quotes for -c prevents bash interpolation
super -j -c 'values {type:10, content:"$message"}'

# WRONG: Escaping double quotes inside is error-prone
super -j -c "values {type:10, content:\"$message\"}"
```

## SuperDB Array Filtering (Critical Pattern)

**`where` operates on streams, not arrays directly**. To filter elements from an array:

**Correct pattern:**

```bash
# Filter nulls from an array
super -j -c "
  [array_elements]
  | unnest this
  | where this is not null
  | collect(this)"
```

**Key points:**

- `unnest this` - converts array to stream of elements
- `where this is not null` - filters elements (note: use `is not null`, not `!= null`)
- `collect(this)` - reassembles stream back into array

**Wrong approaches:**

```bash
# WRONG: where doesn't work directly on arrays
super -s -c "[1,null,2] | where this != null"

# WRONG: incorrect null comparison syntax
super -s -c "unnest this | where this != null"
```

## Aggregate Functions

Aggregate functions (`count()`, `sum()`, `avg()`, `min()`, `max()`, `collect()`,
etc.) can **only** be used inside `aggregate`/`summarize` operators.

For the largest or smallest of several values in one expression, use
`greatest(a, b, ...)` and `least(a, b, ...)`. These were the non-aggregate
`max()` and `min()` before v0.4.0. Using them
in expression context (e.g., `put row:=count()`) is an error:

```
call to aggregate function in non-aggregate context
```

This was changed in [PR #6355](https://github.com/brimdata/super/pull/6355).
Earlier versions of SuperDB/Zed allowed "streaming aggregations" in expression
context, but this was removed for SQL compatibility and parallelization.

### Aggregate / Summarize: Summary Output

Use `aggregate` (or `summarize`) to produce summary output. Can be parallelized.

```bash
# Single summary across all records
echo '{"x":1}
{"x":2}
{"x":3}' |
  super -j -c "aggregate total:=count(), sum_x:=sum(x)" -

# Output:
{"total":3,"sum_x":6}

# Group by category
echo '{"category":"A","amount":10}
{"category":"B","amount":20}
{"category":"A","amount":15}' |
  super -j -c "aggregate total:=sum(amount) by category | sort category" -

# Output:
{"category":"A","total":25}
{"category":"B","total":20}
```

### The `count` Operator (Row Numbering)

For sequential row numbering — the most common former use of expression-context
`count()` — use the **`count` operator** ([PR #6344](https://github.com/brimdata/super/pull/6344)):

```bash
# Default: wraps input in "that" field, adds "count" field
super -s -c "values 1,2,3 | count"
# {that:1,count:1}
# {that:2,count:2}
# {that:3,count:3}

# Custom record expression with count alias
super -s -c "values 1,2,3 | count {value:this, c}"
# {value:1,c:1}
# {value:2,c:2}
# {value:3,c:3}

# Spread input fields alongside the count
super -s -c "values {a:1},{b:2},{c:3} | count | {row:count,...that}"
# {row:1,a:1}
# {row:2,b:2}
# {row:3,c:3}
```

**No replacement exists** for other streaming patterns (`sum`, `avg`, `min`,
`max`, progressive `collect`). Window functions are planned post-GA
([#5921](https://github.com/brimdata/super/issues/5921)).
