#!/bin/bash

#
# simple function that can output its own depth
#

set -eu

function recurs() {
  local i="${1}"
  local s="${2}"
  (( ${i} < ${s} )) && {
    echo "call: ${i}, depth: ${#FUNCNAME[@]}"
    #test $(( ${i} % 5 )) -eq 0 && special ${i}
    recurs $(( ${i} + 1 )) ${s}
  }
}

function special() {
  local i="${1}"
  echo "call: ${i} special, depth: ${#FUNCNAME[@]}"
}

if [ ${#} -ne 0 ] ; then
  if [[ ${1} =~ ^[0-9]+$ ]] ; then
    n=${1}
  else
    echo "please provide an integer argument" 1>&2
    exit 1
  fi
fi

: ${n:=10}

recurs 1 ${n}
