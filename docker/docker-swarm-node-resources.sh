#!/usr/bin/env bash
unset nodes
i=0
cpus=0
mem=0
for n in $(docker node ls -q) ; do
  nodes[${i}]=`docker node inspect ${n} \
               | jq -r '.[]|[.Description|.Hostname,.Resources[]][],[.Spec|.Role,.Availability][]' \
               | xargs echo \
               | awk '{print \$1":"\$2/(1000**3)":"\$3/(1024**3)":"\$4":"\$5}'`
  i=$((${i}+1))
done
for i in ${!nodes[@]} ; do
  node=( $(echo "${nodes[${i}]}" | tr ':' ' ') )
  n="${node[0]}"
  c="${node[1]}"
  m="${node[2]}"
  r="${node[3]}"
  a="${node[4]}"
  cpus=$((${cpus}+${c}))
  mem="$({ echo scale=10 ; echo ${m}+${mem} ; } | bc)"
  echo "${i} ${n} ${c} ${m} ${r} ${a}"
done
echo '- - - - - -'
echo "${#nodes[@]} - ${cpus} ${mem} - -"
unset a c i m n r cpus nodes mem