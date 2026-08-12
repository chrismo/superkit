---
title: "Plain Text Without the Bashisms"
name: plain-text
description: "Replacing sed, cut, awk, sort, uniq, and wc with a single super pipeline over plain text."
layout: default
nav_order: 13
parent: Tutorials
superdb_version: "0.3.0"
last_updated: "2026-08-10"
---

# Plain Text Without the Bashisms

`super` is usually pitched at JSON and `.sup` data, but it reads plain text
perfectly well, and once text is inside a pipeline you stop needing the usual
chain of `sed`, `cut`, `awk`, `sort`, `uniq`, and `wc`.

The argument for doing so isn't that those tools are bad. It's that a shell
pipeline throws away structure at every stage. `awk '{print $1}'` turns a
parsed line back into an unparsed one, so the next stage has to re-parse it.
Five tools means five parsers, five quoting conventions, and five chances to
mis-handle an empty field. One `super` pipeline parses once and keeps the
structure — and the types — the whole way through.

This tutorial is the counterpart to
[bash_to_sup]({% link docs/tutorials/bash_to_sup.md %}), which covers getting
text safely *into* SuperDB, and
[sup_to_bash]({% link docs/tutorials/sup_to_bash.md %}), which covers getting
values back *out*. This one is about staying inside `super` for the middle part.

## Reading and Writing Plain Text

Two flags do the work:

- **`-i line`** reads stdin one line at a time, each line arriving as a string.
- **`-f line`** writes bare values with no quotes or type decorators — the
  format the rest of your shell pipeline expects.

The difference on output matters:

```bash
super -f line -c 'values "quoted?"'
# => quoted?

super -s -c 'values "quoted?"'
# => "quoted?"
```

Use `-f line` when the result is headed for another shell command or a human.
Use `-s` when you want to see the SUP representation, including types.

## The Translation Table

Every one of these was run against SuperDB v0.3.0. The recipe functions
(`sk_field`, `sk_cut`) come from
[text.spq]({% link docs/recipes/text.md %}); load them with `-I text.spq`.

| Bash | SuperDB |
|---|---|
| `cut -d: -f1` | `values sk_cut(this, ":", 1)` |
| `awk '{print $2}'` | `values sk_field(this, 2)` |
| `awk '{print NF}'` | `values sk_nf(this)` |
| `grep foo` | `where grep("foo", this)` |
| `grep -v foo` | `where !grep("foo", this)` |
| `sed 's/world/there/'` | `values replace(this, "world", "there")` |
| `sed -E 's/[0-9]+/#/g'` | `values regexp_replace(this, "[0-9]+", "#")` |
| `tr a-z A-Z` | `values upper(this)` |
| `wc -l` | `aggregate count()` |
| `head -2` | `head 2` |
| `tail -2` | `tail 2` |
| `sort -n` | `sort cast(this, <int64>)` |
| `sort -u` | `aggregate u:=union(this) \| unnest u \| sort this` |
| `sort \| uniq -c` | `aggregate n:=count() by line:=this` |

A few worth seeing run:

```bash
printf 'root:x:0:0\ndaemon:x:1:1\n' |
  super -I text.spq -f line -i line -c 'values sk_cut(this, ":", 1)' -
# => root
# => daemon

printf '10\n2\n3\n' |
  super -f line -i line -c 'sort cast(this, <int64>)' -
# => 2
# => 3
# => 10

printf 'a\nb\na\n' |
  super -f line -i line -c '
    aggregate n:=count() by line:=this
    | sort -r n
    | values f"{n} {line}"' -
# => 2 a
# => 1 b
```

Note that `sort cast(this, <int64>)` needs no equivalent of `sort -n`'s
special-casing — once the value is an `int64`, sorting is numeric because the
type says so. That is the whole thesis in one line.

## Gotchas

These are the things that will bite you first. All confirmed against v0.3.0.

### Arrays index from 0, but awk and cut count from 1

```bash
super -s -c 'values ["a","b","c"][0]'    # => "a"
super -s -c 'values ["a","b","c"][1]'    # => "b"
super -s -c 'values ["a","b","c"][-1]'   # => "c"
super -s -c 'values ["a","b"][9]'        # => error("missing")
```

Negative indexing counts from the end, and out-of-range is an `error("missing")`
value rather than an empty string. `sk_field` and `sk_cut` exist mostly to
absorb both differences: they take the 1-based number you already know from
`awk`/`cut`, and return `""` past the end.

### split() takes a literal, not a regular expression

```bash
super -s -c 'values split("a   b", "[ ]+")'
# => ["a   b"]
```

The separator was treated as the literal text `[ ]+`, which never appears, so
nothing split. For a regex split, collapse first with `regexp_replace`:

```bash
super -s -c 'values split(regexp_replace("a   b", "\\s+", " "), " ")'
# => ["a","b"]
```

### split() does not collapse whitespace runs the way awk does

This is the same trap from the other direction, and it's the single most common
surprise when porting an `awk` one-liner:

```bash
super -s -c 'values split("a   b  c", " ")'
# => ["a","","","b","","c"]
```

`awk` gives you three fields here; `split` gives you six, four of them empty.
`sk_fields` is the awk-compatible version:

