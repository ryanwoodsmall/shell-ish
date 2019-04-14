#!/bin/sh

#
# print factorial of provided number
#

set -eu

if [ ! ${#} -eq 1 ] ; then
  echo "please provide exactly one positive integer"
  exit 1
fi

num="${1}"

if ! $(echo "${num}" | grep -Eq '^[0-9]+$') ; then
  echo "${num} does not appear to be a number"
  exit 1
fi

if [ ${num} -eq 0 ] ; then
  num=1
fi

seq -s '*' "${num}" | bc
