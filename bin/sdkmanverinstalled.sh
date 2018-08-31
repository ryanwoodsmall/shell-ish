#!/bin/bash

of="/tmp/sdkmanlist.out"
si="${SDKMAN_DIR}/bin/sdkman-init.sh"

if [ -e ${si} ] ; then
  . ${si}
else
  echo ${si} not found
  exit 1
fi

sdk list \
| awk '/\$ sdk install /{print $NF}' \
| while read -r p ; do
    echo $p
    sdk list $p \
    | egrep -v '^(=|>|Available|\+|\*|[[:space:]]{1,}$|^$)'
    done \
| tee ${of}

echo

egrep '(^[a-zA-Z]|>|\*)' ${of} \
| egrep -B1 '(>|\*)'
