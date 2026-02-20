---
title: "Joins"
description: "Examples of outer joins, anti joins, and full outer joins in SuperDB."
layout: default
nav_order: 5
parent: Tutorials
superdb_version: "0.1.0"
last_updated: "2026-02-15"
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

Note: In 0.1.0, `select *` now includes columns from both sides. The right table's
columns get a `_1` suffix to avoid name collisions, and unmatched values are
`error("missing")`.
```mdtest-command
super -s -c "select * from za.sup as za
             left join zb.sup as zb
             on za.id=zb.id
             where is_error(zb.name)"
```
```mdtest-output
{id:3,name:"qux",src:"za",id_1:error("missing"),name_1:error("missing"),src_1:error("missing")}
```

Right Join (Right Only + Inner Joins — where clause required to eliminate inner joins)
```mdtest-command
super -s -c "select * from za.sup as za
             right join zb.sup as zb
             on za.id=zb.id
             where is_error(za.name)"
```
```mdtest-output
{id:error("missing"),name:error("missing"),src:error("missing"),id_1:2,name_1:"bar",src_1:"zb"}
```

Anti Join (Left Join exclusively — no where clause required)
```mdtest-command
super -s -c "select * from za.sup as za
             anti join zb.sup as zb
             on za.id=zb.id"
```
```mdtest-output
{id:3,name:"qux",src:"za",id_1:error("missing"),name_1:error("missing"),src_1:error("missing")}
```

Full Outer (Left Only + Right Only + Inner Joins) - _BUG: Still behaves like Left Join — only returns left-side rows_
```mdtest-command
super -s -c "select * from za.sup as za
             full outer join zb.sup as zb
             on za.id=zb.id
             where is_error(za.name) or is_error(zb.name)"
```
```mdtest-output
{id:3,name:"qux",src:"za",id_1:error("missing"),name_1:error("missing"),src_1:error("missing")}
```

## as of versions

```mdtest-command
super --version
```
```mdtest-output
Version: v0.1.0
```
