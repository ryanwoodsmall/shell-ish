#!/bin/bash

#
# detect loops in function calls that can't be recursive
# this currently checks that a function is calling itself and exits when a loop is detected
# required functions are run in a loop and loops are detected only if the current req matches the function name
# a more generalized form would check the stack before doing anything
#
# crosware uses something similar to detect recursive dependencies:
#   https://github.com/ryanwoodsmall/crosware/blob/a9ad7c9044b2ee08c301f6f8175bdbdbc9db6660/bin/crosware#L1237-L1276
#   https://github.com/ryanwoodsmall/crosware/blob/a9ad7c9044b2ee08c301f6f8175bdbdbc9db6660/recipes/common.sh#L117-L128
#

set -eu

fs=( {a..d} )

declare -A reqs
reqs[a]='b'
reqs[b]='c d'
reqs[c]='d'
reqs[d]=''

for f in ${fs[@]} ; do
  eval "
    function ${f}() {
      echo \${FUNCNAME}, depth: \${#FUNCNAME[@]}, stack: \${FUNCNAME[@]}
      for req in \${reqs[${f}]} ; do
        if ! \$(echo \${FUNCNAME[@]} | tr ' ' '\\n' | tail -\$(expr \${#FUNCNAME[@]} - 1) | grep -q \"^\${FUNCNAME}\") ; then
          \${req}
        else
          echo loop detected
          exit 1
        fi
      done
    }
  "
done

function runner() {
  for f in ${fs[@]} ; do
    ${f}
  done
  echo
}

function echoreqs() {
  for req in ${!reqs[@]} ; do
    echo ${req}: ${reqs[${req}]}
  done | sort
}

echo these should all run successfully
echoreqs
runner

echo these should fail
reqs[d]=a
echoreqs
runner
