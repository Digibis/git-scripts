# git-scripts
## Bash Scripts to help with multiple git repositories

### fetch.sh

Simple script that does a fetch on every repository that resides inside a
directory.

### sync_git_all.sh

This script can do a git pull over every repository that resides inside a directory.
Does a recursive search of git repositories over the directory that takes as 
argument, and does a git pull over the develop branch.

It get back to the branch where the repository was and does a git stash of any 
local changes and restores the stash when the pull process ends.
Also, launch many process to process every repository on parallel.

It would stop if finds an error when does a git fetch/pull on a repository


