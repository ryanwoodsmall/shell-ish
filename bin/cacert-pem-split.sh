#!/usr/bin/env bash
#
# read a cacert.pem file and split it into individual #.crt files in the current directory
#
# initially, this was to be a moving window over the cert bundle using tail/head pairs
# this is easier imho and only requires reading the bundle pem once
#
# XXX - note: this is not a parser!!! verify with openssl etc.
# XXX - invalid combos of nested/repeated begin/end pairs will screw it up
#
set -eu

s="$(basename ${BASH_SOURCE[0]})"

declare -a lines
declare -a begincert
declare -a endcert

cert=0
width=0

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
  elif [[ "${l}" =~ "END CERT" ]] ; then
    endcert[${cert}]="${i}"
    ((cert+=1))
  fi
done

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
