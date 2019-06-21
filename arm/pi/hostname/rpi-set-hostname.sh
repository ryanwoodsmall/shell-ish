#!/bin/bash

loopback="127.0.1.1"
nic="eth0"
hf="/etc/hosts"
hnf="/etc/hostname"

hnpref="$(xargs -0 echo < /proc/device-tree/model | tr A-Z a-z | sed 's/raspberry/r/g;s/model.*//g;s/ //g')"
mac="$(cat /sys/class/net/${nic}/address | tr -d :)"

newhostname="${hnpref}-${mac}"

sed -i "/^${loopback} /d" ${hf}
sed -i '/raspberrypi$/d' ${hf}
echo "${loopback} ${newhostname}" >> ${hf}
echo ${newhostname} > ${hnf}

hostname ${newhostname}
systemctl restart networking.service
