#!/bin/bash

#
# use jo and jq to generate some json system info
#  https://github.com/jpmens/jo
#  https://github.com/stedolan/jq
#

jsonprogs=( 'lscpu' 'cat /proc/meminfo' )
jsonprogsnum="${#jsonprogs[@]}"

{
  echo '{'
  for i in ${!jsonprogs[@]} ; do
    echo -n '  "'"${jsonprogs[${i}]}"'": '
    ${jsonprogs[${i}]} \
    | tr -s ' '  \
    | sed 's/: /=/g' \
    | jo -p
    if [ ${i} -lt $((${jsonprogsnum}-1)) ] ; then
      echo -n ','
    fi
    echo
  done
  echo '}'
} | jq -r . 
