#!/bin/bash

#
# verify contents of rpm
#
# get list of files with package with something like:
#
#  grep -B1 / /tmp/rpmverify.out
#

if [ ${UID} -ne 0 ] ; then
  echo 'please run as root' >&2
  exit 1
fi

rpm -qa | sort | while read -r p ; do
  echo $p >&2
  echo $p
  rpm -qV $p
  echo
done | tee /tmp/rpmverify.out
