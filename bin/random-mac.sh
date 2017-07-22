#!/bin/bash

#
# lsb of first octet must be 0 (even) to indicate unicast
# second lsb should be 1 to indicate locally administered MAC
#
# see:
#  https://en.wikipedia.org/wiki/MAC_address#Unicast_vs._multicast
#

{
  echo 02
  for i in {2..6} ; do
    octet=$((${RANDOM}%256))
    printf "%2x\n" ${octet} | \
      tr ' ' '0'
  done
} | \
  xargs echo | \
  tr ' ' ':'
