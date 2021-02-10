#!/usr/bin/env bash
#
# ubuntu on raspberry pi 2/3/4
# tested with ubuntu 20 lts
# tested on a pi3, 64-bit
# default user/pass: ubuntu/ubuntu
#
# XXX - additional user
# XXX - ssh keys
# XXX - hostname
#

sudo dpkg -l | sudo tee ~root/pkglist.initial
sudo snap remove lxd
sudo snap remove core18
sudo snap remove snapd
sudo apt-get update
sudo apt-get purge -y unattended-upgrades
sudo apt-get purge -y bash-completion
sudo apt-get purge -y command-not-found
sudo apt-get purge -y apport
sudo apt-get purge -y apport-symptoms
sudo apt-get purge -y snapd
sudo apt-get purge -y apparmor
sudo apt-get purge -y sosreport
sudo apt-get autoremove -y

sudo groupadd -r docker
sudo groupadd -r wheel
sudo usermod -a -G docker ubuntu
sudo usermod -a -G wheel ubuntu

echo '%wheel ALL=(ALL:ALL) NOPASSWD: ALL' | sudo tee /etc/sudoers.d/wheel
sudo chmod 600 /etc/sudoers.d/wheel

sudo mkdir -p /etc/docker
cat >/tmp/docker_daemon.json<<EOF
{
  "experimental": true,
  "storage-driver": "vfs"
}
EOF
cat /tmp/docker_daemon.json | sudo tee /etc/docker/daemon.json
rm -f /tmp/docker_daemon.json

curl -kLs https://get.docker.com/ | sudo env CHANNEL=stable bash
sudo systemctl enable docker
sudo systemctl restart docker

sudo apt-get update
sudo apt-get dist-upgrade -y
sudo apt full-upgrade -y
sudo apt-get autoremove -y
sync
