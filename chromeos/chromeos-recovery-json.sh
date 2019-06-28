#!/usr/bin/env bash

#
# downloads and reads a Chrome OS recovery.conf file
# generates a JSON representation of the machine recovery
#

set -eu

declare -a f
declare -a names
declare -a starts
declare -a ends

# XXX - the recovery.conf file is referenced in linux_recovery.sh
# XXX - probably need to get it from there instead of hard-coding it here
ru="https://dl.google.com/dl/edgedl/chromeos/recovery"
rf="recovery.conf"
rs="${ru}/linux_recovery.sh"
rc="${ru}/${rf}?source=${rs##*/}"

of="/tmp/${rf}"

# grab recovery.conf file
curl -k -L -f -s -o "${of}" "${rc}"
dos2unix "${of}" >/dev/null 2>&1

# read the file into an array of lines with one extra terminal line
n=0
while IFS="$(printf '\n')" read -r l ; do
  f[${n}]="${l}"
  ((n+=1))
done < "${of}"
f[${n}]=""

# generate a list of board names (mostly for a count) with stanza start/end lines
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

# given a line number, dump a json substring with one-line look-ahead to see if we still have data to parse
# probably need to check in caller if next line is starts for next name?
function format_kv() {
  o="${1}"
  line="${f[${o}]}"
  if [[ ${line} =~ = ]] ; then
      k="${line%%=*}"
      v="${line#${k}=}"
      v="${v//\"/}"
      v="${v//\\/}"
      echo -n '    "'"${k}"'": "'"${v}"'"'
      if [[ ${f[$((${o}+1))]} =~ = ]] ; then
        echo ','
      else
        echo
      fi
  fi
}

# print out the json array
echo '['
echo '  {'
# non-board recovery_tool_ stuff in a single object
for n in $(seq 0 $((${starts[0]}-1))) ; do
  format_kv "${n}"
done
echo '  },'
# and every board from recovery.conf gets its own object
for n in ${!names[@]} ; do
  echo '  {'
  for l in $(seq ${starts[${n}]} ${ends[${n}]}) ; do
    format_kv "${l}"
  done
  echo -n '  }'
  if [ ${n} -lt $((${#names[@]}-1)) ] ; then
    echo ','
  else
    echo
  fi
done
echo ']'
