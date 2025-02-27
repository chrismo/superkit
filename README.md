# SuperKit

The SuperKit library is a collection of common Functions and Operators for the
`zq`, `zed`, and `super` tools. `zq`/`zed` were renamed to SuperDB after version
1.18 of `zq`/`zed`.
                            
It also contains additional docs and descriptive tests as a supplement to the
official documentation.

https://github.com/chrismo/superkit/issues
   
## Repo Structure

Functions and ops can be in any number of different files, with test files
side-by-side.

The release process will produce a single combined file that will be installed
into the home directory of the user executing the install.sh script.
              
### Prefer using functions over operators

Operators cannot be executed in places required to be expressions, so if the
contents of the op or func can work as a func, make it a func.

### All custom funcs/ops start with `k`

More commonly named ones could possibly collide with enhancements in super in
the future. Having some without a `k` prefix and some with would likely be
confusing, and possibly too much time spent deciding what would be more likely
to be common or not.

## Multiple Versions

Right now `super` is pre-release and the team has a lot of work ahead of them,
so `zq` is probably going to stay at 1.18 for a while. 

Separate branches seems reasonable. Working on diffs between them might be a
pain though? Maybe just research this. I could use git worktrees to help prolly.

Another option would be to just tag things. 
             
## TODO

[//]: # (TODO: docs for each func/op in superkit - how to write, how to read?)
                   
skdoc tool

parse out docs as comments from the func/op - and tack on the tests to the
bottom of an .md - or maybe just select ones based on comments as well ... and
then these docs can go side-by-side with the other pre-written docs. of course
using super to do all of this.

could also potentially host the original super docs as well.

Gotta figure out install location for skdoc, all the docs

# e.g.: `skdoc grok` shows grok (sk version or original? how to distinguish)
#       `skdoc` shows all available locally
#       `skdoc funcs` lists all funcs?
#       `skdoc ops` lists all ops?

[//]: # (TODO: docs in the doc folder - how to distribute, how to read?)

`glow` is a nice reader ... we could offer to install that, but maybe just go
with default pager. all the markdown should be generally readable as text.

[//]: # (TODO: skgrok patterns tool that helps you fzf all defined grok patterns - see issues )

rather than parsing the source file, better to write a test or some code that
can dump out all the patterns in a manner we'd like.
