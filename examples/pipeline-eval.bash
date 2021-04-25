#!/usr/bin/env bash
#
# create and eval a pipeline
#

set -eu

# example failing program
function efp() {
  test ${#} -eq 0 && a=0 || a="${1}"
  echo "${FUNCNAME}: doing something... failed: ${a}"
  return 1
}

# example succeding program
function esp() {
  test ${#} -eq 0 && a=0 || a="${1}"
  echo "${FUNCNAME}: doing something... succeeded: ${a}"
  return 0
}

# exit hard
function fail() {
  echo 'totally failed...' 1>&2
  exit 1
}

# reverse a list of arguments
function reverseargs() {
  local i t
  local r=()
  i=0
  while (( ${#} )) ; do
    t="${1}"
    r[${i}]="${t}"
    shift
    i=$((${i}+1))
  done
  for i in $(seq $((${#r[@]}-1)) -1 0) ; do
    echo "${r[${i}]}"
  done
  unset i r t
}

# build an '&&' pipeline
function buildandpipeline() {
  if [ ${#} -eq 0 ] ; then
    echo "true"
    return
  fi
  if [ ${#} -eq 1 ] ; then
    echo "${1}"
    return
  fi
  local d="${1}"
  shift
  buildpipeline "&&" "${d}" "${@}"
}

# build an '||' pipeline
function buildorpipeline() {
  if [ ${#} -eq 0 ] ; then
    echo "true"
    return
  fi
  if [ ${#} -eq 1 ] ; then
    echo "${1}"
    return
  fi
  local d="${1}"
  shift
  buildpipeline "||" "${d}" "${@}"
}

# build a pipeline
#  receives:
#   pipeline stage separator
#   default/base state
#   a bunch of commands
#     
function buildpipeline() {
  if [ ${#} -lt 3 ] ; then
    echo "# ${FUNCNAME}: wrong number of arguments; returning dummy pipeline" 1>&2
    echo true
    return
  fi
  # get the pipeline separator
  local l="${1}"
  shift
  # get the default/failure state
  local d="${1}"
  shift
  # iterate over the reversed array to generate the conditional pipeline
  local i=0
  readarray r < <(reverseargs "${@}")
  local s="${d}"
  for i in $(seq 0 $((${#r[@]}-1))) ; do
    s="${r[${i}]} ${l} ( ${s} )"
  done
  # XXX - is this safe? probably not... newlines probably need escaping
  echo "${s}" | tr -d '\n'
  unset l d r s i
}

: ${testscript:=0}
if [ ${testscript} -eq 1 ] ; then
  # build pipeline
  s=''
  i=0
  s+="esp ${i} && "
  for i in {1..4} ; do
    s+="efp ${i} || "
  done
  ((i++))

  # a successful run will short-circuit the pipeline
  #s+="esp ${i} || "
  s+="fail"

  # show s
  echo
  echo "# pipeline \${s}: ${s}"

  # this will fail (expected) with esp call commented above
  #eval "${s}"

  # fail call will kill the efp|| example, esp call will never eval the pipeline
  #esp ${i} || eval "$s"
  #efp ${i} || eval "$s"

  # subshell eval to workaround exit in fail()
  echo "# running: ( eval \"\${s}\" ) || esp \"${i}\""
  ( eval "${s}" ) || esp "${i}"

  # now with a function

  s=$(buildorpipeline "fail" "efp 1" "efp 2")
  echo
  echo "# pipeline \${s}: ${s}"
  echo "# running: ( eval \"\${s}\" ) || esp 3"
  ( eval "${s}" ) || esp 3

  s=$(buildandpipeline "true" "esp 1" "esp 2")
  echo
  echo "# pipeline \${s}: ${s}"
  echo "# running: ( eval \"\${s}\" ) || esp 3"
  ( eval "${s}" ) || esp 3

  s=$(eval buildorpipeline "fail" $(for i in {0..4} ; do echo -n "\"efp ${i}\" " ; done))
  echo
  echo "# pipeline \${s}: ${s}"
  echo "# running: ( eval \"\${s}\" ) || esp 5"
  ( eval "${s}" ) || esp 5

  s='( '
  s+=$(eval buildorpipeline "fail" $(for i in {0..2} ; do echo -n "\"efp ${i}\" " ; done))
  s+=' ) || ( '
  s+=$(eval buildandpipeline "true" $(for i in {0..2} ; do echo -n "\"esp ${i}\" " ; done))
  s+=' )'
  echo
  echo "# pipeline \${s}: ${s}"
  echo "# running: ( eval \"\${s}\" ) || true"
  ( eval "${s}" ) || true

  echo
fi
