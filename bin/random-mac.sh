#!/bin/bash

for i in $(seq 0 1 5) ; do
	hexd=$(echo "16o ${RANDOM} 256 % p" | dc | tr '[[:lower:]]' '[[:upper:]]')
	echo -n ${hexd} | wc -c | grep -q ^1$ && hexd="0${hexd}"
	echo ${hexd}
done | xargs echo | tr ' ' ':'
