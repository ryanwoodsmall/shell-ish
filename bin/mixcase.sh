#!/usr/bin/env bash

#
# the sponge bob
#

if [ ${#} -ne 1 ] ; then
	echo "please provide a file"
	exit 1
fi

f="${1}"
if [ ! -e "${f}" ] ; then
	echo "${f} does not exist"
	exit 1
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

c=0
cat "${f}" | tr '\n' ' ' | tr -s ' ' | while IFS= read -n1 e ; do
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
done
echo
