#!/bin/bash

whoami | grep -q root || {
  echo "please run as root"
  exit 1
}

#
# common
#

# ssh file in boot
# gpu_mem=16 in config.txt

# package stuff
test -e /root/pkglist.initial || dpkg -l > /root/pkglist.initial
apt-get purge -y bash-completion
apt-get purge -y dphys-swapfile
apt-get autoremove -y
apt-get update
apt-get install -y bc bridge-utils dc screen vim-nox
#apt-get dist-upgrade -y

# zram
zramdeburl="https://mirrors.edge.kernel.org/ubuntu/pool/universe/z/zram-config/zram-config_0.5_all.deb"
zramdebfile="$(basename ${zramdeburl})"
curl -kLo /tmp/${zramdebfile} ${zramdeburl}
dpkg -i /tmp/${zramdebfile}
systemctl enable zram-config.service
systemctl start zram-config.service

#
# raspberry pi 2 or 3
#

# bridge setup
# XXX - make this an array - usb0..#
grep -q usb0 /etc/network/interfaces || {
  cp /etc/network/interfaces{,.ORIG}
  cat >/tmp/br0.conf<<-EOF

allow-hotplug usb0
allow-hotplug usb1
allow-hotplug usb2
allow-hotplug usb3

auto br0
iface br0 inet dhcp
          bridge_ports eth0 usb0 usb1 usb2 usb3
          bridge_fd 0
          bridge_maxwait 0

EOF
  cat /tmp/br0.conf >> /etc/network/interfaces
}
systemctl restart networking.service

# clusterhat control
curl -kLs https://raw.githubusercontent.com/burtyb/clusterhat-image/master/files/sbin/clusterhat > /sbin/clusterhat
chmod 755 /sbin/clusterhat
grep -q clusterhat /etc/rc.local ||{
  cp /etc/rc.local{,.ORIG}
  sed -i '/^exit 0/d' /etc/rc.local
  echo "/sbin/clusterhat on" >> /etc/rc.local
  echo >> /etc/rc.local
  echo "exit 0" >> /etc/rc.local
}
