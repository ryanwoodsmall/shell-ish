#!/usr/bin/env bash

: ${c:="crosware_busybox_httpd_data_http"}
: ${d:="/data/http"}
: ${i:="ryanwoodsmall/crosware:latest"}
: ${p:="80"}

docker pull "${i}"
docker stop "${c}"
docker kill "${c}"
docker rm "${c}"
docker run \
  -d \
  --name "${c}" \
  --restart always \
  -v "${d}:${d}:ro" \
  -p "${p}:${p}" \
    "${i}" \
      busybox httpd -f -vv -h "${d}" -p "${p}"
