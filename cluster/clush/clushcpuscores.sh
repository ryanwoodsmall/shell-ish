#!/bin/bash

#
# get cpu scores from cpubenchmark.net for all clush hosts
#

CL="/tmp/cpulist.out"
CBL="/tmp/cpubenchmarkcpulist.html"
CBU="https://www.cpubenchmark.net"
XO="--html --format -"

clush -N -L -w $(nodeset -f < /opt/tmp/c7.hosts) lscpu \
| awk -F: '/Model name:/{print $NF}' \
| tr -s ' ' \
| sed 's/\((\(R\|TM\))\|\(@\|with Radeon\).*\| CPU\|^ \)//g' \
| tr -s ' ' \
| tr ' ' '+' \
| sed 's/\+$//g' \
| sort -u >${CL}

curl -kLs ${CBU}/cpu_list.php | xmllint ${XO} >${CBL} 2>/dev/null

declare -A cu
declare -A ci
declare -A cr
declare -A ct

for i in $(cat ${CL}) ; do
  cu["${i}"]="${CBU}/$(grep "cpu_lookup.*${i}" ${CBL} \
                       | head -1 \
                       | cut -f2 -d\" \
                       | sed 's/cpu_lookup/cpu/g' \
                       | sed 's/amp;//g')"
  ci["${i}"]="${cu["${i}"]##*=}"
done

for i in $(cat ${CL}) ; do
  # might not have the cpu...
  if [ "${ci[${i}]}" == "${CBU}/" ] ; then
    continue
  fi
  # single thread
  curl -kLs "${CBU}/cpu.php?id=${ci[${i}]}" \
  | xmllint ${XO} 2>/dev/null \
  | awk '/\[threadRating\]/{print $NF}' | cut -f1 -d. | sed "s/\$/: ${i} (single thread)/g;s/+/ /g"
  # full rating
  curl -kLs "${CBU}/cpu.php?id=${ci[${i}]}" \
  | xmllint ${XO} 2>/dev/null \
  | awk '/\[rating\]/{print $NF}' | sed "s/\$/: ${i}/g;s/+/ /g"
  echo
done
