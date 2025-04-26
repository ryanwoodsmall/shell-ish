#!/usr/bin/env bash
#
# self-modifying incrementor with like-named variable
# unlike examples/self-modifying-counter.bash this takes optional starting and step values
# exports a hash of YYYYMMDDHHMMSS to value
# XXX - only one second granularity, busybox date doesn't support real $N for nanosecond?
#

declare -A | grep -q ' incr_h=' || declare -A incr_h=()
export incr_h

function incr() {
  local -i i=0
  local -i p=1
  local -i n=0
  local funcname="${FUNCNAME[0]}"
  local -a funcarray
  local ts="$(date +%Y%m%d%H%M%S)"
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
  eval "${funcname}_h[\"${ts}\"]=\"${i}\""
  export ${funcname}_h
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
