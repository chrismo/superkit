---
title: "Updating Data in a Database"
name: super-db-update
description: "Workarounds for updating data in a SuperDB database table."
layout: default
nav_order: 11
parent: Tutorials
superdb_version: "0.4.0"
last_updated: "2026-10-31"
---

# Updating Data in a Database

As of v0.4.0, a SuperDB database supports SQL `CREATE TABLE`, `INSERT INTO`,
and `DROP TABLE`, but not `UPDATE` or `DELETE` statements. (In-place updates
are tracked in [GitHub Issue #4024](https://github.com/brimdata/super/issues/4024).)
Until then, an update is a separate `load` and `delete`.

Do a **load-then-delete**: if the delete fails you're left with duplicate data,
which you can clean up. A delete-then-load that fails partway leaves you with
no data at all.

> Database _pools_ were renamed _tables_ in v0.4.0, and databases from earlier
> releases can't be opened. See the [upgrade guide](../zq-to-super-upgrades/).

## Setup

Create a database and a typed table. These examples pass `-attach` on each
command so they don't touch your global attachment. Interactively, you'd run
`super db attach ./mydb` once and leave `-attach` off.

```mdtest-command
super db init -q ./mydb
super db -attach ./mydb -s -c "
  CREATE TABLE readings (id int64 NOT NULL, foo int64, ts timestamp)
" | super -s -c 'values {kind,table:info.table,error}' -
```
```mdtest-output
{kind:"create_table",table:"readings",error:null}
```

SQL statements against a database output a status record per statement. The
example above trims it down to the stable fields.

Insert a first reading:

```mdtest-command
super db -attach ./mydb -s -c "
  INSERT INTO readings VALUES (4, 1, '2025-02-18T01:00:00Z'::timestamp)
" | super -s -c 'values {kind,values:info.values,error}' -
```
```mdtest-output
{kind:"insert",values:1::uint64,error:null}
```

## Update = load, then delete

Now `id` 4 has a new value. Load the new version first:

```mdtest-command
echo '{id:4,foo:2,ts:2025-02-18T02:00:00Z}' |
  super db load -attach ./mydb -q -use readings -
super db -attach ./mydb -s -c "from readings | sort ts"
```
```mdtest-output
{id:4,foo:1,ts:2025-02-18T01:00:00Z}
{id:4,foo:2,ts:2025-02-18T02:00:00Z}
```

Then delete the old version with `-where`, which takes a filter expression:

```mdtest-command
super db delete -attach ./mydb -q -use readings \
  -where 'id==4 and ts < 2025-02-18T02:00:00Z'
super db -attach ./mydb -s -c "from readings"
```
```mdtest-output
{id:4,foo:2,ts:2025-02-18T02:00:00Z}
```

## Typed tables reject bad data

Because `readings` has column types, every loaded value is cast to the table's
type. If any value can't be cast, nothing in that load is committed:

```mdtest-command fails
echo '{id:"oops",foo:3}' | super db load -attach ./mydb -q -use readings -
```
```mdtest-output
value {id:error({message:"cannot cast to int64",on:"oops"}),foo:3::(int64|null),ts:null::(timestamp|null)} cannot be cast to table type {id:int64,foo:int64|null,ts:timestamp|null}
```

That makes the load-then-delete pattern safer: a malformed "update" fails at
the load step, before anything is deleted.

## Checking for duplicates

If a load succeeded but the delete didn't, look for keys with more than one
value:

```mdtest-command
echo '{id:4,foo:3,ts:2025-02-18T03:00:00Z}' |
  super db load -attach ./mydb -q -use readings -
super db -attach ./mydb -s -c "
  from readings
  | count() by id
  | where count > 1"
```
```mdtest-output
{id:4,count:2}
```

## as of versions

```mdtest-command
super --version
```
```mdtest-output
Version: v0.4.0
```
