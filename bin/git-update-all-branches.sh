#!/bin/bash

ob="$(git branch -l | grep '^\*' | awk '{print $NF}')"
for b in $(git branch -l -a | awk -F/ '/remotes\/origin\//{print $NF}' | sort -u) ; do
	git checkout "${b}"
	git pull
done
git checkout "${ob}"
