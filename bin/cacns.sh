#!/bin/bash

#
# rip apart cert begin/end pairs from a ca-certificates file and dump their text
#

if [ ${#} -ne 1 ] ; then
  echo "please provide the path to one ca certificate bundle file"
  exit 1
fi

cacf="${1}"

egrep -n -- '^-----(BEGIN|END) (TRUSTED |)CERTIFICATE-----$' ${cacf} | nl -w1 -s: | cut -f1-2 -d: | while read -r cpn ; do
  cln=${cpn/*:/}
  cpln=${cpn/:*/}
  if [[ $((${cpln}%2)) != 0 ]] ; then
    lcln=${cln}
    lcpln=${cpln}
  else
    head -${cln} ${cacf} | tail -$((${cln}-${lcln}+1)) | openssl x509 -noout -text
  fi
done
