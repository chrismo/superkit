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

Left Join
```mdtest-command
super -s -c "select * from za.sup as za
             left join zb.sup as zb
             on za.id=zb.id
             where is_error(zb.name)"
```
```mdtest-output
{id:3,name:"qux",src:"za"}
```

Right Join
```mdtest-command
super -s -c "select * from za.sup as za
             right join zb.sup as zb
             on za.id=zb.id
             where is_error(za.name)"
```
```mdtest-output
{id:2,name:"bar",src:"zb"}
```

Anti Join
```mdtest-command
super -s -c "select * from za.sup as za
             anti join zb.sup as zb
             on za.id=zb.id
             where is_error(za.name) or is_error(zb.name)"
```
As of ASDF_SUPERDB_VERSION=0.50930 - but fixed in 0.51016
```mdtest-output
parse error at line 2, column 13:
            anti join zb.sup as zb
        === ^ ===
```

Full Outer - BUG - Left Only
```mdtest-command
super -s -c "select * from za.sup as za
             full outer join zb.sup as zb
             on za.id=zb.id
             where is_error(za.name) or is_error(zb.name)"
```
```mdtest-output
{id:3,name:"qux",src:"za"}
```
