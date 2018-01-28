#!/bin/bash

wl=()
wf=""
wc=""
uw=1

function usage() {
	cat <<-EOF
	$(basename "${BASH_SOURCE[0]}"): -c # -f /path/to/wordfile [-u]
	  -c # : number of words to randomize (i.e., 10)
	  -f /path/to/wordfile : word source file (i.e., /tmp/words.txt)
	  -u : unique words/lines
	EOF
	exit 1
}

while getopts :f:c:u opt ; do
	case ${opt} in
		c)
			wc="${OPTARG}"
			;;
		f)
			wf="${OPTARG}"
			;;
		u)
			uw=0
			;;
		\?)
			usage
			;;
	esac
done

if [[ ${wc} =~ ^$ || ${wf} =~ ^$ || ! ${wc} =~ ^[0-9]+$ || ! -e ${wf} ]] ; then
	usage
fi

while read rl ; do
	if [[ ${rl} =~ ^$ || ${rl} =~ ^# ]] ; then
		continue
	fi
	wl=("${wl[@]}" "${rl}")
done < ${wf}

for i in $(seq 1 "${wc}") ; do
	wp="$((${RANDOM}%${#wl[@]}))"
	if [[ ${wl[${wp}]} =~ ^$ ]] ; then
		continue
	fi
	echo -n "${wl[${wp}]} "
	if [[ ${uw} == 0 ]] ; then
		wl[${wp}]=""
	fi
done | sed 's/ $//g'

echo
