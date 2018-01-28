#!/bin/bash

#
# use sieve of eratosthenes to figure if a number is prime
#

if [ ${#} -ne 1 -o ${1} -eq 0 ] ; then
  echo "please provide exactly one number that is not 0"
  exit 1
fi

prime=1
n=${1}
test ${n} -lt 0 && n=$((${n}*-1))
test ${n} -lt 2 && prime=0
h=$(((${n}+1)/2))
ps=( $(eratosthenes.sh ${h}) )

for p in ${ps[@]} ; do
  if [ $((${n}%${p})) -eq 0 -a ${n} -ne 2 ] ; then
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
