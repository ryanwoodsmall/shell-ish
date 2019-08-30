#!/bin/bash

#
# simple function that can output its own depth...
# and do something special every X levels deep
#

set -eu

function recurs() {
  local i="${1}"
  local s="${2}"
  local x="${3}"
  (( ${i} <= ${s} )) && {
    echo "call: ${i}, depth: ${#FUNCNAME[@]}"
    if [ ! ${x} -eq 0 ] ; then
      test $(( ${i} % ${x} )) -eq 0 && special ${i}
    fi
    recurs $(( ${i} + 1 )) ${s} ${x}
  }
  return 0
}

function special() {
  local i="${1}"
  echo "call: ${i} special, depth: ${#FUNCNAME[@]}"
}

if [ ${#} -ne 0 ] ; then
  e=0
  if [[ ${1} =~ ^[0-9]+$ ]] ; then
    n=${1}
  else
    e=1
  fi
  if [ ${#} -gt 1 ] ; then
    if [[ ${2} =~ ^[0-9]+$ ]] ; then
      x=${2}
    else
      e=2
    fi
  fi
  if [ ! ${e} -eq 0 ] ; then
    echo "please provide an integer argument" 1>&2
    exit ${e}
  fi
fi

: ${n:=10}
: ${x:=0}

recurs 1 ${n} ${x}
