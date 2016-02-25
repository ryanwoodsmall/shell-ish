#!/bin/bash

nvars="0"
nvals="0"

function usage {
  echo "Usage: $(basename "${0}") -r #vars -l #possiblevals"
}

while getopts ":r:l:" opt ; do
  case $opt in
    l)
      nvals="${OPTARG}"
      ;;
    r)
      nvars="${OPTARG}"
      ;;
    \?)
      usage
      exit 0
      ;;
  esac
done

if [[ ${nvals} -eq 0 || ${nvars} -eq 0 || ! ${nvals} =~ ^[0-9]+$ || ! ${nvars} =~ ^[0-9]+$ ]] ; then
  usage
  exit 1
fi

ind=""

{ for r in $(seq -w 1 ${nvars}) ; do
    echo "${ind}for l${r} in \$(seq -w 0 $((${nvals}-1))) ; do "
    ind+=" "
  done

  echo -n "${ind}echo "
  for r in $(seq -w 1 ${nvars}) ; do
    echo -n "\${l${r}}"
  done
  echo
  ind=${ind/ /}

  for r in $(seq -w 1 ${nvars}) ; do
    echo "${ind}done"
    ind=${ind/ /}
  done
} | bash
