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
if [ ${#} -eq 0 ] ; then
  loc='Saint Louis, United States of America'
else
  loc="${1}"
fi

# en.wttr.in ~= wttr.in/...?lang=en
curl -kLs "http://en.wttr.in/${loc}" \
| egrep -v '^(New|Follow|$)'
