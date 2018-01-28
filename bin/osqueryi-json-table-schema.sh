#!/bin/bash

#
# dump a full json schema for every table osqueryi knows about
#

which osqueryi jq >/dev/null 2>&1 || {
  echo "please make sure osqueryi and jq are installed"
  exit 1
}

index=0
if [[ ${@} =~ -i ]] ; then
  index=1
fi

ts=( $(osqueryi .tables | cut -f2- -d'>') )
li="$((${#ts[@]}-1))"

{
  echo "{"
  if [ ${index} -eq 1 ] ; then
    echo '"table_names": ['
    for ti in $(seq 0 ${li}) ; do
      tn="${ts[${ti}]}"
      echo -n "{ \"name\": \"${tn}\" }"
      test ${ti} -ne ${li} && echo -n ","
      echo
    done
    echo '], "table_schemas": [ {'
  fi
  for ti in $(seq 0 ${li}) ; do
    tn="${ts[${ti}]}"
    echo -n "\"${tn}\":"
    osqueryi --json "PRAGMA table_info(${tn});"
    test ${ti} -ne ${li} && echo ","
  done
  if [ ${index} -eq 1 ] ; then
    echo "} ]"
  fi
  echo "}"
} | jq .
