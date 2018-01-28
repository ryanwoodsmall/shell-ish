#!/bin/sh

{ grep -i "model name" /proc/cpuinfo | \
    sort -u | \
    cut -f2 -d:
  echo ,
  lscpu | \
    grep -i cache | \
    xargs echo
  echo ,
  grep -i ^bogomips /proc/cpuinfo | \
    cut -f2 -d: | \
    xargs echo | \
    tr \  + | \
    bc | \
    sed "s/^/bogomips: /g"
} | xargs echo
