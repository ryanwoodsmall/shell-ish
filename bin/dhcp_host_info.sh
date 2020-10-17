#!/usr/bin/env bash

#
# read dnsmasq DHCPACK lines, generate data for MAC, IP, and host
#
# lines look like:
#   Oct 17 05:01:38 router dnsmasq-dhcp[1234]: DHCPACK(br-lan) 1.2.3.4 00:11:22:33:44:55
#   Oct 17 07:08:07 router dnsmasq-dhcp[1234]: DHCPACK(br-lan) 1.2.3.5 66:77:88:99:AA:BB hostname
#
# XXX - pretty dependent on well-formated/behaved dnsmasq lines - may change with version?
# XXX - would be better to track all this junk in a database?
# XXX - hand cranking "json" here is ugly, would 'jo' be a better fit?
# XXX - should log files be a list instead of a singleton?
#

set -eu

echo "running at $(date +%Y%m%d%H%M%S)" 1>&2

: ${lf:="/var/log/messages"}

n=0
declare -A m2i i2m i2h h2i m2h h2m

while IFS= read l ; do
  a[${n}]="${l}"
  ((n+=1))
done < <(grep DHCPACK "${lf}")
echo "read ${#a[@]} lines" 1>&2
echo "first entry at $(echo ${a[0]} | cut -f1-3 -d' ')" 1>&2
echo "last entry at $(echo ${a[$((${#a[@]}-1))]} | cut -f1-3 -d' ')" 1>&2

for n in ${!a[@]} ; do
  h='' ; i='' ; l='' ; m=''
  l=( $(echo "${a[${n}]}" | cut -f2- -d')') )
  i="${l[0]}"
  m="${l[1]}"
  m2i["${m}"]="${i}"
  i2m["${i}"]="${m}"
  m2h["${m}"]="${h}"
  i2h["${i}"]="${h}"
  if [ ${#l[@]} -ge 3 ] ; then
    h="${l[2]}"
    m2h["${m}"]="${h}"
    h2m["${h}"]="${m}"
    i2h["${i}"]="${h}"
    h2i["${h}"]="${i}"
  fi
done
echo "read ${#m2i[@]} mac addresses" 1>&2

echo '['
n=0
for m in ${!m2i[@]} ; do
  echo '  {'
  echo '    "mac": "'"${m}"'",'
  echo -n '    "ip": "'"${m2i[${m}]}"'"'
  if [ ! -z "${m2h[${m}]}" ] ; then
    echo ','
    echo '    "host": "'"${m2h[${m}]}"'"'
  else
    echo
  fi
  echo -n '  }'
  ((n+=1))
  if [ ${n} -lt ${#m2i[@]} ] ; then
    echo ','
  else
    echo
  fi
done
echo ']'
