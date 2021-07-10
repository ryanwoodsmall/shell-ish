#!/usr/bin/env bash
#
# print file size in type in format:
#   ${SIZE} : ${FILENAME} : ${FILETYPE}
#
# XXX - /dev/stdin stat relies on coreutils features, no idea how to make work with busybox/toybox/ubase/...
#

set -eu

prereqs=( 'awk' 'bash' 'base64' 'cat' 'du' 'echo' 'file' 'stat' )
for prereq in ${prereqs[@]} ; do
  if ! hash "${prereq}" >/dev/null 2>&1 ; then
    echo "$(basename "${BASH_SOURCE[0]}"): ${prereq} not found" 1>&2
    exit 1
  fi
done

declare -a fl
if [ ${#} -gt 0 ] ; then
  fl=("${@}")
else
  fl=(/dev/stdin)
fi

for n in ${!fl[@]} ; do
  f="${fl[${n}]}"
  fs=0
  ft='empty'
  if [ ! -r "${f}" ] ; then
    echo "${f}: file not found or unreadable" 1>&2
    continue
  fi
  if [[ ${f} =~ /dev/stdin ]] ; then
    tf="$(cat "${f}" | base64)"
    ft="$(echo "${tf}" | base64 -d | file -)"
    fs="$(stat -c %s - <<<$(echo "${tf}" | base64 -d))"
  else
    ft="$(file "${f}")"
    if [ -d "${f}" ] ; then
      fs="$(du -ks "${f}" | awk '{print $1}')"
      fs=$((${fs}*1024))
    else
      fs="$(stat -c %s "${f}")"
    fi
  fi
  ft="${ft#*: }"
  echo "${fs} : ${f} : ${ft}"
done
