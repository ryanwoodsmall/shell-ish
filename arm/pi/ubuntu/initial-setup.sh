#!/usr/bin/env bash
#
# ubuntu on raspberry pi 2/3/4
# tested with ubuntu 20 lts
# tested on pi3 & pi4, both aarch64
# default user/pass: ubuntu/ubuntu
#
# XXX - additional user
# XXX - ssh keys
# XXX - hostname
# XXX - poe fan control
#       https://www.raspberrypi.org/forums/viewtopic.php?t=230603
#       https://jjj.blog/2020/02/raspberry-pi-poe-hat-fan-control/
#       https://www.raspberrypi.org/forums/viewtopic.php?t=276805
# XXX - make every step idempotent/checkable...
# XXX - include in cloud-init?
#

# exec > >(tee -a /tmp/initial-setup.out) 2>&1

sudo systemctl stop unattended-upgrades.service
sudo systemctl stop snapd.service

sudo dpkg -l | sudo tee ~root/pkglist.initial

sudo dpkg --remove unattended-upgrades
sudo dpkg --remove snapd
sudo dpkg --purge unattended-upgrades
sudo dpkg --purge snapd
#sudo snap remove --purge lxd
#sudo snap remove --purge core18
#sudo snap remove --purge snapd

rm -f /etc/localtime
ln -sf /usr/share/zoneinfo/Etc/UTC /etc/localtime
echo Etc/UTC > /etc/timezone

sudo cat /boot/firmware/usercfg.txt | sudo tee /boot/firmware/usercfg.txt.ORIG
cat >/tmp/usercfg.txt<<EOF
dtoverlay=rpi-poe
dtparam=poe_fan_temp0=60000
dtparam=poe_fan_temp1=65000
dtparam=poe_fan_temp2=70000
dtparam=poe_fan_temp3=75000
EOF
cat /tmp/usercfg.txt | sudo tee -a /boot/firmware/usercfg.txt

sudo apt-get update
sudo apt-get purge -y unattended-upgrades
sudo apt-get purge -y bash-completion
sudo apt-get purge -y command-not-found
sudo apt-get purge -y apport
sudo apt-get purge -y apport-symptoms
sudo apt-get purge -y snapd
sudo apt-get purge -y apparmor
sudo apt-get purge -y sosreport
sudo apt-get purge -y motd-news-config
sudo apt-get autoremove -y

sudo apt-get update
sudo apt-get dist-upgrade -y
sudo apt full-upgrade -y
sudo apt-get autoremove -y
sudo apt-get install -y ethtool
sudo apt-get install -y iperf3
sudo apt-get install -y net-tools
sudo apt-get install -y screen
sudo apt-get install -y tmux
sudo apt-get install -y vim-nox
sudo apt-get install -y qemu-user-static
sudo apt-get install -y binfmt-support
sudo apt-get install -y network-manager
sync

sudo systemctl enable binfmt-support.service
sudo systemctl start binfmt-support.service

sudo systemctl stop motd-news.timer
sudo systemctl disable motd-news.timer

sudo sed -i.ORIG 's/ENABLED=1/ENABLED=0/g' $(sudo realpath /etc/default/motd-news)
sudo sed -i.ORIG '/motd\.dynamic/s/^/#/g' $(sudo realpath /etc/pam.d/login /etc/pam.d/sshd)

sudo groupadd -r docker
sudo groupadd -r wheel
sudo usermod -a -G docker ubuntu
sudo usermod -a -G wheel ubuntu

echo '%wheel ALL=(ALL:ALL) NOPASSWD: ALL' | sudo tee /etc/sudoers.d/wheel
sudo chmod 600 /etc/sudoers.d/wheel

sudo mkdir -p /etc/docker
cat >/tmp/docker_daemon.json<<EOF
{
  "experimental": true
}
EOF
cat /tmp/docker_daemon.json | sudo tee /etc/docker/daemon.json
rm -f /tmp/docker_daemon.json

curl -kLs https://get.docker.com/ | sudo env CHANNEL=stable bash
sudo systemctl enable docker
sudo systemctl restart docker

sudo sed -i.ORIG '/set bell-style none/ s/#//g' /etc/inputrc

netplan generate
sudo mv /etc/netplan/50-cloud-init.yaml{,.OFF}
cat >/tmp/99-network-manager.yaml<<EOF
network:
  version: 2
  renderer: NetworkManager
EOF
cat /tmp/99-network-manager.yaml | sudo tee /etc/netplan/99-network-manager.yaml
netplan generate
netplan apply

sudo systemctl disable systemd-resolved.service
sudo systemctl stop systemd-resolved
sudo rm -f /etc/resolv.conf
sudo cp /etc/NetworkManager/NetworkManager.conf{,.ORIG}
grep -q 'dns=default' /etc/NetworkManager/NetworkManager.conf || sudo sed -i '/\[main\]/a dns=default' /etc/NetworkManager/NetworkManager.conf
sudo systemctl restart NetworkManager
