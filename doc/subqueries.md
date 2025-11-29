# Subqueries

While there are many different types of subqueries, this document so far is just
highlighting some common scenarios that may not have obvious implementations in
superdb.

## Correlated Subqueries

[//]: # (TODO: file versions - phil's versions from Slack - NOT versions - issue #54) 

Let's start with this simple dataset:

```json lines
{"id":1, "date":"2025-02-27", "foo": 3}
{"id":2, "date":"2025-02-27", "foo": 2}
{"id":3, "date":"2025-02-28", "foo": 5}
{"id":4, "date":"2025-02-28", "foo": 9}
```

And we want to select the entries with the largest `foo` for each date.

One way to do this in SQL looks like this:

```sql
select id, date, foo
from data
where (date, foo) in
      (select date, max(foo) as max_foo
       from data
       group by date);
```

Another way, by joining a derived table:

```sql
select *
from data d
       join
     (select date, max(foo) as max_foo
      from data
      group by date) max_foo
     on d.date = max_foo.date and
        d.foo = max_foo.max_foo;
```

In `zq` and `super` this can be done one way, with piped operators and a Lateral
Subquery:

```mdtest-input data.json
{"id":1, "date":"2025-02-27", "foo": 3}
{"id":2, "date":"2025-02-27", "foo": 2}
{"id":3, "date":"2025-02-28", "foo": 5}
{"id":4, "date":"2025-02-28", "foo": 9}
```

Here's an example using the piped `where` operator:
```mdtest-command
zq -z '
  collect(this)
  | {data: this}
  | maxes:=(over this.data | foo:=max(foo) by date | yield {date,foo})
  | over this.data with maxes => ( where {date,foo} in maxes )' data.json
```
```mdtest-output
{id:1,date:"2025-02-27",foo:3}
{id:4,date:"2025-02-28",foo:9}
```
                                              
And another example using the piped `join` operator:
```mdtest-command
ASDF_SUPERDB_VERSION=0.51016 super -s -c '
  collect(this)
  | unnest {data:this, item:this} into (
      values this.item
      | inner join (unnest this.data
                    | foo:=max(foo) by date
                    | values {date,foo})
        on {left.date,left.foo}={right.date,right.foo}
      | values left
    )
  | sort id' data.json
```
```mdtest-output
{id:1,date:"2025-02-27",foo:3}
{id:4,date:"2025-02-28",foo:9}
```
                                 
`super` also supports SQL syntax, and as of around 0.50918, these subqueries work:

```mdtest-command
ASDF_SUPERDB_VERSION=0.51016 super -s -c '
  select *
  from "data.json"
  where foo in (select max(foo), date
                from "data.json"
                group by date) '
```
```mdtest-output
{id:1,date:"2025-02-27",foo:3}
{id:4,date:"2025-02-28",foo:9}
```
  
If we save off the max data to a file first, then we can start to see how this
could look:
```mdtest-command
ASDF_SUPERDB_VERSION=0.51016 super -s -c '
  select max(foo) as max_foo
  from "data.json"
  group by date' > max.sup

ASDF_SUPERDB_VERSION=0.51016 super -s -c '
  select l.id, l.date, l.foo
  from "data.json" l
    join "max.sup" r
    on l.foo==r.max_foo'
```
```mdtest-output
{id:1,date:"2025-02-27",foo:3}
{id:4,date:"2025-02-28",foo:9}
```

## Subquery with Related Data Join

A more realistic scenario: find the records with the top `score` per date, and
also pull in user information from a related table.

```mdtest-input scores.json
{"id":1, "date":"2025-02-27", "score": 3, "user_id": 101}
{"id":2, "date":"2025-02-27", "score": 2, "user_id": 102}
{"id":3, "date":"2025-02-28", "score": 5, "user_id": 101}
{"id":4, "date":"2025-02-28", "score": 9, "user_id": 103}
```

```mdtest-input users.json
{"user_id": 101, "name": "Moxie"}
{"user_id": 102, "name": "Ziggy"}
{"user_id": 103, "name": "Sprocket"}
```

First, the basic join returns all records with user names:
```mdtest-command
ASDF_SUPERDB_VERSION=0.51016 super -s -c '
  select s.id, s.date, s.score, s.user_id, u.name
  from "scores.json" s
    join "users.json" u on s.user_id = u.user_id
  order by s.id'
```
```mdtest-output
{id:1,date:"2025-02-27",score:3,user_id:101,name:"Moxie"}
{id:2,date:"2025-02-27",score:2,user_id:102,name:"Ziggy"}
{id:3,date:"2025-02-28",score:5,user_id:101,name:"Moxie"}
{id:4,date:"2025-02-28",score:9,user_id:103,name:"Sprocket"}
```

Filtering to top scores per date using a subquery:
```mdtest-command
ASDF_SUPERDB_VERSION=0.51016 super -s -c '
  select *
  from "scores.json"
  where score in (select max(score), date
                  from "scores.json"
                  group by date)'
```
```mdtest-output
{id:1,date:"2025-02-27",score:3,user_id:101}
{id:4,date:"2025-02-28",score:9,user_id:103}
```

The "obvious" SQL approach with tuple comparison returns empty — this is a known
issue during SuperDB's pre-release period
([#6326](https://github.com/brimdata/super/issues/6326)):
```mdtest-command
ASDF_SUPERDB_VERSION=0.51016 super -s -c '
  select s.id, s.date, s.score, s.user_id, u.name
  from "scores.json" s
    join "users.json" u on s.user_id = u.user_id
  where (s.date, s.score) in (
    select date, max(score)
    from "scores.json"
    group by date)'
```
```mdtest-output
```

A derived table approach (subquery in FROM) does work:
```mdtest-command
ASDF_SUPERDB_VERSION=0.51016 super -s -c '
  select s.id, s.date, s.score, s.user_id, u.name
  from "scores.json" s
    join (
      select date, max(score) as max_score
      from "scores.json"
      group by date
    ) m on s.date = m.date and s.score = m.max_score
    join "users.json" u on s.user_id = u.user_id
  order by s.id'
```
```mdtest-output
{id:1,date:"2025-02-27",score:3,user_id:101,name:"Moxie"}
{id:4,date:"2025-02-28",score:9,user_id:103,name:"Sprocket"}
```

The piped approach also works — filter first, then join to get usernames:
```mdtest-command
ASDF_SUPERDB_VERSION=0.51016 super -s -c '
  from "scores.json"
  | where score in (select max(score), date from "scores.json" group by date)
  | inner join (from "users.json") on left.user_id=right.user_id
  | select left.id, left.date, left.score, right.name
  | sort id'
```
```mdtest-output
{id:1,date:"2025-02-27",score:3,name:"Moxie"}
{id:4,date:"2025-02-28",score:9,name:"Sprocket"}
```

# as of versions

```mdtest-command
ASDF_SUPERDB_VERSION=0.51016 super --version
```
```mdtest-output
Version: v0.0.0-20251016221528-bdb38bbc4fef
```
_and zq 1.18_
```mdtest-command
zq --version
```
```mdtest-output
Version: v1.18.0
```
