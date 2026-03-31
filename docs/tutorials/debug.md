---
title: "debug"
name: debug
description: "Guide to the debug operator for tapping pipelines and inspecting intermediate values."
layout: default
nav_order: 3
parent: Tutorials
superdb_version: "0.3.0"
last_updated: "2026-03-28"
---

# debug

The `debug` operator lets you tap into a pipeline to inspect intermediate values
without affecting the main output. It has this signature:

```
debug [ <expr> ] [ filter ( <pred> ) ]
```

Debug output goes to **stderr** in SUP format, while the main pipeline flows
through to stdout unchanged. This makes it a non-invasive way to see what's
happening inside a query.

## Basic usage

With no arguments, `debug` sends every value to stderr as-is. The main pipeline
is unaffected. Use `| where false` to suppress normal output so you can see
just the debug side:

```mdtest-command
super -s -c "
  values 1, 2, 3
  | debug
  | where false
" 2>&1
```
```mdtest-output
1
2
3
```

All three values flowed through debug to stderr. Meanwhile the main output
(stdout) is empty because `where false` filtered everything. Without `2>&1`,
you'd see the debug output on your terminal's stderr while stdout stays empty.

Now look at just the main pipeline — suppressing stderr with `2>/dev/null`:

```mdtest-command
super -s -c "
  values 1, 2, 3
  | debug
  | where this > 1
" 2>/dev/null
```
```mdtest-output
2
3
```

The `debug` operator didn't change what passes through. Only values greater
than 1 made it past the `where` filter.

## Debug with an expression

You can transform what gets emitted to debug output by providing an expression.
This is useful for adding labels or extracting specific fields. The expression
only affects what goes to stderr — the pipeline still sees the original values.

```mdtest-command
super -s -c "
  values 10, 20, 30
  | debug this * 2
  | where false
" 2>&1
```
```mdtest-output
20
40
60
```

The debug output shows doubled values. The main pipeline (if we hadn't filtered
it) would still see 10, 20, 30.

You can wrap values in a record to add context:

```mdtest-command
super -s -c "
  values {name:\"alice\",age:30}, {name:\"bob\",age:17}
  | debug {check:name}
  | where false
" 2>&1
```
```mdtest-output
{check:"alice"}
{check:"bob"}
```

## Debug with filter

The `filter` clause controls **which values trigger debug output**. Only values
matching the predicate are emitted to stderr. This is syntax specific to the
`debug` operator — not the standalone `where` operator.

```mdtest-command
super -s -c "
  values 1, 2, 3, 4, 5
  | debug filter (this > 3)
  | where false
" 2>&1
```
```mdtest-output
4
5
```

Only 4 and 5 matched the filter, so only they appeared in debug output. All
five values still pass through the main pipeline regardless.

You can combine an expression with a filter:

```mdtest-command
super -s -c "
  values {x:1,y:2}, {x:3,y:4}
  | debug y filter (x=1)
  | where false
" 2>&1
```
```mdtest-output
2
```

This emits `y` to debug output, but only for records where `x=1`.

## Practical example: grading with debug alerts

Here's a more realistic use case. Say you're processing exam scores — you want
to add a `pass` field to every record, write the results to a file, and get
alerts on stderr for anyone who failed badly.

A single command does all three. Redirect stdout to a file and the debug
alerts appear on your terminal via stderr:

```mdtest-command
super -s -c "
  values
    {name:\"alice\",score:85},
    {name:\"bob\",score:42},
    {name:\"carol\",score:91},
    {name:\"dave\",score:67}
  | debug f'FAIL: {name} ({score})' filter (score < 70)
  | put pass:=score >= 70
  | sort name
" > /tmp/scores.sup
```
```mdtest-output
"FAIL: bob (42)"
"FAIL: dave (67)"
```

The failures showed up on your terminal while the results went to the file.
Every student has the new `pass` field:

```mdtest-command
cat /tmp/scores.sup
```
```mdtest-output
{name:"alice",score:85,pass:true}
{name:"bob",score:42,pass:false}
{name:"carol",score:91,pass:true}
{name:"dave",score:67,pass:false}
```

The `debug` operator didn't change the pipeline — every record flows through
with `pass` added. It just tapped into the stream to flag the failures on
stderr.

## Advanced: debug with a subquery

Since `debug` operates per-value, it can't aggregate across the whole stream by
itself. But you can use `collect` to gather all records, then use a `(...)`
lateral subquery inside debug to compute a summary.

Building on the previous example, let's add a count of total failures to the
debug output. The trick is: first debug the per-record failures, then collect
into an array, debug the count via a subquery, and unnest back out:

```mdtest-command
super -s -c "
  values
    {name:\"alice\",score:85},
    {name:\"bob\",score:42},
    {name:\"carol\",score:91},
    {name:\"dave\",score:67}
  | put pass:=score >= 70
  | debug f'FAIL: {name} ({score})' filter (pass=false)
  | collect(this)
  | debug (unnest this
           | where pass=false
           | count()
           | values f'{this} student(s) failed')
  | unnest this
  | sort name
" > /tmp/scores.sup
```
```mdtest-output
"FAIL: bob (42)"
"FAIL: dave (67)"
"2 student(s) failed"
```

The first `debug` fires per-record, flagging each failure. Then after `collect`
gathers everything into a single array, the second `debug` runs a `(...)`
subquery that unnests the array, filters to failures, counts them, and formats
a summary.

The file still has the same clean output:

```mdtest-command
cat /tmp/scores.sup
```
```mdtest-output
{name:"alice",score:85,pass:true}
{name:"bob",score:42,pass:false}
{name:"carol",score:91,pass:true}
{name:"dave",score:67,pass:false}
```

