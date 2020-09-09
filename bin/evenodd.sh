#!/usr/bin/env bash

#
# quick even/odd flipper w/random and modulus
#

while true ; do
  i=${RANDOM}
  s=odd
  if [ $((${i}%2)) -eq 0 ] ; then
    s=even
  fi
  printf '%-4s : %d\n' "${s}" "${i}"
  sleep 1
done
