#!/usr/bin/env bash
#
# given an element and (optional) delimiter (default ' ')
# return a shortened version of the input
# order should remain the same
# blank entries (i.e., lines matching ^$ when delimiter is converted to newline) are trimmed
#

set -eu
set -o pipefail

sn="$(basename ${BASH_SOURCE[0]%.bash})"

function uniqueify() {
  if [ ${#} -lt 1 ] ; then
    echo -n
    return
  fi
  local d=" "
  local e
  local n
  local i="${1}"
  declare -a ia oa
  declare -A u
  if [ ${#} -ge 2 ] ; then
    d="${2}"
  fi
  if ! $(echo "${i}" | grep -q "${d}") ; then
    echo "${i}"
    return
  fi
  readarray -t ia < <(echo "${i}" | tr "${d}" "\n" | grep -v '^$')
  #for n in ${!ia[@]} ; do echo "in: ${n} : ${ia[${n}]}" 1>&2 ; done
  for n in ${!ia[@]} ; do
    u["${ia[${n}]}"]=0
  done
  for n in ${!ia[@]} ; do
    if [ "${u[${ia[${n}]}]}" -eq 0 ] ; then
      oa+=( "${ia[${n}]}" )
    fi
    u["${ia[${n}]}"]=$((${u[${ia[${n}]}]}+1))
  done
  #for n in ${!oa[@]} ; do echo "out: ${n} : ${oa[${n}]}" 1>&2 ; done
  for n in ${!oa[@]} ; do
    echo "${oa[${n}]}"
  done | paste -s -d "${d}" -
}

: ${testscript:=0}
if [ ${testscript} -eq 1 ] ; then
  d=''
  # no args
  echo "${sn}: nothing"
  uniqueify
  # zero/one arg
  i=''
  echo "${sn}: input: '${i}'" ; o="$(uniqueify "${i}")" ; echo "${sn}: output: '${o}'"
  i='a'
  echo "${sn}: input: '${i}'" ; o="$(uniqueify "${i}")" ; echo "${sn}: output: '${o}'"
  # two unique args, default delimiter
  i='a b'
  echo "${sn}: input: '${i}'" ; o="$(uniqueify "${i}")" ; echo "${sn}: output: '${o}'"
  # two duplicate args, default delimiter
  i='a a'
  echo "${sn}: input: '${i}'" ; o="$(uniqueify "${i}")" ; echo "${sn}: output: '${o}'"
  # three duplicate args, wrong delimiter
  i='a a a'
  d=':'
  echo "${sn}: input: '${i}' , delimeter: '${d}'" ; o="$(uniqueify "${i}" "${d}")" ; echo "${sn}: output: '${o}'"
  # three duplicate args, delimiter
  i='a:a:a'
  d=':'
  echo "${sn}: input: '${i}' , delimeter: '${d}'" ; o="$(uniqueify "${i}" "${d}")" ; echo "${sn}: output: '${o}'"
  # many args, lots of dupes
  i='a:a:a b:b:b c:c:c'
  d=':'
  echo "${sn}: input: '${i}' , delimeter: '${d}'" ; o="$(uniqueify "${i}" "${d}")" ; echo "${sn}: output: '${o}'"
  # leading, ending delims
  i=':a:b:c:a:d:b:e:c:a:f:d:q:'
  d=':'
  echo "${sn}: input: '${i}' , delimeter: '${d}'" ; o="$(uniqueify "${i}" "${d}")" ; echo "${sn}: output: '${o}'"
  # mixed numbers, letters, dupes
  i='a 1 b 2 c 3 d 4 d 3 c 2 b 1 a 0 1 2 3 4 5 6 7 8 9 a b c d e f g'
  d=' '
  echo "${sn}: input: '${i}' , delimeter: '${d}'" ; o="$(uniqueify "${i}" "${d}")" ; echo "${sn}: output: '${o}'"
  # real examples
  # LDFLAGS
  i='-static -L/path/to/lib -L/path/to/lib2 -L/path/to/lib -L/path/to/lib3 -static'
  d=' '
  echo "${sn}: input: '${i}' , delimeter: '${d}'" ; o="$(uniqueify "${i}" "${d}")" ; echo "${sn}: output: '${o}'"
  # PKG_CONFIG_{LIBDIR,PATH}
  i=':::/path/to/lib/pkgconfig:/path/to/lib2/pkgconfig:/path/to/lib/pkgconfig:/path/to/lib3/pkgconfig/path/to/lib2/pkgconfig:::/path/to/lib4/pkgconfig:::'
  d=':'
  echo "${sn}: input: '${i}' , delimeter: '${d}'" ; o="$(uniqueify "${i}" "${d}")" ; echo "${sn}: output: '${o}'"
fi
