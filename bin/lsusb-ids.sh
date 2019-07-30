#!/bin/bash

#
# busybox/toybox/ubase lsusb only list ids
# get a usb.ids file to figure out what's what
#

test -e /tmp/usb.ids || {
  wget -P /tmp/ http://www.linux-usb.org/usb.ids
}

lsusb \
| while IFS="$(printf '\n')" read -r u ; do
  i="${u#*: ID }"
  i="${i%% *}"
  m="${i%:*}"
  d="${i#*:}"
  h="${u%%: *}"
  sed -n "/^${m}/,/^[0-9a-f]\{4\}  /p" /tmp/usb.ids \
  | egrep "^(${m}  |[[:blank:]]${d}  )" \
  | tr -d '\t' \
  | sed "s/^\(${m}\|${d}\)  //g" \
  | xargs echo "${h}: ID ${m}:${d}"
done
