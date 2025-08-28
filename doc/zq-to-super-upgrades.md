# Upgrading zq to super

_This is an agentic document tested with Claude. It is not 
100% complete, and has some opinionated sections from the
author, but covers many of the cases required as of Aug 2025._

We use an asdf custom plugin to manage superdb pre-releases.

Here are all the major language upgrades that need to be made.

This reflects changes as of `0.50815` according to the custom asdf
superdb plugin we use for pre-releases.

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
super -c -j $input_file # illegal!!
```
This is illegal! Because there's no command string passed with the `-c`
switch. The correct transformation is:

```bash
super -j $input_file # good! :) 
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
echo "$json" | super -c -f line 'values this.KmsKeyId' - # illegal!
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
                                   
As of [5075037c](https://github.com/brimdata/super/commit/5075037c) on Aug 27, 2025:

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
