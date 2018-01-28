#!/bin/bash

export PATH="/opt/python/python-2.7/bin:${PATH}"
export PATH="${PATH}:/usr/local/sbin:/usr/local/bin"
export PLYPORT="6969"
export PLYDIR="${HOME}/downloads/github/themacks/ply"
export PLYLOG="/tmp/ply.log"

test -e ${PLYDIR} || {
  echo "no such dir ${PLYDIR}"
  exit 1
}
pushd ${PLYDIR}
test -e ply.py || {
  echo "no such file ${PWD}/ply.py"
  exit 1
}
python2.7 ply.py ${PLYPORT} 2>&1 | tee ${PLYLOG}x
