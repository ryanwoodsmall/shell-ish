#!/bin/sh

if [ $# -le 0 ] ; then
  echo "Usage: $(basename ${0}) pid1# <pid2#> ... <pidN#>" 1>&2
  exit 1
fi

for i in "${@}" ; do
  for j in cmdline environ ; do
    test -e /proc/${i}/${j} && \
      cat /proc/${i}/${j} | \
        tr \\0 \\n | \
        sed s#^#${i}:/proc/${i}/${j}:#g
  done
done
