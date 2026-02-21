---
title: "Fork as a Window Function Workaround"
description: "Using fork as a workaround for window functions to do per-group selection."
layout: default
nav_order: 3
parent: Tutorials
superdb_version: "0.1.0"
last_updated: "2026-02-20"
---

# Fork as a Window Function Workaround

Window functions like `ROW_NUMBER() OVER (PARTITION BY ...)` are not yet
available in SuperDB ([brimdata/super#5921][issue]). This tutorial shows how to
use `fork` to achieve per-group selection — picking the top N items from each
group.

[issue]: https://github.com/brimdata/super/issues/5921

## The Problem

You have a pool of available EC2 instances spread across availability zones.
You need to pick instances while maximizing AZ distribution — taking an equal
number from each zone rather than filling up from one.

```mdtest-input instances.sup
{id:"i-001",az:"us-east-1a"}
{id:"i-002",az:"us-east-1a"}
{id:"i-003",az:"us-east-1a"}
{id:"i-004",az:"us-east-1b"}
{id:"i-005",az:"us-east-1c"}
{id:"i-006",az:"us-east-1c"}
{id:"i-007",az:"us-east-1c"}
{id:"i-008",az:"us-east-1c"}
```

Distribution: 3 in `us-east-1a`, 1 in `us-east-1b`, 4 in `us-east-1c`.

## What You'd Want (Window Functions)

In SQL with window functions, this would be straightforward:

```sql
SELECT * FROM (
  SELECT *,
    ROW_NUMBER() OVER (PARTITION BY az ORDER BY id) as rn
  FROM instances
) WHERE rn <= 2
```

This assigns a row number within each AZ group, then filters to keep only the
first 2 per group. But SuperDB doesn't support this yet.

## The Fork Approach

`fork` splits the input stream into parallel branches. Each branch receives a
copy of **all** the input records, processes them independently, and the results
from every branch are merged back together into a single stream.

Here's the full query — we'll break it down step by step after:

```mdtest-command
super -s -c "
  from instances.sup
  | fork
    ( where az=='us-east-1a' | head 2 )
    ( where az=='us-east-1b' | head 2 )
    ( where az=='us-east-1c' | head 2 )
  | sort az, id
"
```
```mdtest-output
{id:"i-001",az:"us-east-1a"}
{id:"i-002",az:"us-east-1a"}
{id:"i-004",az:"us-east-1b"}
{id:"i-005",az:"us-east-1c"}
{id:"i-006",az:"us-east-1c"}
```

### Step by Step

**Step 1: `from instances.sup`** — reads all 8 records into the stream:

```mdtest-command
super -s -c "from instances.sup"
```
```mdtest-output
{id:"i-001",az:"us-east-1a"}
{id:"i-002",az:"us-east-1a"}
{id:"i-003",az:"us-east-1a"}
{id:"i-004",az:"us-east-1b"}
{id:"i-005",az:"us-east-1c"}
{id:"i-006",az:"us-east-1c"}
{id:"i-007",az:"us-east-1c"}
{id:"i-008",az:"us-east-1c"}
```

**Step 2: `fork`** — sends all 8 records into each of three branches. Each
branch sees the full input and processes it independently.

**Branch 1:** `where az=='us-east-1a'` filters to 3 records, then `head 2`
keeps the first 2:

```mdtest-command
super -s -c "from instances.sup | where az=='us-east-1a' | head 2"
```
```mdtest-output
{id:"i-001",az:"us-east-1a"}
{id:"i-002",az:"us-east-1a"}
```

(i-003 was filtered out by `head 2`)

**Branch 2:** `where az=='us-east-1b'` filters to 1 record, `head 2` returns
what's available:

```mdtest-command
super -s -c "from instances.sup | where az=='us-east-1b' | head 2"
```
```mdtest-output
{id:"i-004",az:"us-east-1b"}
```

Only 1 instance exists in this AZ. `head 2` doesn't error or pad — it just
returns what's there.

**Branch 3:** `where az=='us-east-1c'` filters to 4 records, `head 2` keeps
the first 2:

```mdtest-command
super -s -c "from instances.sup | where az=='us-east-1c' | head 2"
```
```mdtest-output
{id:"i-005",az:"us-east-1c"}
{id:"i-006",az:"us-east-1c"}
```

(i-007 and i-008 were filtered out by `head 2`)

**Step 3: implicit combine** — after the fork closes, results from all three
branches merge back into a single stream of 5 records. Fork branches run in
parallel and finish in nondeterministic order, so the combined output may be
interleaved differently on each run. This is why the final `sort` matters.

**Step 4: `sort az, id`** — sorts the combined results for clean, predictable
output:

```mdtest-command
super -s -c "
  from instances.sup
  | fork
    ( where az=='us-east-1a' | head 2 )
    ( where az=='us-east-1b' | head 2 )
    ( where az=='us-east-1c' | head 2 )
  | sort az, id
"
```
```mdtest-output
{id:"i-001",az:"us-east-1a"}
{id:"i-002",az:"us-east-1a"}
{id:"i-004",az:"us-east-1b"}
{id:"i-005",az:"us-east-1c"}
{id:"i-006",az:"us-east-1c"}
```

2 from `us-east-1a`, 1 from `us-east-1b` (all it had), 2 from `us-east-1c` —
as balanced as possible given the available pool.

## Why Not Just Sort and Head?

Without fork, you might try:

```mdtest-command
super -s -c "from instances.sup | sort az, id | head 5"
```
```mdtest-output
{id:"i-001",az:"us-east-1a"}
{id:"i-002",az:"us-east-1a"}
{id:"i-003",az:"us-east-1a"}
{id:"i-004",az:"us-east-1b"}
{id:"i-005",az:"us-east-1c"}
```

All 3 from `us-east-1a`, the 1 from `us-east-1b`, and only 1 from `us-east-1c`.
That's unbalanced — it fills up from the first AZ alphabetically instead of
distributing evenly.

## Verifying the Distribution

You can check the balance of your selection by piping through an aggregate:

```mdtest-command
super -s -c "
  from instances.sup
  | fork
    ( where az=='us-east-1a' | head 2 )
    ( where az=='us-east-1b' | head 2 )
    ( where az=='us-east-1c' | head 2 )
  | aggregate count:=count() by az
  | sort az
"
```
```mdtest-output
{az:"us-east-1a",count:2}
{az:"us-east-1b",count:1}
{az:"us-east-1c",count:2}
```

## Alternative: Self-Join for Row Numbering

There's a pure SQL approach that doesn't require fork and works dynamically with
any number of groups. The idea: for each record, count how many records in the
same group have an id less than or equal to it. This simulates
`ROW_NUMBER() OVER (PARTITION BY az ORDER BY id)`.

```mdtest-command
super -s -c "
  select a.id, a.az, count(*) as row_num
  from instances.sup a
  join instances.sup b on a.az = b.az and b.id <= a.id
  group by a.id, a.az
  order by a.az, a.id
"
```
```mdtest-output
{id:"i-001",az:"us-east-1a",row_num:1}
{id:"i-002",az:"us-east-1a",row_num:2}
{id:"i-003",az:"us-east-1a",row_num:3}
{id:"i-004",az:"us-east-1b",row_num:1}
{id:"i-005",az:"us-east-1c",row_num:1}
{id:"i-006",az:"us-east-1c",row_num:2}
{id:"i-007",az:"us-east-1c",row_num:3}
{id:"i-008",az:"us-east-1c",row_num:4}
```

Step by step, for record `i-006` in `us-east-1c`:

1. The self-join matches `i-006` against all `us-east-1c` records with
   `id <= 'i-006'`: that's `i-005` and `i-006` itself.
2. `count(*)` = 2, so `row_num` = 2.

Now filter to keep only the first 2 per group:

```mdtest-command
super -s -c "
  with ranked as (
    select a.id, a.az, count(*) as row_num
    from instances.sup a
    join instances.sup b on a.az = b.az and b.id <= a.id
    group by a.id, a.az
  )
  select id, az from ranked
  where row_num <= 2
  order by az, id
"
```
```mdtest-output
{id:"i-001",az:"us-east-1a"}
{id:"i-002",az:"us-east-1a"}
{id:"i-004",az:"us-east-1b"}
{id:"i-005",az:"us-east-1c"}
{id:"i-006",az:"us-east-1c"}
```

Same result as fork, but no hardcoded AZ names — works with any number of
groups dynamically.

## Trade-offs

**Fork** is simple and fast (linear scan per branch), but requires hardcoding
group values. Best when groups are known and stable (like AZs in a region).

**Self-join** is dynamic and handles any number of groups automatically, but
is O(n^2) per group since every record is joined against all peers with a
smaller key. Fine for small datasets, potentially slow for large ones.

**With window functions** ([brimdata/super#5921][issue]), the query would be
both dynamic and efficient — handling any number of groups with a single linear
pass and supporting sophisticated ranking (e.g., ordering within groups by
launch time, instance type preference, etc.).

| Approach         | Dynamic groups? | Time complexity  | Notes                                      |
|------------------|-----------------|------------------|--------------------------------------------|
| Fork             | No              | O(n) per branch  | Groups must be hardcoded                   |
| Self-join        | Yes             | O(n^2) per group | Every record joined against its group peers |
| Window functions | Yes             | O(n log n)       | Sort + single pass (not yet available)     |

For a refresher on what those mean in practice
([Big O notation](https://en.wikipedia.org/wiki/Big_O_notation)):

| Notation   | Name        | 100 records | 10,000 records | Growth        |
|------------|-------------|-------------|----------------|---------------|
| O(n)       | Linear      | 100         | 10,000         | Scales nicely |
| O(n log n) | Linearithmic| ~664        | ~132,877       | Typical sort  |
| O(n^2)     | Quadratic   | 10,000      | 100,000,000    | Gets slow fast|
