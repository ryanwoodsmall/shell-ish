#!/bin/bash

#
# sieve of eratosthenes, adapted from
#  http://primes.utm.edu/glossary/page.php?sort=SieveOfEratosthenes
#

# Eratosthenes(n) {
#   a[1] := 0
#   for i := 2 to n do a[i] := 1
#   p := 2
#   while p^2  <  n do {
#     j := p^2
#     while (j  <  n) do {
#       a[j] := 0
#       j := j+p
#     }
#     repeat p := p+1 until a[p] = 1
#   }
#   return(a)
# }

if [ ${#} -ne 1 ] ; then
  echo "please provide exactly one number"
  exit
fi

n="${1}"
test ${n} -lt 0 && n=$((${n}*-1))

declare -a a
a[0]=0
a[1]=0

p=2

test ${n} -lt ${p} && exit

for i in $(eval echo {${p}..${n}}) ; do
  a[${i}]=1
done

while [ $((${p}**2)) -le ${n} ] ; do
  j=$((${p}**2))
  while [ ${j} -le ${n} ] ; do
    a[${j}]=0
    j=$((${j}+${p}))
  done
  p=$((${p}+1))
  until [ ${a[${p}]} -eq 1 ] ; do
    p=$((${p}+1))
  done
done

for i in $(eval echo {0..${n}}) ; do
    test ${a[${i}]} -eq 1 && echo -n "${i} "
done | xargs echo
