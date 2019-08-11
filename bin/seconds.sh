#!/usr/bin/env bash

#
# pretty print seconds
#

set -eu

n="$(basename ${BASH_SOURCE[0]})"
if [ ${#} -ne 1 ] ; then
  echo "${n}: provide one number to pretty print"
  exit 1
fi
if [ ${1} -lt 1 ] ; then
  echo "${n}: provide a positive number greater than zero"
  exit 1
fi

rem=${1}
sm=60
sh=$((${sm}*60))
sd=$((${sh}*24))
sy=$((${sd}*365))
y=0
d=0
h=0
m=0

if [ ${rem} -ge ${sy} ] ; then
  y=$((${rem}/${sy}))
  rem=$((${rem}-(${y}*${sy})))
fi
if [ ${rem} -ge ${sd} ] ; then
  d=$((${rem}/${sd}))
  rem=$((${rem}-(${d}*${sd})))
fi
if [ ${rem} -ge ${sh} ] ; then
  h=$((${rem}/${sh}))
  rem=$((${rem}-(${h}*${sh})))
fi
if [ ${rem} -ge ${sm} ] ; then
  m=$((${rem}/${sm}))
  rem=$((${rem}-(${m}*${sm})))
fi
s=${rem}

{
  for v in y d h m s ; do
    if [ ${!v} -gt 0 ] ; then
      echo "${!v}${v}"
    fi
  done
} | xargs echo
