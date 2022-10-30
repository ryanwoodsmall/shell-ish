#!/usr/bin/env bash
#
# print file size in type in format:
#   ${SIZE} : ${FILENAME} : ${FILETYPE}
#
# XXX - /dev/stdin stat relies on coreutils features, no idea how to make work with busybox/toybox/ubase/...
#

set -eu

: ${file:="file"}

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

declare -A fsh fth

fnw=0
fsw=0

for n in ${!fl[@]} ; do
  f="${fl[${n}]}"
  fs=0
  ft='empty'
  if [ ! -r "${f}" ] ; then
    echo "${f}: file not found or unreadable" 1>&2
    continue
  fi
  if [[ ${f} =~ /dev/stdin ]] ; then
    tf="$( ( cat "${f}" | base64 ) 2>/dev/null )"
    ft="$( ( echo "${tf}" | base64 -d | ${file} - ) 2>/dev/null )"
    fs="$( ( stat -c %s - <<<$(echo "${tf}" | base64 -d) ) 2>/dev/null )"
  else
    ft="$(${file} "${f}")"
    if [ -d "${f}" ] ; then
      fs="$(du -ks "${f}" | awk '{print $1}')"
      fs=$((${fs}*1024))
    else
      fs="$(stat -c %s "${f}")"
    fi
  fi
  ft="${ft#*: }"
  fsh["${f}"]="${fs}"
  fth["${f}"]="${ft}"
  c="$(echo -n ${fs} | wc -c)"
  if [ ${c} -gt ${fsw} ] ; then
    fsw="${c}"
  fi
  c="$(echo -n ${f} | wc -c)"
  if [ ${c} -gt ${fnw} ] ; then
    fnw="${c}"
  fi
done

for n in ${!fl[@]} ; do
  f="${fl[${n}]}"
  test -r "${f}" &>/dev/null || continue
  printf "%-${fsw}s : %-${fnw}s : %s\\n" "${fsh[${f}]}" "${f}" "${fth[${f}]}"
done
