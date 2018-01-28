#!/bin/bash

for i in $(find /tmp/hosts/ -type f -exec basename {} \; | sort) ; do
  ssh -t $i 'sudo virsh dumpxml rhel7-dcos-$(hostname -s)' | \
    xmllint --xpath '/domain/devices/interface[1]/mac/@address' - | \
    awk -F\" '{print $2}'
done | while read mac ; do
  arp -an | \
    grep -i $mac | \
    sed 's/\((\|)\)//g' | \
    awk '{print $2}'
done | \
  sort -n
