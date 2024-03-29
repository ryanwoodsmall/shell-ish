#!/bin/bash

#
# use wttr.in for weather
#
#  github:
#   https://github.com/chubin/wttr.in
#  help:
#   curl -kLs 'http://wttr.in/:help?lang=en'
#

# default to st. louis, mo, usa because i live in st. louis
# auto detection finds st. louis... senegal
# 'stl' is lambert airport, also works
: ${wttrinloc:='Saint Louis, United States of America'}
if [ ${#} -ne 0 ] ; then
  wttrinloc="${1}"
fi

# en.wttr.in ~= wttr.in/...?lang=en
curl -kLs "https://en.wttr.in/${wttrinloc// /%20}" \
| egrep -v '^(New|Follow|$)'
