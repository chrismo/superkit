# Subqueries

While there are many different types of subqueries, this document so far is just
highlighting some common scenarios that may not have obvious implementations in
superdb.

## Correlated Subqueries

Let's start with this simple dataset:

```json lines
{"id":1, "date":"2025-02-27", "foo": 3}
{"id":2, "date":"2025-02-27", "foo": 2}
{"id":3, "date":"2025-02-28", "foo": 5}
{"id":4, "date":"2025-02-28", "foo": 9}
```

And we want to select the entries with the largest `foo` for each date.

One way to do this in SQL looks like this:

```sqlite
select id, date, foo
from data
where (date, foo) in
      (select date, max(foo) as max_foo
       from data
       group by date);
```

Another way, by joining a derived table:

```sqlite
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
super -z -c '
  collect(this)
  | over this with data=this => (
      inner join (over data
                  | foo:=max(foo) by date
                  | max_key:={date,foo})
      on {date,foo}=max_key
    )' data.json
```
```mdtest-output
{id:1,date:"2025-02-27",foo:3}
{id:4,date:"2025-02-28",foo:9}
```
                                 
`super` also supports SQL syntax, but these subqueries aren't supported yet.
                                         
```mdtest-command fails
super -z -c '
  select * 
  from "data.json"
  where foo in (select max(foo), date
                from "data.json"
                group by date) '
```
```mdtest-output
parse error at line 4, column 24:
  where foo in (select max(foo), date
                   === ^ ===
```
  
If we save off the max data to a file first, then we can start to see how this
could look:
```mdtest-command
super -z -c 'select max(foo) as max_foo 
             from "data.json" 
             group by date' > max.jsup
             
super -z -c '
  select l.id, l.date, l.foo
  from "data.json" l
    join "max.jsup" r
    on l.foo==r.max_foo'
```                   
```mdtest-output                  
{id:1,date:"2025-02-27",foo:3}
{id:4,date:"2025-02-28",foo:9}
```

# as of versions

```mdtest-command
super --version
```
```mdtest-output
Version: v1.18.0-304-g6300fbaf
```
_and zq 1.18_
```mdtest-command
zq --version
```
```mdtest-output
Version: v1.18.0
```
