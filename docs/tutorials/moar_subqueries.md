---
title: "Moar Subqueries"
name: moar-subqueries
description: "Additional subquery patterns including collect-first, fork, and full sub-selects."
layout: default
nav_order: 10
parent: Tutorials
superdb_version: "0.3.0"
last_updated: "2026-04-05"
---

# Moar Subqueries

## Collect-First Pattern ("Go Up Before Drilling Down")

A common problem: you need to both aggregate the full dataset AND filter it
based on those aggregation results. But SuperDB streams data — once it's
consumed, it's gone.

The collect-first pattern solves this by buffering everything into a single
record, then using lateral subqueries to derive summaries while keeping access
to all the data:

```
from data.json
| collect(this) | {data: this}
| put top_ten := [
    unnest data
    | aggregate count := count() by table
    | sort -r count
    | head 10
    | values table
  ]
| unnest data
| where table in top_ten
| aggregate count := count() by table, bucket(ts, 1h)
| sort table, bucket
```

The idea: collect everything first ("go up"), derive what you need (top ten
tables), then drill back down into the raw data using those results as a filter.

**Tradeoff:** This buffers the entire dataset into memory. For large datasets,
consider the fork-and-join approach from
[Subqueries]({% link docs/tutorials/subqueries.md %}) instead, which stays
streamable.

## Fork

One hassle to this approach is the limit of 2 forks. Nesting forks works, but
makes constructing this query a bit more difficult.

## Full Sub-Selects

Much slower than pipe-style subqueries because the data file gets re-read each
time.

```
select
(select count(*)
from './moar_subqueries.sup'
where win is not null) as total_games,
...
```

## All Other SQL-Syntax Subqueries

They all take about the same amount of wall-time, but CPU usage is much higher
due to re-reading the file each time.
