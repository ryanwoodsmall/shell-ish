#!/bin/bash

set -eu

declare -a f
declare -a names
declare -a starts
declare -a ends

ru="https://dl.google.com/dl/edgedl/chromeos/recovery"
rf="recovery.conf"
rs="${ru}/linux_recovery.sh"
rc="${ru}/${rf}?source=${rs##*/}"

of="/tmp/${rf}"

curl -k -L -f -s -o "${of}" "${rc}"
dos2unix "${of}" >/dev/null 2>&1

n=0
while IFS="$(printf '\n')" read -r l ; do
  f[${n}]="${l}"
  ((n+=1))
done < "${of}"
f[${n}]=""

n=0
for l in ${!f[@]} ; do
  if [[ ${f[${l}]} =~ ^name= ]] ; then
    name="${f[${l}]}"
    names[${n}]="${name#name=}"
    starts[${n}]="${l}"
    if [ ${n} -gt 0 ] ; then
      ends[$((${n}-1))]="$((${l}-1))"
    fi
    ((n+=1))
  fi
done
ends[$((${n}-1))]="${l}"

echo "["
echo "  {"
for n in $(seq 0 $((${starts[0]}-1))) ; do
  line="${f[${n}]}"
  # XXX - dupe, make it a function
  if [[ ${line} =~ = ]] ; then
      k="${line%%=*}"
      v="${line#${k}=}"
      echo -n '    "'"${k}"'": "'"${v}"'"'
      if [[ ${f[$((${n}+1))]} =~ = ]] ; then
        echo ","
      else
        echo
      fi
  fi
done
echo "  },"
for n in ${!names[@]} ; do
  echo "  {"
  for l in $(seq ${starts[${n}]} ${ends[${n}]}) ; do
    line="${f[${l}]}"
    if [[ ${line} =~ = ]] ; then
      k="${line%%=*}"
      v="${line#${k}=}"
      v="${v//\"/}"
      v="${v//\\/}"
      echo -n '    "'"${k}"'": "'"${v}"'"'
      if [ ${l} -lt ${ends[${n}]} ] ; then
        if [[ ${f[$((${l}+1))]} =~ = ]] ; then
          echo ","
        else
          echo
        fi
      fi
    fi
  done
  echo -n "  }"
  if [ ${n} -lt $((${#names[@]}-1)) ] ; then
    echo ","
  else
    echo
  fi
done
echo "]"
