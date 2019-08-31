#!/bin/bash

#
# detect loops in function calls that can't be recursive
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
