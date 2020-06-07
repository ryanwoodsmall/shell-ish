#!/bin/bash

whoami | grep -qi '^root$' || {
  echo 'please run as root'
  exit 1
}

cd /root
# dpkg-query -f '${binary:Package}\n' -W | cut -f1 -d:
dpkg > /root/pkglist.initial
apt-get purge -y \
  bash-completion \
  unattended-upgrades \
  apparmor \
  apparmor-easyprof \
  apparmor-easyprof-ubuntu \
  click-apparmor \
  libapparmor-perl \
  python3-apparmor \
  python3-apparmor-click \
  python3-libapparmor
apt-get autoremove -y
apt-get update
apt-get --allow-releaseinfo-change update
apt-get install -y \
  gcc \
  g++ \
  make \
  git \
  git-core \
  git-man \
  screen \
  aptitude \
  ntp \
  ntpdate \
  vim-nox \
  dc \
  bc \
  bind9-host \
  flex \
  bison \
  byacc \
  nfs-client \
  build-essential \
  upstart \
  pkg-config
# pi
apt-get purge -y dphys-swapfile
echo 'LANG=en_US.UTF-8' > /etc/default/locale
export LANG="en_US.UTF-8"
sed -i 's/^en_GB/# en_GB/g' /etc/locale.gen
sed -i '/^# en_US.UTF-8/ s/^# //g' /etc/locale.gen
sed -i 's/^# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/g' /etc/locale.gen
locale-gen
update-locale
echo 'Etc/UTC' > /etc/timezone
rm -f /etc/localtime
ln -sf /usr/share/zoneinfo/Etc/UTC /etc/localtime
cp /etc/rc.local /etc/rc.local.ORIG
sed -i '/^exit/d' /etc/rc.local
sed -i '/^scaling_governor/d' /etc/rc.local
echo 'echo performance | tee /sys/devices/system/cpu/cpu?/cpufreq/scaling_governor' | tee -a /etc/rc.local
echo 'exit 0' | tee -a /etc/rc.local
systemctl enable multi-user.target
systemctl set-default multi-user.target
systemctl enable ntp.service
systemctl enable rpcbind.service
grep -q '^wheel:' /etc/group || groupadd -r wheel
echo '%wheel ALL=(ALL) NOPASSWD: ALL' | tee /etc/sudoers.d/wheel
cat >/etc/network/interfaces.d/eth0<<EOF
auto eth0
iface eth0 inet dhcp
EOF
