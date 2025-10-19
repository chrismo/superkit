# Upgrading zq to super

Oct 19, 2025 — SuperDB Version 0.51016 (pre-release) 

This is a custom pre-release version used by the community-contributed [asdf
plugin](https://github.com/chrismo/asdf-superdb).

This is an agentic document tested with Claude. It is not 100% complete, and has
some opinionated sections from the author.

Here are all the major language upgrades that need to be made.

## yield -> values

This is a very simple keyword upgrade without any behavioral changes.

Anywhere the keyword `yield` appears in a zq query, replace it with `values`.

## parse_zson -> parse_sup

Simple replacement: `parse_zson` for `parse_sup`

## comments

`zq` used `//` for single line comments. `super` now uses PostgreSQL
compatible comments. `--` for single line `/* ... */` for multi-line.

## `-c [cmd]` switch

`super` requires a `-c [cmd]` switch before the command string. `zq`
didn't require a switch, it just accepted the command string passed to
it, if one was used.

### While MOST uses of zq/super have a command string, it is NOT required.

DO NOT make the following upgrade:

```bash
zq -j $input_file
```
This zq command is merely reformatting the input file to compact
(single-line) JSON.

```bash
super -c -j $input_file # ILLEGAL!!
```
This is illegal! Because there's no command string passed with the `-c`
switch. The correct transformation is:

```bash
super -j $input_file # GOOD! :) 
```

### DO NOT FORGET that -c must have the command string immediately follow it

```bash
echo "$json" | zq -f text 'yield this.KmsKeyId' -
```

Must become
```bash
echo "$json" | super -f line -c 'values this.KmsKeyId' -
```

NOT THIS:
```bash
echo "$json" | super -c -f line 'values this.KmsKeyId' - # ILLEGAL!
```
This is illegal!

## -f text => -f line

`-f text` is no longer an option, and should just be replaced with `-f line`

## -z switch -> -s

simple replace: `-z` -> `-s` and capitalized version too: `-Z` -> `-S`

## `-c [cmd]` should be the LAST switch in the commands.

`-c [cmd]` should come last! All other switches in front of it.

## zero-based to one-based indexing

Because PostgreSQL level compatibility is a goal for the sql portions of
the SuperDB syntax, and psql uses one-based indexing for much of its
syntax, SuperDB is now one-based.

This largely shows in `[...]` slice nomenclature on strings and arrays.

Anytime you see `[0:2]` it should be changed to `[1:3]`. Or `[:2]` ->
`[:3]`. Negative indexes have NOT changed. So `[0:-1]` -> `[1:-1]`.

## over -> unnest

Simple uses of over are simple to change without behavioral change:

These are identical:

```bash
yield [1,2,3] | over this
```

```bash
values [1,2,3] | unnest this
```

### `=>` has become `into`

`over this => (...)` is now `unnest this into (...)` and should largely
be the same.

### `with ... =>` is more complicated

`over a with b => (...)` is now `unnest {b,a} into (...)` and will have
behavioral changes! `this` inside the parens used to be just `a` with `zq`
but now `this` inside the parens with `super` is the record `{b,a}`.

## grep and regexp changes

As of this change ([PR 6115](https://github.com/brimdata/super/pull/6115)) on
Aug 15, 2025:

- inline regexp (`/.../`) is no longer a supported syntax and must be strings
- globs are no longer supported in the `grep` function
- `this` is no longer implied, it must be passed in the 2nd argument.

```bash
# NO LONGER WORKS IN SUPER
echo '{"s":"alphabet"}' | zq -z "grep(/a*b/,s)" -
```

```bash
# THE CORRECT WAY TO DO IT NOW. CORRECT. GOOD.
echo '{"s":"alphabet"}' | super -s -c "grep('a.*b',s)" -
```

```bash
# THIS WAY NO LONGER WORKS IN SUPER.
zq -z "yield ['a','b'] | grep(/b/)"       
["a","b"]
```

```bash
# MISSING SECOND ARGUMENT IS BAD.
super -s -c "values ['a','b'] | grep('b')"
too few arguments at line 1, column 20:
values ['a','b'] | grep('b')
                   ~~~~~~~~~\
```

```bash
# CORRECT. GOOD.
super -s -c "values ['a','b'] | grep('b', this)"
["a","b"]
```

## Changes to implied `this` arguments

As of [5075037c](https://github.com/brimdata/super/commit/5075037c) on Aug 27,
2025:

`is` and `nest_dotted` no longer take an implied `this` as a first argument.
They now must receive `this` explicitly as their 1st argument.

This is a similar change as to `grep` above.

`shape` and `cast` also will be changed in a similar fashion SOON.

```bash
# THIS NO LONGER WORKS. BAD.
zq -z "yield 2 | is(<int64>)"
2
```

```bash
# THIS SHOWS THE ERROR WHEN INCORRECT.
super -s -c "values 2 | is(<int64>)"
too few arguments at line 1, column 12:
values 2 | is(<int64>)
~~~~~~~~~~~
```

```bash
# CORRECT. GOOD.
super -s -c "values 2 | is(this, <int64>)"
2
```

`nest_dotted` is the same.

[//]: # (TODO: NEED EXAMPLES)

## Cast changes

As of [ec1c5eee](https://github.com/brimdata/super/commit/ec1c5eee) on Aug 28, 2025:

([4e6d4921](https://github.com/brimdata/super/commit/4e6d4921) on Aug 29, 2025
includes a CAST related bug fix)

zq used to support casting with a direct "function" style syntax like this:

```bash
zq -z "{a:time('2025-08-28T12:00:00Z')}" 
```
...where `time` could be any primitive type (e.g. `string`, `int64`, `uint64`,
etc.) or custom type.

But that's no longer supported.

```bash
# BAD. INCORRECT.
super -s -c "{a:time('2025-08-28T12:00:00Z')}"      
no such function at line 1, column 4:
{a:time('2025-08-28T12:00:00Z')}
```

You have to cast by other means:

```bash
# CORRECT. GOOD. THIS IS THE PREFERRED UPGRADE METHOD.
super -s -c "{a:'2025-08-28T12:00:00Z'::time}" 
{a:2025-08-28T12:00:00Z}
```

```bash
# this is legal, but not preferred. do not use.
super -s -c "{a:cast('2025-08-28T12:00:00Z', <time>)}"
{a:2025-08-28T12:00:00Z}
```

```bash
# this is legal, but not preferred. do not use.
super -s -c "{a:CAST('2025-08-28T12:00:00Z' AS time)}"
{a:2025-08-28T12:00:00Z}
```

## User Defined Syntax Changes

### User-Defined Operators: `op` syntax change

As of [PR 6181](https://github.com/brimdata/super/pull/6181) on Sep 2, 2025:

User-defined operators now use a different syntax for both declaration and
invocation to better align with built-in operators and distinguish them from
user functions.

**OLD zq syntax:**
```bash
# Declaration with parentheses around parameters
op components(s): (
  parse_sup(s)
  | unnest json
  | values this
)

# Invocation with parentheses (function-call style)
unnest [this] | components(this)
```

**NEW super syntax:**
```bash
# Declaration WITHOUT parentheses around parameters
op components s: (
  parse_sup(s)
  | unnest json
  | values this
)

# Invocation uses 'call' keyword (or shortcut without it)
unnest [this] | call components this

# Shortcut: drop 'call' keyword (preferred)
unnest [this] | components this
```

**Key changes:**
- Declaration: `op name(arg):` → `op name arg:`
- Multiple args: `op name(a, b):` → `op name a, b:`
- No args: `op name():` → `op name:`
- Invocation: `name(arg)` → `call name arg` or just `name arg`

**Note:** The shortcut form (without `call`) cannot be used for a single
operator with no arguments inside a subquery - you must use `call` in that
case.

### User-Defined Functions: `func` → `fn`

https://github.com/brimdata/super/commit/aab15e0d

`func` is now just `fn` - a simple rename.

**OLD:**
```bash
func myfunction(x): x + 1
```

**NEW:**
```bash
fn myfunction(x): x + 1
```

## lateral subqueries that produce multiple results must be array wrapped

Starting with [this PR (6100)](https://github.com/brimdata/super/pull/6100) on
Aug 11, and finishing with [this PR
(6243)](https://github.com/brimdata/super/pull/6243) on Sep 17 to allow `[...]`
syntax in these spaces, lateral subqueries that produce multiple results must be
wrapped in an array.

Before these changes, this would work as-is:
```bash
super -s -c "[3,2,1] | { a: ( unnest this | values this ) }"

{a:[3,2,1]}
```

After these changes, this errors out:
```bash
super -s -c "[3,2,1] | { a: ( unnest this | values this ) }"

{a:error("query expression produced multiple values (consider [subquery])")}
```

But is patched just by putting the lateral subquery in an literal array:
```bash
super -s -c "[3,2,1] | { a: ( [unnest this | values this] ) }"

{a:[3,2,1]}
```

## cast related functions removed

The functions crop(), fill(), fit(), order(), and shape() have all been REMOVED.
Cast should be used in any location calling any of these functions. See the
[cast section above](#cast-changes) for details on what should be done instead
of these functions.

There's a small chance that these functions were used in a context where cast is
not appropriate, because it does too much, but it seems unlikely.

## chrismo Preferred Formatting Changes

This is just a matter of preference. I want all multi-line command
strings to go from this:

```bash
zq -j 'over this
       | cut Id,Name' -
```

To this:
```bash
super -j -c "
  over this
  | cut Id,Name
" -
```

Double-quotes should always be used, since single-quoted strings are legal
with SuperDB.

The command string should have the opening double-quote end the 1st line, then
the command string contents should start on a new line, just 2 space indented
from the parent `super` binary.

The closing double-quote should be on its own line, left-aligned in the same
column os the `super` binary at the very start.
