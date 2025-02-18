# from

_as of super prerelease v1.18.0-284-gc810226c_

```mdtest-command
super --version
```
```mdtest-output
Version: v1.18.0-284-gc810226c
```

`super db` replaces the `zed` CLI command, and largely carries over the
existing functionality. I have run across at least one issue with it
so far.

[GitHub Issue #5660](https://github.com/brimdata/super/issues/5660)

## using `from` with a variable - super db

```mdtest-command
super db init ./test-lake
super db -lake ./test-lake create "a"
super -c "{a:1}" | super db load -lake ./test-lake -use "a" -
super db query -lake ./test-lake "from a | yield this"
```
```mdtest-output head
lake created...
```

```mdtest-command fails
super db query -lake ./test-lake "op load_pool(pool_name): (from pool_name | yield this) load_pool('a')"
```
```mdtest-output
pool_name: pool not found at line 1, column 32:
op load_pool(pool_name): (from pool_name | yield this) load_pool('a')
                               ~~~~~~~~~
```

```mdtest-command
rm -rf ./test-lake
```
```mdtest-output head
...
```

## using `from` with a variable - zed

```mdtest-command
zed init ./test-lake
zed -lake ./test-lake create "a"
super -c "{a:1}" | zed load -lake ./test-lake -use "a" -
zed query -lake ./test-lake "from a | yield this"
```
```mdtest-output head
lake created...
```

```mdtest-command
zed query -lake ./test-lake -z "op load_pool(pool_name): (from pool_name | yield this) load_pool('a')"
```
```mdtest-output
{a:1}
```

```mdtest-command
rm -rf ./test-lake
```
```mdtest-output head
...
```
