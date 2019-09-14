#!/bin/bash

#
# download, build, and run some benchmarks
#

set -eu

reqs=( 'curl' 'make' 'gcc' )
for req in ${reqs[@]} ; do
  which ${req} >/dev/null 2>&1 || {
    echo "${req} not found"
    exit 1
  }
done

td="/tmp"
cmd="${td}/coremark-master"
cmf="${cmd}.zip"
cmu="https://github.com/eembc/coremark/archive/master.zip"

declare -A bmflags bmtimes
bmflagscommon="LFLAGS_END=\"-lpthread -static\""
bmflagsthreads="-DMULTITHREAD=$(nproc)"
bmflags['single']="${bmflagscommon}"
bmflags['multi-fork']="XCFLAGS=\"${bmflagsthreads} -DUSE_FORK\" ${bmflagscommon}"
bmflags['multi-pthread']="XCFLAGS=\"${bmflagsthreads} -DUSE_PTHREAD\" ${bmflagscommon}"
bmflags['multi-socket']="XCFLAGS=\"${bmflagsthreads} -DUSE_SOCKET\" ${bmflagscommon}"
bmprofs=( $(echo ${!bmflags[@]} | tr ' ' '\n' | sort -r) )

rm -rf "${cmf}" "${cmd}"
curl -kLso "${cmf}" "${cmu}"
unzip -q -o "${cmf}" -d "${td}"
cd "${cmd}"

for bmprof in ${bmprofs[@]} ; do
  make clean >/dev/null 2>&1
  echo -n "${bmprof}: " 1>&2
  st="$(date +%s)"
  eval make ${bmflags[${bmprof}]} > ${bmprof}-make.out 2>&1
  et="$(date +%s)"
  rt="$((${et}-${st}))s"
  echo "${rt}" 1>&2
  bmtimes["${bmprof}"]="${rt}"
  cat run1.log > ${bmprof}.out
done

for bmprof in ${bmprofs[@]} ; do
  test -e ${bmprof}.out \
  && tr -s ' ' < /tmp/coremark-master/${bmprof}.out \
     | grep '^CoreMark ' \
     | grep -v Size \
     | sed "s/^/${bmprof} : ${bmtimes[${bmprof}]} : /g"
done | sort -t: -k4 -n
