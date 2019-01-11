#!/bin/bash

#
# open an unencrypted tcp listener connecting to the docker socket
#
# XXX - can be made secure using openssl-listen: and proper cert setup!
#

set -eu

: ${socat_port:="2375"}
: ${socat_socketL:="/var/run/docker.sock"}

socat \
  -v \
  -d -d \
  tcp4-listen:${socat_port},fork,reuseaddr \
  unix-connect:/var/run/docker.sock
