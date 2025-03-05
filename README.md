# SuperKit

The SuperKit library is a collection of common Functions and Operators for
[SuperDB](https://superdb.org/). These will also work with the last released
version of `zq` and `zed`, version 1.18.0.
                            
SuperKit also contains additional docs and descriptive tests as a supplement to
the official documentation.

https://github.com/chrismo/superkit/issues

## Installation

To install SuperKit, run the following command:

```sh
curl -fsS https://raw.githubusercontent.com/chrismo/superkit/main/install.sh | bash
```

This will install the SuperKit shell scripts (`sk`, `skdoc`, `skgrok`) into the
XDG bin path, which is usually `~/.local/bin`, and the remaining files into the
XDG data path, which is usually `~/.local/share/superkit` if you haven't
redefined the XDG env vars. For more info, see the [XDG Base Directory
Specification](https://specifications.freedesktop.org/basedir-spec/basedir-spec-latest.html).

# Developing Superkit
   
## Repo Structure

Functions and ops can be in any number of different files, with test files
side-by-side.

The release process produces a single combined file that will be installed as a
single file to be included automatically by the `sk` script.
              
### Prefer using functions over operators

Operators cannot be executed in places required to be expressions, so if the
contents of the op or func can work as a func, make it a func.

### All custom funcs/ops start with `k`

If we didn't do this, then more commonly named ones could possibly collide with
additions made in SuperDB itself in the future. Having some without a `k` prefix
and some with would likely be confusing, and I'd rather avoid wasting time
deciding which items should get the prefix or not. It is a little aesthetically
unpleasing, but ¯\_(ツ)\_/¯

## Multiple Versions

Especially with the supplemental documentation, there are variances between
`super` and `zq`, but the goal is to encapsulate these into one set of docs,
rather than versioning SuperKit separately for `super` and `zq`. In the future
we may need to do this, but for now, we'll try to keep it simple.

## TODO

[//]: # (TODO: docs for each func/op in superkit - how to write, how to read?)
                   
### skdoc tool

parse out sk func/ops docs as comments from the func/op? and tack on the tests
to the bottom of an .md? or maybe just select ones based on comments as well ...
and then these docs can go side-by-side with the other pre-written docs.

also want to pull down the original super docs as well to have locally.

# e.g.: `skdoc grok` shows grok (sk version or original? how to distinguish)
#       `skdoc` shows all available locally
#       `skdoc funcs` lists all funcs?
#       `skdoc ops` lists all ops?
