#!/bin/bash

# /etc/dhcp/dhclient.d/set_hostname.sh

TS="$(date '+%Y%m%d%H%M%S')"
# XXX - this will break if an IP is not configured and/or DNS is not available
IPADDR="$(ifconfig ${interface} | grep inet\  | awk '{gsub(/:/," ");print $3}')"
FQDN="$(host ${IPADDR} | awk '{gsub(/\.$/,"");print $NF}')"
SHORTNAME="${FQDN%%.*}"

set_hostname_common() {
  hostname "${SHORTNAME}"
}

set_hostname_restore() {
  set_hostname_common
}

set_hostname_config() {
  set_hostname_common
}
