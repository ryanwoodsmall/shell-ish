#!/usr/bin/env bash
set -e
set -u
set -o pipefail

: ${debug:=0}

function sep() {
  echo "${@}" 1>&2
}

function dbp() {
  if [ "${debug}" -eq 0 ] ; then
    return
  fi
  sep "${@}"
}

declare a=()
a=( a b c d )
dbp "a : ${a[@]}"
t="$(declare -p a | cut -f2- -d=)"
dbp "t : ${t}"
declare -a b=()
dbp "b : ${b[@]}"
eval "b=${t}"
dbp "b : ${b[@]}"
b=()
dbp "b : ${b[@]}"

function testargs() {
  dbp "testargs : ${#} : ${@}"
  if [ ${#} -lt 1 ] ; then
    dbp "no args"
    return
  fi
  declare -a r=()
  for i in $(seq 0 $((${#}-1))) ; do
    t="${1}"
    r[${i}]="${t}"
    shift
    dbp "  i : ${i} : ${t}"
  done
  s="$(declare -p r | cut -f2- -d=)"
  dbp "  s : ${s}"
  echo "${s}"
}

# tests
testargs
testargs a
testargs a b
testargs 0 a b 1

# copy
testargs a b c d e f g
c=""
dbp "c : ${c}"
c="$(testargs a b c d e f g)"
dbp "c : ${c}"

# reconstitute
declare -a r=()
dbp "r : ${r[@]}"
eval "r=${c}"
dbp "r : ${r[@]}"
testargs ${r[@]}
