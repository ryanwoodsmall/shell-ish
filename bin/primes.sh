#!/bin/bash

#
# generate list of primes up to given number
#

set -e
set -u

if [[ ${#} != 1 ]] ; then
  echo "please provide a number"
  exit 1
fi

start=2
primes="${start}"

for (( i=$((${start}+1)) ; i <= ${1} ; i++ )) ; do
  test $((${i}%2)) -eq 0 && continue
  broke=0
  for p in ${primes} ; do
  test ${p} -le $((${i}/2+1)) && {
    test $((${i}%${p})) -eq 0 && {
      broke=1
      break
    }
  }
  done
  test ${broke} -eq 0 && primes+=" ${i}"
done

echo "${primes}"
