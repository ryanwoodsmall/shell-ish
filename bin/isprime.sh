#!/bin/bash

#
# use sieve of eratosthenes to figure if a number is prime
#

if [ ${#} -ne 1 ] ; then
  echo "please provide exactly one number"
  exit
fi

n=${1}
h=$(((${n}+1)/2))
ps=( $(eratosthenes.sh ${h}) )
prime=1

for p in ${ps[@]} ; do
  if [ $((${n}%${p})) -eq 0 ] ; then
    prime=0
    break
  fi
done

if [ ${prime} -eq 1 ] ; then
  echo "${n} is prime"
  exit 0
else
  echo "${n} is not prime"
  exit 1
fi
