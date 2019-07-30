#!/bin/bash

#
# busybox/toybox/ubase lsusb only list ids
# get a usb.ids file to figure out what's what
#

test -e /tmp/usb.ids || {
  wget -P /tmp/ http://www.linux-usb.org/usb.ids
}

lsusb \
| cut -f2- -d: \
| sed 's/^ ID //g' \
| while IFS="$(printf '\n')" read -r u ; do
  i="${u%% *}"
  m="${i%:*}"
  d="${i#*:}"
  sed -n "/^${m}/,/^[0-9a-f]\{4\}  /p" /tmp/usb.ids \
  | egrep "^(${m}  |[[:blank:]]${d}  )"
done
