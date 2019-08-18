#!/bin/bash

set -eu

exs=( 'one' 'two' 'three' )
funcs=( '1' '2' '3' )

for ex in ${exs[@]} ; do
  for func in ${funcs[@]} ; do
    eval "
    function ${ex}${func}() {
      echo \${FUNCNAME}: ${ex} ${func}
    }
    "
  done
  eval "
    function ${ex}exp() {
      echo \${FUNCNAME}
      for ex in ${exs[@]} ; do
        for func in ${funcs[@]} ; do
          \${ex}\${func}
        done
      done
    }
  "
done
#set
for ex in ${exs[@]} ; do
  echo ${ex}
  ${ex}exp
done
