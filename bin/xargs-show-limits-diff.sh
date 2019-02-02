#!/bin/bash

#
# show limits differences between two versions of gnu findutils xargs
# both must be in path
#

set -eu

xargs --version 2>&1 \
| grep -q GNU

which -a xargs \
| xargs realpath \
| grep '/xargs$' \
| sort -u \
| while read -r x ; do
    ${x} --version 2>&1 \
    | grep -q GNU \
      && echo ${x} \
      || true
  done \
  | head -2 \
  | while read -r x ; do
      echo "<(echo ${x} ; echo ; echo | ${x} --show-limits 2>&1)"
    done \
    | xargs echo diff -Naur \
    | bash
