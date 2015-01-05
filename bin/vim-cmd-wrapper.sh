#!/bin/bash

VIMCMD="vmware-vim-cmd"

hash ${VIMCMD}  2>/dev/null 
if [ $? -ne 0 ] ; then
	echo "${VIMCMD} is necessary" 1>&2
	exit 1
fi

WSHAEGREPVPATTERN='^(filename|supported|license|description|author|depends|vermagic):'
DEFAULTPORT="443"

usage () {
	${VIMCMD} -h | egrep -v $WSHAEGREPVPATTERN 2>/dev/null
}

while getopts "H:O:P:U:hv" opt ; do
	case $opt in
	H)
		ESXHOST="$OPTARG"
		;;
	O)
		ESXPORT="$OPTARG"
		;;
	P)
		ESXPASS="$OPTARG"
		;;
	U)
		ESXUSER="$OPTARG"
		;;
	h)
		usage
		;;
	v)
		${VIMCMD} -v | egrep -v $WSHAEGREPVPATTERN 2>/dev/null
		;;
	esac
done

test -z $ESXPORT && ESXPORT="${DEFAULTPORT}"
test -z $ESXHOST && NOESXHOST=1 || NOESXHOST=0
test -z $ESXUSER && NOESXUSER=1 || NOESXUSER=0
test -z $ESXPASS && NOESXPASS=1 || NOESXPASS=0
if [ "$NOESXHOST" -eq 1 ] || [ "$NOESXUSER" -eq 1 ] || [ "$NOESXPASS" -eq 1 ]
then
	usage 1>&2
	exit 1
fi

ESXTHUMBPRINT=`gethttpscert.sh -h ${ESXHOST} -p ${ESXPORT} | certfingerprint.sh`

${VIMCMD} -t "${ESXTHUMBPRINT}" "${@}" | egrep -v $WSHAEGREPVPATTERN
