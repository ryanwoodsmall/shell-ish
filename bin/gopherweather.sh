#!/usr/bin/env bash
#
# dump weather from floodgap gopher
#
set -eu

: ${zip:="63105"}

hash lynx >/dev/null 2>&1 || {
  echo "$(basename ${BASH_SOURCE[0]}): 'lynx' not found" 1>&2
  exit 1
}

lynx -dump -dont_wrap_pre "gopher://gopher.floodgap.com:70/7/groundhog/us/zipcode?${zip}"
