#!/usr/bin/env bash
#
# read a cacert.pem file and split it into individual #.crt files in the current directory
#
# initially, this was to be a moving window over the cert bundle using head/tail pairs
# this is easier imho and only requires reading the bundle pem once
#
# XXX - note: this is not a parser!!! verify with openssl etc.
# XXX - invalid combos of nested/repeated begin/end pairs will screw it up
# XXX - tighten up BEGIN/END =~ matchers - line should start and end with "-"
#
set -eu

s="$(basename ${BASH_SOURCE[0]})"

declare -a lines
declare -a begincert
declare -a endcert

cert=0
width=1
beginfound=0

if [ ${#} -le 0 ] ; then
  f="/dev/stdin"
else
  f="${1}"
fi

readarray -t lines < "${f}"

for i in ${!lines[@]} ; do
  l="${lines[${i}]}"
  if [[ "${l}" =~ "BEGIN CERT" ]] ; then
    begincert[${cert}]="${i}"
    if [ ${beginfound} -ne 0 ] ; then
      echo "${s}: nested BEGIN statements around line ${i}?" 1>&2
      exit 2
    fi
    beginfound=1
  elif [[ "${l}" =~ "END CERT" ]] ; then
    endcert[${cert}]="${i}"
    ((cert+=1))
    if [ ${beginfound} -ne 1 ] ; then
      echo "${s}: END without BEGIN around line ${i}?" 1>&2
      exit 2
    fi
    beginfound=0
  fi
done

if [ ${cert} -le 0 ] ; then
  echo "${s}: no cert BEGIN/END pairs found" 1>&2
  exit 1
fi

echo "${s}: found ${cert} BEGIN/ENDs in ${f}" 1>&2
width="$(echo -n ${cert} | wc -c)"
printfpattern="%0${width}d"

for cert in ${!endcert[@]} ; do
  certfile="$(printf "${printfpattern}" ${cert}).crt"
  echo "${s}: ${cert} : ${begincert[${cert}]} ${endcert[${cert}]} : ${certfile}" 1>&2
  for i in $(seq ${begincert[${cert}]} ${endcert[${cert}]}) ; do
    echo "${lines[${i}]}"
  done > "${certfile}"
done
