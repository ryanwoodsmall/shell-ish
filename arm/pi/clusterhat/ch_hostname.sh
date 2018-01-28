#!/bin/bash

#
# drop this in /etc/rc.local to set the clusterhat pi hostname to something with its mac
#

loopback="127.1.1.1"
# generic rpi#-AABBCCDDEEFF:
#   hnpref="$(xargs -0 echo < /proc/device-tree/model | tr A-Z a-z | sed 's/raspberry/r/g;s/model.*//g;s/ //g')"
hnpref="chpi"
nic="eth0"
# stretch, jessie will need something like
#   ifconfig ${nic} | awk '/HWaddr/{print $NF}'
mac="$(ifconfig ${nic} | awk '/ether /{print $2}')"
hf="/etc/hosts"
newhostname="${hnpref}-${mac//:/}"
sed -i "/^${loopback} /d" ${hf}
echo "${loopback} ${newhostname}" >> ${hf}
hostname ${newhostname}
systemctl restart networking.service
