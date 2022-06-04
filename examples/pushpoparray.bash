#!/usr/bin/env bash
#
# push/pop to/from bash arrays
#
#  XXX - push/pop implies a stack (LIFO); FIFO implemented as well
#  XXX - push/pop on list as stack; enqueue/dequeue on list as fifo
#  XXX - pop/push can do car/cdr stuff...
#  XXX - append vs prepend?
#  XXX - global lock
#  XXX - make iflock per-stream (read/write) locking for thread-safety?
#  XXX - iflock array [read|write] [lock|unlock] - would just need to lock on ${arraylock[${arrayname}_${read|write}]}?
#  XXX - in-memory data types
#  XXX - could combine with serialized hash to do key/value store, pub/sub, etc.
#  XXX - urlencode/base64 encode data. json. lol
#  XXX - id with uuid
#  XXX - not far from map/filter(/reduce?/apply?) behavior here
#  XXX - need copy array function
#  XXX - combine with fs fifos/network sockets to generalize/distribute
#
#  XXX - waitlock/freelock should send commands to an intermediate service function
#    state:    LOCKED, FREE
#    commands: LOCK, FREE, WAIT
#    could use a fork/background/wait thred
#    or build a stream with fifo idea...
#
#           LOCKED   FREE
#           _________________
#      LOCK| false  | true  |
#      FREE| true   | false |
#      WAIT| thread | LOCK  |
#          ------------------
#

set -eu

declare -A arraylock
: ${writelock:=1}
: ${readlock:="${writelock}"}
: ${testscript:=0}

