#!/bin/bash

#
# EBG13: Qbrf jung vg fnlf ba gur gva.
#
# below is equivalent to:
#   tr 'N-ZA-Mn-za-m' 'A-Za-z'
#

set -e
set -u
declare -A r
l=({a..z})
u=({A..Z})
e=${#l[@]}
for n in ${!l[@]} ; do
  p=$(($n+13))
  test $p -ge $e && p=$(($p-$e))
  r[${l[$n]}]=${l[$p]}
  r[${u[$n]}]=${u[$p]}
done
while read -r l ; do
  for ((n=0 ; n<${#l} ; n++)) ; do
    i=${l:$n:1}
    if [[ $i =~ [a-zA-Z] ]] ; then
      i=${r[$i]}
    fi
    echo -n "$i"
  done
  echo
done