#!/bin/bash

#
# serve up the docker socket to tcp://localhost:2375 via socat in a docker container
#

socat_image="socat"
socat_name="socat_docker_socket"

docker build \
  --pull \
  --force-rm \
  --tag "${socat_image}" \
    https://github.com/ryanwoodsmall/dockerfiles/raw/master/crosware/socat/Dockerfile

docker run \
  --name "${socat_name}" \
  --detach \
  --volume /var/run/docker.sock:/var/run/docker.sock \
  --network host \
  --privileged \
  --restart always \
    "${socat_image}" \
      -d -d tcp4-listen:2375,fork,reuseaddr,bind=localhost unix-connect:/var/run/docker.sock
