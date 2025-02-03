# SuperKit

The SuperKit library is a collection of common Operators and Functions for the
`zq`, `zed`, and `super` tools. `zq`/`zed` were renamed to SuperDB after version
1.18 of `zq`/`zed`.
                            
It also contains additional docs and descriptive tests as a supplement to the
official documentation.

https://github.com/chrismo/superkit/issues
   
## Repo Structure

Ops and functions can be in any number of different files, with test files
side-by-side.

The release process will produce a single combined file that will be installed
into the home directory of the user executing the install.sh script.

## Multiple Versions

Right now `super` is pre-release and the team has a lot of work ahead of them,
so `zq` is probably going to stay at 1.18 for a while. 

Separate branches seems reasonable. Working on diffs between them might be a
pain though? Maybe just research this. I could use git worktrees to help prolly.
             
## TODO

[//]: # (TODO: _ALWAYS_ a k prefix? In case of future name collisions?) 
[//]: # (TODO: Then always a k prefix on the spq files as well?) 
