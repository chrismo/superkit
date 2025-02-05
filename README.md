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
              
## Prefer using functions over operators

Operators cannot be executed in places required to be expressions, so if the
contents of the op or func can work as a func, make it a func.

## Multiple Versions

Right now `super` is pre-release and the team has a lot of work ahead of them,
so `zq` is probably going to stay at 1.18 for a while. 

Separate branches seems reasonable. Working on diffs between them might be a
pain though? Maybe just research this. I could use git worktrees to help prolly.
             
## TODO

[//]: # (TODO: _ALWAYS_ a k prefix? In case of future name collisions?) 
[//]: # (TODO: Then always a k prefix on the spq files as well?)
[//]: # (TODO: docs for each func/op in superkit - how to write, how to read?)
[//]: # (TODO: docs in the doc folder - how to distribute, how to read?)

