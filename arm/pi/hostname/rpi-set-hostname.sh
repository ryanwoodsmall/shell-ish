#!/bin/bash

loopback="127.0.1.1"
nic="eth0"
hf="/etc/hosts"
hnf="/etc/hostname"
needrestart=0

hnpref="$(xargs -0 echo < /proc/device-tree/model | tr A-Z a-z | sed 's/raspberry/r/g;s/model.*//g;s/ //g')"
mac="$(cat /sys/class/net/${nic}/address | tr -d :)"

defaulthostname="raspberrypi"
newhostname="${hnpref}-${mac}"

if ! $(grep -q "^${newhostname}$" ${hnf}) ; then
  needrestart=1
fi

sed -i "/^${loopback} /d" ${hf}
sed -i "/${newhostname}$/d" ${hf}
sed -i "/^127.*${defaulthostname}$/d" ${hf}
echo "${loopback} ${newhostname}" >> ${hf}
echo ${newhostname} > ${hnf}

if [ ${needrestart} -eq 1 ] ; then
  hostname ${newhostname}
  systemctl restart networking.service
fi
