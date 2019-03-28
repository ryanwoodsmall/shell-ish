#!/bin/bash

#
# quick and dirty "compare all files in two directories" thing
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

d1files=( "$(cd "${d1}" ; find . -type f | sort | sed 's#^\./##g')" )
d2files=( "$(cd "${d2}" ; find . -type f | sort | sed 's#^\./##g')" )

declare -A d1sha256 d2sha256

for file in ${d1files[@]} ${d2files[@]} ; do
  d1sha256["${file}"]=""
  d2sha256["${file}"]=""
done

for d1file in ${d1files[@]} ; do
  d1sha256["${d1file}"]="$(sha256sum "${d1}/${d1file}" | awk '{print $1}')"
done
for d2file in ${d2files[@]} ; do
  d2sha256["${d2file}"]="$(sha256sum "${d2}/${d2file}" | awk '{print $1}')"
done

for d1file in ${d1files[@]} ; do
  if [ -z "${d2sha256[${d1file}]}" ] ; then
    echo "${d2}/${d1file}: no such file or directory"
    continue
  fi
  if [ "${d1sha256[${d1file}]}" != "${d2sha256[${d1file}]}" ] ; then
    echo "${d1}/${d1file}: differs from ${d2}/${d1file}"
  fi
done | tr -s '/'

for d2file in ${d2files[@]} ; do
  if [ -z "${d1sha256[${d2file}]}" ] ; then
    echo "${d1}/${d2file}: no such file or directory"
    continue
  fi
  if [ "${d2sha256[${d2file}]}" != "${d1sha256[${d2file}]}" ] ; then
    echo "${d2}/${d2file}: differs from ${d1}/${d2file}"
  fi
done | tr -s '/'
