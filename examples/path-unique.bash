#!/usr/local/crosware/software/bash/current/bin/bash5
#
# print unique ${PATH} using bash arrays/hashes
#
# XXX - assumes no space in ${PATH}
# XXX - don't put spaces in ${PATH}, really
# XXX - don't, not kidding
#
# usage:
#   export PATH="$(/path/to/path-unique.bash)"
#
set -euo pipefail
declare -a a=( ${PATH//:/ } )
declare -a u=()
declare -A h=()
for (( i=$((${#a[@]}-1)) ; i>=0 ; i-- )) ; do
  h["${a[${i}]}"]="${i}"
done
for k in ${!h[@]} ; do
  u[${h["${k}"]}]="${k}"
done
a="${u[@]}"
a="${a// /:}"
printf '%s\n' "${a}"
