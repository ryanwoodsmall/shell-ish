#!/usr/bin/env bash

# XXX - need to verify detached HEAD, etc.
# exit early/often
#set -eu

# XXX - can't do this from a subdir
#if [ ! -e ./.git/ ] ; then
#  echo "no .git directory found"
#  exit 1
#fi

# current branch
ob="$(git branch -l | grep '^\*' | awk '{print $NF}')"
# list of remotes we can strip
remotes=( $(git remote -v | awk '{print $1}' | sort -u) )
# list of all branches
branches=( $(git branch -la | awk '{print $NF}') )
# associative array to indicate unique branch names
declare -A ub

# clean up old/non-existent remotes
git fetch -p

# loop through *all* branches
for i in ${!branches[@]} ; do
  # rip off remote/.../
  for r in ${remotes[@]} ; do
    branches[${i}]="${branches[${i}]#remotes/${r}/}"
  done
  # rip off origin/
  if [[ ${branches[${i}]} =~ origin/ ]] ; then
    branches[${i}]="${branches[${i}]#origin/}"
  fi
  # indicate unique branch name with a key
  ub["${branches[${i}]}"]=1
done

# checkout and pull each unique branch
for b in ${!ub[@]} ; do
  git checkout "${b}"
  git pull
done

# switch back to original branch
git checkout "${ob}"
