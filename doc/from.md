# from

**NOTE:** As of SuperDB 0.1.0, the expression-based `from` approach documented
below no longer works — `from` with dynamic expressions is a parse error. This
doc is preserved for historical reference until a replacement mechanism is
available.

The `super db` subcommand replaces the `zed` CLI command that accompanied `zq`
through version 1.18.

The `from` operator in `zed` was used to direct a query to a Pool in a Data
Lake.

In `super db`, it's been changed to incorporate all the functionality previously
contained in the `get` and `file` operators, which were specific to a URI and a
file respectively. (`get` and `file` will continue to work with `super db` but
are just synonyms for `from`).

But in order to accommodate that change, a breaking change has been introduced
in cases where the data source passed to the operator is an expression. It must
be evaluated. (When this change was [first
introduced](https://github.com/brimdata/super/pull/5378), square brackets were
required to make things work, but was later [changed to an `eval`
function](https://github.com/brimdata/super/commit/935f9460ce9f08812376ffc1302207e08bfe4800))

## using `from` with an expression - super db

Let's setup a temporary local lake to work with:
```mdtest-command
super db init ./test-lake
super db -lake ./test-lake create "a"
super -c "{a:1}" | super db load -lake ./test-lake -use "a" -
super db query -s -lake ./test-lake "from a | values this"
```
```mdtest-output head
lake created...
```

And now run this `super db query` against it, with a user-defined op that takes
the pool name as a parameter.
```mdtest-command fails
super db query -s -lake ./test-lake "op load_pool pool_name: (from pool_name | values this) load_pool('a')"
```
This produces this error:
```mdtest-output
pool_name: pool not found at line 1, column 32:
op load_pool pool_name: (from pool_name | values this) load_pool('a')
                               ~~~~~~~~~
```

If it's a field reference, it also won't work as-is, though the error is
different:
```mdtest-command fails
super db query -s -lake ./test-lake "{name:'a'} | from this.name | values this"
```
This produces this error:
```mdtest-output
from operator cannot have parent unless from argument is an expression at line 1, column 19:
{name:'a'} | from this.name | values this
                  ~~~~~~~~~
```

But wrapped in `eval`, all is well:
```mdtest-command 
super db query -s -lake ./test-lake "op load_pool pool_name: (from eval(pool_name) | values this) load_pool('a')"
```
```mdtest-output
{a:1}
```

...but the field reference version doesn't work...
```mdtest-command fails 
super db query -s -lake ./test-lake "{name:'a'} | from eval(this.name) | values this"
```
```mdtest-output
a: cannot open in a data lake environment
```

(and then let's clean up after ourselves):
```mdtest-command
rm -rf ./test-lake
```
```mdtest-output head
...
```

## using `from` with an expression - zed
                                          
With zq/zed 1.18, this wasn't a problem. Same setup:
```mdtest-command
zed init ./test-lake
zed -lake ./test-lake create "a"
super -c "{a:1}" | zed load -lake ./test-lake -use "a" -
zed query -lake ./test-lake "from a | values this"
```
```mdtest-output head
lake created...
```
                                                    
Same query passing pool name to a user-defined op:
```mdtest-command
zed query -lake ./test-lake -z "op load_pool pool_name: (from pool_name | values this) load_pool('a')"
```
```mdtest-output
{a:1}
```

But this didn't work then with a field reference either:
```mdtest-command fails
zed query -lake ./test-lake -z "{name:'a'} | from this.name | values this"
```
```mdtest-output
this.name: pool not found at line 1, column 19:
{name:'a'} | from this.name | values this
                  ~~~~~~~~~
```

_clean-up:_
```mdtest-command
rm -rf ./test-lake
```
```mdtest-output head
...
```

## notes

[GitHub Issue #5660](https://github.com/brimdata/super/issues/5660)

## as of versions

```mdtest-command
super --version
```
```mdtest-output
Version: v0.1.0
```
