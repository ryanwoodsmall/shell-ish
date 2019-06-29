#!/bin/bash

whoami | grep -q '^root$' || {
  echo 'please run as root'
  exit 1
}

echo performance \
| tee /sys/devices/system/cpu/cpu?/cpufreq/scaling_governor >/dev/null 2>&1

sysctl vm.swappiness \
| grep -q ' = 1$' || sysctl vm.swappiness=1 >/dev/null 2>&1
