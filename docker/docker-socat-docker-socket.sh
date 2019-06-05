#!/bin/bash

#
# serve up the docker socket to tcp://localhost:2375 via socat in a docker container
#

docker run \
  --name socat_docker_socket \
  --detach \
  --volume /var/run/docker.sock:/var/run/docker.sock \
  --network host \
  --privileged \
  --restart always \
    socat \
      -d -d tcp4-listen:2375,fork,reuseaddr,bind=localhost unix-connect:/var/run/docker.sock
