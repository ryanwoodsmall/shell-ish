#!/usr/bin/env bash
#
# generate some functions in "verb_target_extra{_extra,...}" format
#
# this can be used to get and use function-name-encoded info with a standarized naming scheme
# - like package name at runtime using function name
# - or "what to do"
# - if this is "install" with "name1", do this, if it's "name2" do this other thing
#
# also show caller info and stack here and there
#

function showstack() {
  echo stack:
  n=2
  for i in $(seq $((${#FUNCNAME[@]}-1)) -1 0) ; do
    for d in $(seq 0 $((${n}-1))) ; do
      echo -n " "
    done
    echo ${FUNCNAME[${i}]}
    ((n=n+2))
  done
}

function showcallerinfo() {
  fn=${FUNCNAME[1]}
  IFS=_ read v t e <<< $fn
  e=${fn#${v}_${t}_}
  if [ -z "${t}" ] ; then
    echo $fn : not in verb target extra format
  else
    echo $fn : verb: $v , target: $t , extra: $e
  fi
  showstack
}

function k_l_m_n() {
  showcallerinfo
}

function h_i_j() {
  k_l_m_n
}

function d_e_f() {
  h_i_j
}

function a_b_c() {
  showcallerinfo
  d_e_f
}

function runner() {
  showcallerinfo
  a_b_c
  k_l_m_n
  showcallerinfo
}

showcallerinfo
runner
