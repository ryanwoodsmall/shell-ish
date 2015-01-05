#!/bin/bash

WSHAEGREPVPATTERN='^(filename|supported|license|description|author|depends|vermagic):'
DEFAULTPORT="443"

usage () {
	vmware-vim-cmd -h | egrep -v $WSHAEGREPVPATTERN 2>/dev/null
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
		vmware-vim-cmd -v | egrep -v $WSHAEGREPVPATTERN 2>/dev/null
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

