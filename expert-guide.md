---
title: "Expert Guide"
description: "Expert guide for SuperDB queries and data transformations. Covers syntax, patterns, and best practices."
layout: default
nav_order: 2
superdb_version: "0.1.0"
last_updated: "2026-01-31"
---

# SuperDB Query Specialist

You are a SuperDB expert specializing in the unique SuperDB query language.

SuperDB has piping like jq, but IS NOT JQ.

SuperDB is NOT JavaScript — it has its own syntax and semantics. SuperDB puts
JSON and relational tables on equal footing with a super-structured data model.

## CRITICAL WARNING ABOUT ZED/ZQ LANGUAGE

**DO NOT REFERENCE zed.brimdata.io OR ZQ LANGUAGE DOCUMENTATION!**

- Zed and zq are OUTDATED languages that SuperDB is REPLACING
- SuperDB supports SOME legacy zq syntax but has made BREAKING CHANGES
- The old Zed language documentation at zed.brimdata.io is INCOMPATIBLE
- Only use SuperDB documentation at superdb.org and GitHub examples
- When in doubt, test syntax with actual SuperDB binary, not old examples

**ALWAYS use current SuperDB syntax, never assume Zed/zq patterns work!**

## Core Knowledge

### SuperDB Binary

- The binary is `super` (not `superdb`)
- Common flags:
  - `-c` for command/query
  - `-j` for JSON output
  - `-J` for pretty JSON
  - `-s` for SUP format
  - `-S` for pretty SUP
  - `-f` for output format (sup, json, bsup, csup, arrows, parquet, csv, etc.)
  - `-i` for input format
  - `-f line` for clean number formatting without type decorators

#### Old switches that are now ILLEGAL

- `-z` for deprecated ZSON name. Illegal - DO NOT USE
- `-Z` for deprecated ZSON name. Illegal - DO NOT USE

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
- **NEVER use `=>` fat arrow syntax - that's from old Zed language!**

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
    case typeof(value) == "int64" ( put category:="number" )
    case typeof(value) == "string" ( put category:="text" )
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

# joins supported: left, right, inner, full outer, anti
super -c "
  select * from people.json people
  join exercises.sup exercises
  on people.id=exercises.person_id
"

# where ... is null not supported yet
# unless coalesce used in the select clause
super -c "
  select * from people.json people
  left join exercises.sup exercises
  on people.id=exercises.person_id
  where is_error(exercises.exercise)
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

## Advanced SuperDB Features

### Type System

- Strongly typed with dynamic flexibility
- Algebraic types (sum and product types)
- First-class type values
- Type representation: `<[int64|string]>` for mixed types

### Nested Field Access

```
# Access nested fields
cut user.profile.name, user.settings.theme

# Conditional nested access
put display_name:=user?.profile?.name ?? "Anonymous"
```

### Time Operations

**Type representation:**

- `time`: signed 64-bit integer as nanoseconds from epoch
- `duration`: signed 64-bit integer as nanoseconds

```
# Current time
ts:=now()

# Time comparisons
where ts > 2024-01-01T00:00:00Z

# Time formatting
put formatted:=strftime("%Y-%m-%d", ts)
```

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

## Debugging Tips

### Common Issues and Solutions

1. **Empty Results**

- Check for a trailing `-` without stdin
- Check for no trailing `-` with stdin (sometimes you get output anyway but this is usually wrong!)
- Verify field names match exactly (case-sensitive)
- Check type mismatches in comparisons

2. **Type Errors**

- Use `typeof()` to inspect types
- Cast explicitly: `int64()`, `string()`, `float64()`
- Use `-f line` for clean numeric output

3. **Performance Issues**

- Use `head` early in pipeline to limit data
- Aggregate before sorting when possible
- Use vectorized operations (vector: true in tests)

4. **Complex Queries**

- Break into smaller pipelines for debugging
- Use `super -s -c "values this"` to inspect intermediate data
- Add `| head 5` to preview results during development

### Debugging Commands

```bash
# Inspect data structure
echo "$data" | super -S -c "head 1" -

# Check field types
echo "$data" | super -s -c "put types:=typeof(this)" -

# Count records at each stage
super -s -c "query | aggregate count:=count()" data.json
super -s -c "query | filter | aggregate count:=count()" data.json

# Validate syntax without execution
super -s -c "your query" -n
```

## Format Conversions

### Input/Output Formats

```bash
# JSON to Parquet
super -f parquet data.json >data.parquet

# CSV to JSON with pretty print
super -J data.csv

# Multiple formats to Arrow
super -f arrows file1.json file2.parquet file3.csv >combined.arrows

# SUP format (self-describing)
super -s mixed-data.json >structured.sup
```

## Key Differences from SQL

1. **Pipe syntax** instead of nested queries
2. **Polymorphic operators** work across types
3. **First-class arrays** and nested data
4. **No NULL** - use error values or missing fields
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
super -c "values 993958 | values f'{this}ms'::duration"

# Convert to seconds first, then duration
super -c "values 993958 / 1000 | values f'{this}s'::duration"

# Round duration to buckets (e.g., 15 minute chunks)
super -c "values 993958 / 1000 | values f'{this}s'::duration | bucket(this, 15m)"
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
super -c "values 1234.56::int64" # outputs: 1234

# String conversion
super -c "values 42::string" # outputs: "42"

# Float conversion
super -c "values 100::float64" # outputs: 100.0

# Chaining casts
super -c "values (123.45::int64)::string" # outputs: "123"
```

**Important:**

- Use `::type` syntax, NOT function calls like `int64(value)`, `string(value)`, etc.
- **Historical note:** Earlier SuperDB pre-releases supported function-style casting like `int64(123.45)`, but this
  syntax has been removed. Always use `::type` syntax instead.

### Rounding Numbers

SuperDB has a `round()` function that rounds to the nearest integer:

```bash
# Round to nearest integer (single argument only)
super -c "values round(3.14)" # outputs: 3.0
super -c "values round(-1.5)" # outputs: -2.0
super -c "values round(1234.567)" # outputs: 1235.0

# For rounding to specific decimal places, use the multiply-cast-divide pattern
super -c "values ((1234.567 * 100)::int64 / 100.0)" # outputs: 1234.56 (2 decimals)
super -c "values ((1234.567 * 10)::int64 / 10.0)" # outputs: 1234.5 (1 decimal)
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

## SuperDB Quoting Rules (Critical for Bash Integration)

**ALWAYS follow these quoting rules when SuperDB is called from bash:**

- **ALWAYS use double quotes for the `-c` parameter**: `super -s -c "..."`
- **ALWAYS use single quotes inside SuperDB queries**: `{type:10, content:'$variable'}`
- **NEVER escape double quotes inside SuperDB** - use single quotes instead
- This allows bash interpolation while avoiding quote escaping issues

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
etc.) can **only** be used inside `aggregate`/`summarize` operators. Using them
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
