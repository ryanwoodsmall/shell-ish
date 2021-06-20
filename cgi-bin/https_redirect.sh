#!/usr/bin/env sh
#
# redirect a request to the same thing under https at :oport
# can be used as index.cgi under e.g. an otherwise empty root to force all requests
#
# XXX - check port/header, don't redirect traffic twice?
# XXX - SERVER_NAME?
# XXX - is REQUEST_URI safe here, need to insert / between https://host:port and URI?
# XXX - `date` -R is busybox/coreutils only, format is like "Sun, 20 Jun 2021 08:28:51 -0500"
# XXX - busybox httpd header date looks like "Sun, 20 Jun 2021 13:32:26 GMT"
# XXX - 301 (permanent) or 302 (temporary)? 302 seems safer
#

set -eu

: ${iport:=18080}
: ${oport:=18443}
: ${HTTP_HOST:=""}
: ${HTTPS:="off"}
: ${REQUEST_SCHEME:="http"}
: ${SERVER_PORT:=${iport}}

d="$(date -R)"
h="$(echo ${HTTP_HOST} | cut -f1 -d:)"
test -z "${h}" && h="$(hostname)" || true

printf 'HTTP/1.1 302 Found\r\n'
printf 'Date: %s\r\n' "${d}"
printf 'Connection: close\r\n'
printf 'Content-type: text/html\r\n'
printf 'Location: https://%s:%s%s\r\n' "${h}" "${oport}" "${REQUEST_URI}"
printf '\r\n'
