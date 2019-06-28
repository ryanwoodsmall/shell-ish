#!/bin/bash

#
# this sucks
# needs to be run on an armv7 box - raspberry pi, raspbian lite
# needs extra swap for linking - i used a 4GB swap partition on a usb ssd
#

uname -m | grep -q armv7l || {
  echo "please run on armv7l..."
  exit 1
}

# checkout/update docker-ce source
mkdir -p ${HOME}/Downloads/github/docker
cd ${HOME}/Downloads/github/docker
test -e docker-ce || {
  git clone https://github.com/docker/docker-ce.git
}
cd docker-ce
git pull
git checkout -b local_v17.06.0-ce v17.06.0-ce

# ENV GOARM 7 -> ENV GOARM 6
find . -type f | \
  grep -v \\.git | \
  xargs grep -l 'GOARM.*7' 2>/dev/null | \
  xargs sed -i '/GOARM/ s/\(.*GOARM.*\)7/\1 6/g'

# armhf/debian:jessie -> resin/rpi-raspbian:jessie
find . -type f | \
  grep -v \\.git | \
  xargs grep -l 'FROM.*armhf/debian:jessie' 2>/dev/null | \
  xargs sed -i '/armhf\/debian:jessie/ s/\(.*FROM.*\)armhf\/debian:jessie/\1 resin\/rpi-raspbian:jessie/g'

# remove "seccomp" from DOCKER_BUILDTAGS
find . -type f | \
  grep -v \\.git | \
  xargs grep -l 'DOCKER_BUILDTAGS.*seccomp' 2>/dev/null | \
  xargs sed -i '/DOCKER_BUILDTAGS.*seccomp/ s/seccomp//g'

# armhf/alpine -> arm32v6/alpine
find . -type f | \
  grep -v \\.git | \
  xargs grep -l 'armhf/alpine' 2>/dev/null | \
  xargs sed -i '/armhf\/alpine/ s/armhf\/alpine/arm32v6\/alpine/g'

# only build "debian-jessie" which we're faking out with raspbian
sed -i 's/^deb:.*/deb: debian/g;s/^debian:.*/debian: debian-jessie/g' components/packaging/deb/Makefile
sed -i '/^deb:/ s/\(.*DOCKER_BUILD_PKGS:=\).*/\1debian-jessie/g' ./components/packaging/Makefile

echo "okay, now run 'make deb' and pray"
