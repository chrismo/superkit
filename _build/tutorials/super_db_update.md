---
title: "Updating Data in a Lake"
description: "Workarounds for updating data in a SuperDB lake."
layout: default
nav_order: 9
parent: Tutorials
superdb_version: "0.1.0"
last_updated: "2026-02-15"
---

# Updating Data in a Lake
            
There are plans to eventually support this, captured in this [GitHub Issue
#4024](https://github.com/brimdata/super/issues/4024). But for now, we'll have
to fudge it.

All we can do for now are separate `delete` and `load` actions. It's safer to do
a load-then-delete, in case the delete fails, we'll at least have duplicated
data, vs. no data at all in the case of failure during a delete-then-load.

Since we have unstructured data, we can attempt to track the ...

load: {id:4,foo:1,ts:time('2025-02-18T01:00:00')}
load: {id:4,foo:2,ts:time('2025-02-18T02:00:00')}
delete: -where 'id==4 and ts < 2025-02-18T02:00:00'

if it's typed data

delete: -where 'is(<foo>) ...'

if we need to double-check duplicate data:

'count() by is(<foo>)'
