#!/bin/bash

datadir="/opt/portainer/data"

test -e ${datadir} || mkdir -p ${datadir}

docker kill portainer
docker rm --force portainer
docker rmi --force portainer/portainer
docker \
  run \
  --name portainer \
  -d \
  -p 9000:9000 \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v ${datadir}:/data \
  --restart always \
  portainer/portainer
