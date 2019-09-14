#!/usr/bin/env bash

set -eu

: ${d:="https://github.com/ryanwoodsmall/dockerfiles/raw/master/crosware/webserver/Dockerfile"}
: ${p:="80"}
: ${h:="/data/http"}
: ${n:="crosware_busybox_httpd${h//\//_}"}
: ${i:="${n}"}

docker build --tag "${i}" "${d}"
docker stop "${n}" || true
docker kill "${n}" || true
docker rm "${n}" || true
docker run \
  --detach \
  --env BUSYBOX_HTTPD_PORT="${p}" \
  --env BUSYBOX_HTTPD_HOME="${h}" \
  --name "${n}" \
  --publish "${p}:${p}" \
  --restart always \
  --volume "${h}:${h}:ro" \
    "${i}"
