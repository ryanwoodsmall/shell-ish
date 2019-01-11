#!/bin/bash

#
# open an unencrypted tcp listener connecting to the docker socket
#
# from unix-unix idea here:
#   https://developers.redhat.com/blog/2015/02/25/inspecting-docker-activity-with-socat/
# some other examples:
#   https://www.cyberciti.biz/faq/linux-unix-tcp-port-forwarding/
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
