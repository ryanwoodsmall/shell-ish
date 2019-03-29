#!/bin/bash

#
# quick and dirty "compare all files in two directories" thing
# gnu diff can do this with "diff --brief --recursive d1/ d2/"
# we sort of mimic its output
#
# XXX - does *not* handle spaces in names, oy
#

set -eu

if [ "${#}" -ne 2 ] ; then
  echo "please provide exactly two directories"
  exit 1
fi

d1="${1}"
d2="${2}"

for d in "${d1}" "${d2}" ; do
  if [ ! -e "${d}" ] ; then
    echo "directory ${d} does not exist"
    exit 1
  fi
done

d1files=( "$(cd "${d1}" ; find . -type f -o -type l | sort | sed 's#^\./##g')" )
d2files=( "$(cd "${d2}" ; find . -type f -o -type l | sort | sed 's#^\./##g')" )

declare -A d1cont d2cont

for file in ${d1files[@]} ${d2files[@]} ; do
  d1cont["${file}"]=""
  d2cont["${file}"]=""
done

for d1file in ${d1files[@]} ; do
  d1cont["${d1file}"]="1"
done
for d2file in ${d2files[@]} ; do
  d2cont["${d2file}"]="1"
done

for file in $(echo ${d1files[@]} ${d2files[@]} | tr ' ' '\n' | sort -u) ; do
  if [ -z "${d2cont[${file}]}" ] ; then
    echo "Only in ${d1}: ${file}"
    continue
  elif [ -z "${d1cont[${file}]}" ] ; then
    echo "Only in ${d2}: ${file}"
    continue
  fi
  if ! $(cmp -s "${d1}/${file}" "${d2}/${file}" >/dev/null 2>&1) ; then
    echo "Files ${d1}/${file} and ${d2}/${file} differ"
  fi
done | tr -s '/'
