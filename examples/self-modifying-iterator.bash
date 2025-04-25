#!/usr/bin/env bash
#
# self-modifying iterator with like-named variable
#

function iter() {
  local -i i=0
  local -i n=$((i+1))
  local funcname="${FUNCNAME[0]}"
  local func="function $(declare -f ${funcname})"
  export ${funcname}="${i}"
  printf '%s\n' "${i}"
  func="${func//local -i i=${i}/local -i i=${n}}"
  eval "${func}"
}
