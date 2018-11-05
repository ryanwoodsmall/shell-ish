#!/usr/bin/env bash

#
# the sponge bob
#

if [ ${#} -ne 1 ] ; then
	f="/dev/stdin"
else
	f="${1}"
	if [ ! -e "${f}" ] ; then
		echo "${f} does not exist"
		exit 1
	fi
fi

# let's make this dumb
declare -A u l t
a=( {A..Z} {a..z} )

# uppercase
for c in ${!a[@]} ; do
	u["${a[${c}]}"]=$(echo ${a[${c}]} | tr '[[:lower:]]' '[[:upper:]]')
done
#lowercase
for c in ${!a[@]} ; do
	l["${a[${c}]}"]=$(echo ${a[${c}]} | tr '[[:upper:]]' '[[:lower:]]')
done
# full alphabet
for i in ${!a[@]} ; do
	t["${a[${i}]}"]=0
done

# XXX - use CRLF as a crutch here
c=0
cat "${f}" | unix2dos | tr '\n' ' ' | tr -s ' ' | while IFS= read -n1 e ; do
	# XXX - could speed up by checking if [[ ${e} =~ ^[A-Za-z]$q ]] here
	if [ ! -z "${t[${e}]}" ] ; then
		if [ ${c} -eq 0 ] ; then
			echo -n "${l[${e}]}"
			c=1
		else
			echo -n "${u[${e}]}"
			c=0
		fi
	else
		echo -n "${e}"
	fi
done \
| tr '\r' '\n' \
| sed 's/^ //g'
