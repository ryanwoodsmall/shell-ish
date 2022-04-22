#!/usr/bin/env bash
#
# exclude words from a list using a set of exclusions and bash regex
#

set -euo pipefail

# word list
wl=( one two three four five six seven eight nine ten zero "a space" "another space" )
for i in ${!wl[@]} ; do
  echo wl[${i}] : ${wl[${i}]}
done

# word list expanded
wle="${wl[@]}"
echo wle : ${wle}
echo

# exclusion list
el=( two six zero "a space" )
for i in ${!el[@]} ; do
  echo el[${i}] : ${el[${i}]}
done

# exclusion list expanded
ele="${el[@]}"
echo ele : ${ele}

# exclusion list delimited
eld="$(for i in ${!el[@]} ; do echo ${el[${i}]} ; done | paste -s -d '|' -)"
echo eld : ${eld}

# exclusion list regex
elr="^(${eld})$"
echo elr : ${elr}
echo

for i in ${!wl[@]} ; do
  w="${wl[${i}]}"
  if [[ ${w} =~ ${elr} ]] ; then
    echo e : ${w}
    continue
  fi
  echo w : ${w}
done
