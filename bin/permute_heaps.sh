#!/bin/bash

#
# shitty implementation of heap's algorithm
#
#   https://en.wikipedia.org/wiki/Heap%27s_algorithm
#   http://www.cs.princeton.edu/~rs/talks/perms.pdf
#

# XXX - tables... ugh, not used
#wl=( the best thing since sliced bread )
#wl=( a b c d )
#wc=${#wl[@]}
#li=$(( ${wc} - 1 ))
#fac=1
#for f in $(eval echo {1..${wc}}) ; do
#	(( fac *= f ))
#done

# XXX - debugging
function dumper() {
	local i="${1}"
	shift
	local c=("${@}")
	local cc="${#c[@]}"
	echo -n "i=${i} : "
	#echo -n "cc=${cc} : "
	for e in $(seq 0 $((${cc}-1))) ; do
		echo -n "c[${e}]=${c[${e}]} "
	done | xargs echo
}

function generate() {
	local c
	local n="${1}"
	shift
	local a=("${@}")
	echo "${a[@]}"
	for (( i=0 ; i < ${n} ; i=$((${i}+1)) )) ; do
		c[${i}]=0
	done
	i=0
	while $(test ${i} -lt ${n}) ; do
		#dumper "${i}" "${c[@]}" | sed s/^/b:/g 1>&2
		if [ ${c[${i}]} -lt ${i} ] ; then
			s="${a[${i}]}"
			if [ $((${i}%2)) -eq 0 ] ; then
				f="${a[0]}"
				a[0]="${s}"
				a[${i}]="${f}"
			else
				f="${a[${c[${i}]}]}"
				a[${c[${i}]}]="${s}"
				a[${i}]="${f}"
				
			fi
			echo "${a[@]}"
			c[${i}]="$((${c[${i}]}+1))"
			i=0
		else
			c[${i}]=0
			i=$((${i}+1))
		fi
		#dumper "${i}" "${c[@]}" | sed s/^/e:/g 1>&2
	done
}

if [ $# -lt 2 ] ; then
	echo "please provide at least 2 words"
	exit
fi

generate "${#@}" "${@}" | tr -s ' ' | sed 's/^ //g'
