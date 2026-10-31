---
title: "Joins"
name: joins
description: "Examples of outer joins, anti joins, and full outer joins in SuperDB."
layout: default
nav_order: 6
parent: Tutorials
superdb_version: "0.4.0"
last_updated: "2026-10-31"
---

# Joins

## Outer Joins

```mdtest-input za.sup
{id:1,name:"foo",src:"za"}
{id:3,name:"qux",src:"za"}
```
```mdtest-input zb.sup
{id:1,name:"foo",src:"zb"}
{id:2,name:"bar",src:"zb"}
```

Left Join (Left Only + Inner Joins — where clause required to eliminate inner joins)

`select *` includes columns from both sides. The right table's columns get a
`_1` suffix to avoid name collisions. As of v0.4.0, unmatched columns are
`null`, following SQL semantics (earlier releases produced `error("missing")`
and needed `is_error()` in the `where` clause).
```mdtest-command
super -s -c "select * from za.sup as za
             left join zb.sup as zb
             on za.id=zb.id
             where zb.name is null"
```
```mdtest-output
{id:3,name:"qux",src:"za",id_1:null,name_1:null,src_1:null}
```

Right Join (Right Only + Inner Joins — where clause required to eliminate inner joins)
```mdtest-command
super -s -c "select * from za.sup as za
             right join zb.sup as zb
             on za.id=zb.id
             where za.name is null"
```
```mdtest-output
{id:null,name:null,src:null,id_1:2,name_1:"bar",src_1:"zb"}
```

Anti Join (Left Join exclusively — no where clause required)
```mdtest-command
super -s -c "select * from za.sup as za
             anti join zb.sup as zb
             on za.id=zb.id"
```
```mdtest-output
{id:3,name:"qux",src:"za",id_1:null,name_1:null,src_1:null}
```

Full Outer (Left Only + Right Only + Inner Joins) - _BUG: Still behaves like Left Join — only returns left-side rows_
```mdtest-command
super -s -c "select * from za.sup as za
             full outer join zb.sup as zb
             on za.id=zb.id
             where za.name is null or zb.name is null"
```
```mdtest-output
{id:3,name:"qux",src:"za",id_1:null,name_1:null,src_1:null}
```

## as of versions

```mdtest-command
super --version
```
```mdtest-output
Version: v0.4.0
```