function waitlock() {
  local a
  if [ ${#} -lt 1 ] ; then
    echo "${FUNCNAME}: not enough arguments" 1>&2
    return
  fi
  a="${1}"
  : ${arraylock[${a}]:=0}
  while [ ${arraylock[${a}]} -eq 1 ] ; do
    usleep 100
  done
  unset a
}

function lockarray() {
  local a
  if [ ${#} -lt 1 ] ; then
    echo "${FUNCNAME}: not enough arguments" 1>&2
    return
  fi
  a="${1}"
  waitlock "${a}"
  arraylock[${a}]=1
  unset a
}

function unlockarray() {
  local a
  if [ ${#} -lt 1 ] ; then
    echo "${FUNCNAME}: not enough arguments" 1>&2
    return
  fi
  a="${1}"
  arraylock[${a}]=0
  unset a
}

function iflock() {
  local a l c s v
  if [ ${#} -lt 3 ] ; then
    echo "${FUNCNAME}: not enough arguments" 1>&2
    return
  fi
  a="${1}"
  l="${2}"
  c="${3}"
  v="${l}lock"
  eval ": \${${v}:=0}"
  export "${v}"
  if [ ${!v} -eq 1 ] ; then
    if [[ ${c} =~ unlock ]] ; then
      unlockarray "${a}"
    else
      lockarray "${a}"
    fi
  fi
  unset a l c s v
}

function getarraylength() {
  local a l
  if [ ${#} -lt 1 ] ; then
    echo "${FUNCNAME}: not enough arguments" 1>&2
    return
  fi
  a="${1}"
  l=$(eval echo "\${#${a}[@]}")
  echo "${l}"
  unset a l
}

function pusharray() {
  local a e
  if [ ${#} -le 1 ] ; then
    echo "${FUNCNAME}: not enough arguments" 1>&2
    return
  fi
  a="${1}"
  iflock "${a}" write lock
  shift
  for e in "${@}" ; do
    eval "${a}+=( '${e}' )"
  done
  export "${a}"
  iflock "${a}" write unlock
  unset a e
}

function enqueuearray() {
  local a l i e n
  if [ ${#} -lt 1 ] ; then
    echo "${FUNCNAME}: not enough arguments" 1>&2
    return
  fi
  a="${1}"
  iflock "${a}" write lock
  shift
  l=$(getarraylength "${a}")
  n=$((${l}-1))
  for i in $(seq ${n} -1 0) ; do
    eval "${a}[$((${i}+${#}))]=\"\${${a}[${i}]}\""
  done
  i=0
  for e in "${@}" ; do
    eval "${a}[${i}]=\"${e}\""
    i=$((i++))
  done
  export "${a}"
  iflock "${a}" write unlock
  unset a l i e n
}

function poparray() {
  local a l n e
  if [ ${#} -lt 1 ] ; then
    echo "${FUNCNAME}: not enough arguments "1>&2
    return
  fi
  a="${1}"
  iflock "${a}" write lock
  l=$(getarraylength "${a}")
  if [ ${l} -lt 1 ] ; then
    iflock "${a}" write unlock
    return
  fi
  n=$((${l}-1))
  e=$(eval echo \"\${${a}[${n}]}\")
  echo "${e}"
  eval unset "${a}[${n}]"
  export "${a}"
  iflock "${a}" write unlock
  unset a l n e
}

function dequeuearray() {
  poparray "${@}"
}

function takearray() {
  local a l i e n
  if [ ${#} -lt 1 ] ; then
    echo "${FUNCNAME}: not enough arguments" 1>&2
    return
  fi
  a="${1}"
  iflock "${a}" write lock
  l=$(getarraylength "${a}")
  if [ ${l} -lt 1 ] ; then
    unlockarray "${a}"
    return
  fi
  e="$(eval echo "\${${a}[0]}")"
  echo "${e}"
  if [ ${l} -eq 1 ] ; then
    eval unset "${a}[0]"
    unlockarray "${a}"
    return
  fi
  n=$((${l}-1))
  for i in $(eval echo \${!${a}[@]}) ; do
    if [[ ${i} == 0 ]] ; then
      continue
    fi
    eval "${a}[$((${i}-1))]=\"\${${a}[${i}]}\""
  done
  eval unset "${a}[${n}]"
  iflock "${a}" write unlock
  unset a l i e n
}

function peekarray() {
  local a l n
  if [ ${#} -lt 1 ] ; then
    echo "${FUNCNAME}: not enough arguments" 1>&2
    return
  fi
  a="${1}"
  iflock "${a}" read lock
  l=$(getarraylength "${a}")
  if [ ${l} -lt 1 ] ; then
    unlockarray "${a}"
    return
  fi
  n=$((${l}-1))
  eval echo "\${${a}[${n}]}"
  iflock "${a}" read unlock
  unset a l n
}

function showarray() {
  local a i
  if [ ${#} -lt 1 ] ; then
    echo "${FUNCNAME}: not enough arguments "1>&2
    return
  fi
  a="${1}"
  iflock "${a}" read lock
  p=""
  if [ ${#} -gt 1 ] ; then
    p="${2}: "
  fi
  for i in $(eval echo \${!${a}[@]}) ; do
    echo "${p}$(eval echo \"\${${a}[${i}]}\")"
  done
  iflock "${a}" read unlock
  unset a i
}

function dumparray() {
  local a i
  if [ ${#} -lt 1 ] ; then
    echo "${FUNCNAME}: not enough arguments "1>&2
    return
  fi
  a="${1}"
  iflock "${a}" read lock
  echo -n "${a}=( "
  for i in $(eval echo \${!${a}[@]}) ; do
    echo -n "[${i}]=\"$(eval echo \${${a}[${i}]})\" "
  done
  echo " )"
  iflock "${a}" read unlock
  unset a i
}

if [ ${testscript} -eq 1 ] ; then
  declare -a testarray
  testarray=()
  showarray testarray
  getarraylength testarray
  s=()
  s+=( 'push:element zero' )
  s+=( 'push:1' )
  s+=( 'push:this is two' )
  s+=( 'pop:' )
  s+=( 'push:three' )
  s+=( 'pop:' )
  s+=( 'push:4' )
  s+=( 'pop:' )
  s+=( 'pop:' )
  s+=( 'pop:' )
  s+=( 'pop:' )
  s+=( 'push:last' )
  s+=( 'enqueue:new first' )
  s+=( 'enqueue:0th' )
  s+=( 'pop:' )
  s+=( 'dequeue:' )
  s+=( 'dequeue:' )
  s+=( 'enqueue:element zero' )
  s+=( 'enqueue:1' )
  s+=( 'enqueue:two' )
  s+=( 'take:' )
  s+=( 'pop:' )
  s+=( 'take:' )
  s+=( 'take:' )
  s+=( 'push:new 1' )
  s+=( 'peek:' )
  s+=( 'push:new 2' )
  s+=( 'peek:' )
  s+=( 'pop:' )
  s+=( 'peek:' )
  s+=( 'pop:' )
  s+=( 'peek:' )
  for i in ${!s[@]} ; do
    v="${s[${i}]}"
    v="${v%%:*}"
    e="${s[${i}]}"
    e="${e#${v}:}"
    echo "-- ${s[${i}]}"
    ${v}array testarray "${e}"
    #showarray testarray
    echo "$(getarraylength testarray) : $(dumparray testarray)"
  done
fi
