# Upgrading zq to super

_This is an agentic document tested with Claude. It is not 
100% complete, and has some opinionated sections from the
author, but covers many of the cases required as of July 2025._

We use an asdf custom plugin to manage superdb pre-releases.

Here are all the major language upgrades that need to be made.

This reflects changes as of `0.50725` according to the custom asdf
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

```zq
zq -j $input_file
```
This zq command is merely reformatting the input file to compact
(single-line) JSON. 

```super
super -c -j $input_file # illegal!!
```
This is illegal! Because there's no command string passed with the `-c`
switch. The correct transformation is:

```super
super -j $input_file # good! :) 
```

### DO NOT FORGET that -c must have the command string immediately follow it

```zq
echo "$json" | zq -f text 'yield this.KmsKeyId' -
```

Must become
```super
echo "$json" | super -f line -c 'values this.KmsKeyId' -
```

NOT THIS:
```super
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

```zq
yield [1,2,3] | over this
```

```super
values [1,2,3] | unnest this
```

### `=>` has become `into`

`over this => (...)` is now `unnest this into (...)` and should largely
be the same.
            
### `with ... =>` is more complicated

`over a with b => (...)` is now `unnest {b,a} into (...)` and will have
behavioral changes! `this` inside the parens used to be just `a` with `zq`
but now `this` inside the parens with `super` is the record `{b,a}`.  

## Formatting changes

This is just a matter of preference. I want all multi-line command
strings to go from this:
                       
```zq
zq -j 'over this
       | cut Id,Name' -
```

To this:
```super
super -j -c '
  over this
  | cut Id,Name
' -
```

The command string should have the opening quote or double-quote end the
1st line, then the command string contents should start on a new line,
just 2 space indented from the parent `super` binary.

The closing quote or double-quote should be on its own line,
left-aligned in the same column os the `super` binary at the very start.
