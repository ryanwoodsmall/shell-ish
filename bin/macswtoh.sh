#!/bin/sh

if [ $# -le 0 ] ; then
	echo "please provide at least one MAC in ABCD.EF01.2345 format" 1>&2
	exit 1
fi

for MAC in $@ ; do
	MAC=`echo $MAC | tr -d .`
	MAC=`echo $MAC | tr '[[:upper:]]' '[[:lower:]]'`
	echo $MAC | grep -qE '^[a-f0-9]{12}$'
	if [ $? -ne 0 ] ; then
		echo "$MAC does not appear to be a valid MAC" 1>&2
		continue
	fi
	echo $MAC | sed 's/\(..\)/\1:/g;s/:$//g'
done
