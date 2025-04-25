#!/usr/bin/env bash
#
# self-modifying incrementor with like-named variable
# unlike examples/self-modifying-iterator.bash this takes optional starting and step values
#

function incr() {
  local -i i=0
  local -i p=1
  local -i n=0
  local funcname="${FUNCNAME[0]}"
  local -a funcarray
  readarray -t funcarray < <(declare -f "${funcname}")
  funcarray[0]="function ${funcarray[0]}"
  if [[ ${#} -gt 0 ]] ; then
    if [[ ${1} =~ ^(|-)[0-9]+$ ]] ; then
      i="${1}"
      shift
      if [[ ${#} -gt 0 ]] ; then
        if [[ ${1} =~ ^(|-)[0-9]+$ ]] ; then
          p="${1}"
          shift
        else 
          return
        fi
      fi
    else
      return
    fi
  fi
  n=$((i+p))
  export ${funcname}="${i}"
  printf '%s\n' "${i}"
  for e in ${!funcarray[@]} ; do
    if [[ "${funcarray[${e}]}" =~ "local -i i=" ]] && [[ "${funcarray[${e}]}" =~ i=(|-)[0-9]+ ]] ; then
      funcarray[${e}]="local -i i=${n};"
    elif [[ "${funcarray[${e}]}" =~ "local -i p=" ]] && [[ "${funcarray[${e}]}" =~ p=(|-)[0-9]+ ]] ; then
      funcarray[${e}]="local -i p=${p};"
    fi
  done
  source /dev/stdin < <(for e in ${!funcarray[@]} ; do printf '%s\n' "${funcarray[${e}]}" ; done)
}
