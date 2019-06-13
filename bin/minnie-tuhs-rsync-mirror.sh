#!/bin/bash

set -eu

td="$(cd $(dirname ${BASH_SOURCE[0]}) && pwd)"
md="${td}/minnie-rsync"
test -e "${md}" || mkdir -p "${md}"

mto="minnie.tuhs.org"
rpre="UA_"
declare -A rsrcdests
rsrcdests["Root"]='.'
for rsrcdest in Applications Distributions Documentation Tools ; do
  rsrcdests["${rsrcdest}"]="${rsrcdest}"
done

pushd "${md}"
for r in ${!rsrcdests[@]} ; do
  mkdir -p "${rsrcdests[${r}]}"
  rsync -avz "${mto}::${rpre}${r}" "${rsrcdests[${r}]}" | sed "s/^/${r}: /g"
done
popd
echo