## Alternative: fork instead of collect/unnest

The `collect`/`unnest` sandwich works, but it buffers the entire dataset into
memory. The `fork` operator offers an alternative — each branch processes the
data independently:

```mdtest-command
super -s -c "
  values
    {name:\"alice\",score:85},
    {name:\"bob\",score:42},
    {name:\"carol\",score:91},
    {name:\"dave\",score:67}
  | put pass:=score >= 70
  | fork
    (debug f'FAIL: {name} ({score})' filter (pass=false)
     | where pass=false
     | count()
     | debug f'{this} student(s) failed'
     | where false)
    (sort name)
" > /tmp/scores.sup
```
```mdtest-output
"FAIL: bob (42)"
"FAIL: dave (67)"
"2 student(s) failed"
```

```mdtest-command
cat /tmp/scores.sup
```
```mdtest-output
{name:"alice",score:85,pass:true}
{name:"bob",score:42,pass:false}
{name:"carol",score:91,pass:true}
{name:"dave",score:67,pass:false}
```

The first fork branch handles all the debug output: per-record failure alerts,
then filters to just failures, counts them, and emits a summary via a second
`debug`. The `where false` at the end drops everything from that branch's stdout.
The second branch is just the clean main output.

Note that the `filter` clause on `debug` only controls what goes to stderr — it
doesn't filter the branch itself. That's why `where pass=false` is needed again
before `count()`.

### Streaming behavior

The key advantage of `fork` is that the main branch can emit results
immediately while the debug branch accumulates. With `collect`/`unnest`,
nothing can emit until the entire dataset is buffered.

You can see this with a large input — pipe a million numbers in, fork into a
debug count and a main branch that filters to milestones:

```mdtest-command
seq 1 1000000 | super -s -c "
  fork
    (count() | debug f'{this} total records' | where false)
    (where this % 100000 = 0 | head 5)
" -
```
```mdtest-output
100000
200000
300000
400000
500000
"1000001 total records"
```

The milestones appear **before** the debug count — they streamed through as the
data flowed. Compare with `collect`/`unnest`, where the count appears **first**
because everything must be buffered before any output:

```mdtest-command
seq 1 1000000 | super -s -c "
  collect(this)
  | debug (unnest this | count() | values f'{this} total records')
  | unnest this
  | where this % 100000 = 0
  | head 5
" -
```
```mdtest-output
"1000001 total records"
100000
200000
300000
400000
500000
```

`fork` also uses O(1) memory for the counting branch (just an integer
accumulator), while `collect` stores every record in an array (O(n)). The
`collect`/`unnest` approach is more compact and keeps the aggregation in a
single self-contained subquery, but `fork` scales better.

## Mixing SQL and pipeline debug

SQL and pipeline syntax can be mixed freely. Use SQL `SELECT` for the
relational logic, then pipe into `debug` for instrumentation. This also
shows `FROM (values ...)` — inline data in a SQL FROM clause:

```mdtest-command
super -s -c "
  SELECT *, score >= 70 as pass
  FROM (values
    {name:\"alice\",score:85},
    {name:\"bob\",score:42},
    {name:\"carol\",score:91},
    {name:\"dave\",score:67})
  | fork
    (debug f'FAIL: {name} ({score})' filter (pass=false)
     | where pass=false
     | count()
     | debug f'{this} student(s) failed'
     | where false)
    (sort name)
" > /tmp/scores.sup
```
```mdtest-output
"FAIL: bob (42)"
"FAIL: dave (67)"
"2 student(s) failed"
```

```mdtest-command
cat /tmp/scores.sup
```
```mdtest-output
{name:"alice",score:85,pass:true}
{name:"bob",score:42,pass:false}
{name:"carol",score:91,pass:true}
{name:"dave",score:67,pass:false}
```

The SQL handles the data shaping (`SELECT *, score >= 70 as pass`), then the
pipeline takes over for the debug side-channel. This is a natural split — use
each syntax for what it's best at.

## Using fn and op with debug

User-defined functions work in debug's `filter` clause, which is a clean way to
name your predicates:

```mdtest-command
super -s -c "
  fn is_fail(s): s < 70
  values {name:\"alice\",score:85},{name:\"bob\",score:42}
  | debug f'FAIL: {name} ({score})' filter (is_fail(score))
  | where false
" 2>&1
```
```mdtest-output
"FAIL: bob (42)"
```

Debug also works inside `op` bodies, so you can package up a debug-instrumented
pipeline for reuse:

```mdtest-command
super -s -c "
  op grade_report: (
    fork
      (debug f'FAIL: {name} ({score})' filter (score < 70)
       | where false)
      (put pass:=score >= 70 | sort name)
  )
  values {name:\"alice\",score:85},{name:\"bob\",score:42},{name:\"carol\",score:91},{name:\"dave\",score:67}
  | grade_report
" > /tmp/scores.sup
```
```mdtest-output
"FAIL: bob (42)"
"FAIL: dave (67)"
```

```mdtest-command
cat /tmp/scores.sup
```
```mdtest-output
{name:"alice",score:85,pass:true}
{name:"bob",score:42,pass:false}
{name:"carol",score:91,pass:true}
{name:"dave",score:67,pass:false}
```

## Notes

- Debug output is always in SUP format, even when the main output uses `-j`,
  `-f csv`, etc.
- The `filter` clause is part of the `debug` operator's syntax, not a separate
  pipeline stage.
- `debug` passes all input values through to its output unchanged, whether or
  not they match the filter.
- When using the superdb-mcp server, debug output is returned in a `debug`
  field in the query result.

## as of versions

```mdtest-command
super --version
```
```mdtest-output
Version: v0.3.0
```
