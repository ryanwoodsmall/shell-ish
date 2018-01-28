#!/bin/bash

for i in {1..100} ; do
  mod3=$((${i}%3))
  mod5=$((${i}%5))
  if [[ ${mod3} != 0 && ${mod5} != 0 ]] ; then
    echo ${i}
    continue
  fi
  if [[ ${mod3} == 0 ]] ; then
    echo -n Fizz
  fi
  if [[ ${mod5} == 0 ]] ; then
    echo -n Buzz
  fi
  echo
done
