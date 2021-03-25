#!/usr/bin/env bash

#
# show the current working directories of any of your own real $SHELL processes 
#

set | grep -q ^BASH_VERSION= || {
  echo "this doesn't appear to be bash"
  exit 1
}

# default to $SHELL or bash for the program/process name
if [ ! -z "${SHELL}" ] ; then
: ${procname:=$(basename ${SHELL})}
else
: ${procname:=bash}
fi

if [ $(pgrep -x ${procname} | grep -v "^${$}$" | wc -l) -le 0 ] ; then
  echo "no (other) ${procname} processes"
  exit 1
fi

for p in $(pgrep -x ${procname}) ; do
  if [[ $(stat -c '%u' /proc/${p}/) == ${UID} ]] ; then
    if [ -r /proc/${p}/exe ] ; then
      if [[ $(realpath /proc/${p}/exe | xargs basename) =~ ^${procname}$ ]] ; then
        realpath /proc/${p}/cwd 2>/dev/null
      fi
    fi
  fi
done | sort -u
