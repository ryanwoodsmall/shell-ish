#!/bin/bash

#
# print count and provider for all *box based utils
#  b : busybox
#  s : sbase-box
#  t : toybox
#  u : ubase-box
#

declare -A uaa
for u in busybox sbase-box toybox ubase-box ; do
  p="${u:0:1}"
  a=''
  if [[ $u =~ busybox ]] ; then
    a='--list'
  fi
  if $(which ${u} >/dev/null 2>&1) ; then
    for t in $(${u} ${a}) ; do
      uaa["${t}"]+="${p}"
    done
  fi
done

for t in ${!uaa[@]} ; do
  u="${uaa[${t}]}"
  c="$(echo -n ${u} | wc -c)"
  echo "${t} : ${c} : ${u}"
done