```bash
super -I text.spq -s -c "values join(sk_fields('a   b  c'), '|')"
# => "a|b|c"
```

### regexp() and regexp_replace() take their arguments in opposite orders

```bash
super -s -c 'values regexp("id=([0-9]+)", "id=4711 ok")'
# => ["id=4711","4711"]

super -s -c 'values regexp_replace("a1b2", "[0-9]", "#")'
# => "a#b#"
```

`regexp` is *pattern first*; `regexp_replace` is *input first*. `regexp` returns
an array whose element 0 is the whole match and whose later elements are the
capture groups.

Also note that a regex literal — `/[0-9]+/` — is not accepted as a function
argument in 0.3.0; both of these take the pattern as a plain string.

### grep() is a regex match, not a substring match

```bash
super -s -c 'values grep("a.c", "abc")'      # => true
super -s -c 'values grep("^b", "abc")'       # => false
super -s -c 'values grep("(?i)ABC", "abc")'  # => true
```

So `where grep(...)` behaves like `grep -E`, and `(?i)` gives you `grep -i`.

### Literal brackets in a grok pattern need a doubled backslash

Because the pattern is a SuperQL string first and a regex second, one backslash
gets consumed by the string parser:

```bash
super -S -i line -c 'values grok("\\[%{HTTPDATE:ts}\\]", this)' access.log
```

## Worked Example: Top Talkers in an Access Log

Take a Common Log Format file:

```
10.0.0.1 - - [10/Aug/2026:13:55:36 -0700] "GET /index.html HTTP/1.0" 200 2326
10.0.0.2 - - [10/Aug/2026:13:55:37 -0700] "GET /api/users HTTP/1.0" 200 15320
10.0.0.1 - - [10/Aug/2026:13:55:38 -0700] "POST /api/login HTTP/1.0" 401 128
10.0.0.3 - - [10/Aug/2026:13:55:39 -0700] "GET /index.html HTTP/1.0" 200 2326
10.0.0.1 - - [10/Aug/2026:13:55:40 -0700] "GET /missing HTTP/1.0" 404 512
10.0.0.2 - - [10/Aug/2026:13:55:41 -0700] "GET /api/users HTTP/1.0" 500 64
```

The reflex version, four processes and two sorts:

```bash
awk '{print $1}' access.log | sort | uniq -c | sort -rn | head -3
#    3 10.0.0.1
#    2 10.0.0.2
#    1 10.0.0.3
```

The same thing in one pipeline:

```bash
super -I text.spq -f line -i line -c '
  values sk_field(this, 1)
  | aggregate n:=count() by ip:=this
  | sort -r n
  | head 3
  | values f"{n} {ip}"
' access.log
# => 3 10.0.0.1
# => 2 10.0.0.2
# => 1 10.0.0.3
```

Roughly a wash — this is the case the shell is genuinely good at. Drop the final
`values f"{n} {ip}"` and switch to `-s`, though, and you get records instead of
text, which is where it stops being a wash.

## Worked Example: Where the Shell Gives Up

Now ask a question the shell can't answer with field-slicing: **per client, how
many requests, how many bytes, and how many were errors?** That needs three
fields parsed and two of them typed as numbers.

Parse the whole line once with `grok`:

```bash
super -s -i line -c '
  values grok("%{IP:ip} %{DATA} \\[%{HTTPDATE:ts}\\] \"%{WORD:method} %{URIPATHPARAM:path} %{DATA}\" %{NUMBER:status} %{NUMBER:bytes}", this)
  | put status := cast(status, <int64>), bytes := cast(bytes, <int64>)
  | aggregate
      reqs   := count(),
      bytes  := sum(bytes),
      errors := sum(status >= 400 ? 1 : 0)
    by ip
  | sort -r bytes
' access.log
```

```
{ip:"10.0.0.2",reqs:2,bytes:15384,errors:1}
{ip:"10.0.0.1",reqs:3,bytes:2966,errors:2}
{ip:"10.0.0.3",reqs:1,bytes:2326,errors:0}
```

Two details worth calling out:

- `grok` returns every captured field as a **string**, so `status` and `bytes`
  need an explicit `cast` before they can be summed or compared. Skipping the
  cast gives you lexical comparisons — `"99" > "400"` is true.
- There is no `count(where ...)` in 0.3.0. A conditional count is
  `sum(cond ? 1 : 0)`, as in `errors` above.

The output is structured, so the next step is a pipeline stage rather than
another parse. Swap `-s` for `-f json` and it feeds a web page; swap it for
`-f csv` and it feeds a spreadsheet; leave it and it feeds another `super`.

## When to Stay in Bash

This is not an argument for never typing `grep` again.

- **Interactive one-offs.** `grep ERROR app.log` is shorter than anything here
  and you are going to read the answer with your eyes.
- **Streaming huge files where you need an early exit.** `grep -m1` stops
  reading; an aggregate has to see everything.
- **When the tool already is the answer.** `wc -l` on a 40GB file is hard to beat.

The trade tips toward `super` as soon as a pipeline grows past two stages, needs
a number compared as a number, or produces output another program has to parse.
That is also the point where the shell version starts collecting `IFS`
workarounds — see [sup_to_bash]({% link docs/tutorials/sup_to_bash.md %}) for
what that road looks like.
