#!/usr/bin/env bash
#
# generate some functions in "verb_target_extra{_extra,...}" format
#
# XXX - "stack" is not right, need a depth tracking wrapper with a counter for indent level
# XXX - increment n, filter functions and add caller as necessary
# XXX - should verb be action? action-target-options? important!
#
# this can be used to get and use function-name-encoded info with a standarized naming scheme
# - like package name at runtime using function name
# - or "what to do"
# - if this is "install" with "name1", do this, if it's "name2" do this other thing
#
# useful funcs
# - {get,has}{verb,target,extra}
#
# also show caller info and stack here and there
#
# recursion detection - loop too... hmmmmmm...
#
# splicing into functions:
# - "call func args"
# - wrapper, check for flag
# - should probably check that something is actually a function with declare, otherwise just eval?
# - "save old func" should probably save the body only
#   - declare -a newfunc=()
#   - mapfile -t newfunc < <(declare -p func)
#   - unset newfunc[$((${#newfunc[@]}-1))] # delete last '}'
#   - shift # get 'funcname () '
#   - shift # get first '{'
# - probably need a "wrapper wrapper" that just prints the new function with amendments
#   - would allow replacements
#   - func -> newfunc -> func=newfunc -> delete newfunc
#   - with callbacks/callhook below...
#   - could use for e.g. a package to tell upstream "if you install yourself, upgrade me too"
#   - no special handling, just throw a check in a function or an overrides dir that's sourced
# - if flag, save function, insert code...
#   - like to show stack...:
#   - { printf "%$((${#FUNCNAME[@]}*2))s" ; printf " * ${FUNCNAME[0]} : ${@}" ; } 1>&2
#     -or { l=${#FUNCNAME[@]} ; for i in ${!FUNCNAME[@]} ; do e=$(((${i}+1)%${l})) ; printf "%$((${e}*2))s" ; echo "* ${FUNCNAME[${i}]}" ; done ; } | tac 1>&2
#   - "eval newfunc argument1 argument2 ..."
#   - restore oldfunc
#   - delete newfunc
# - callbacks?
#   - crosware...
#   - "applycallback func" - reify funcs after round of sourcing profile
#   - use a stack/array?
#     - global hash with serialized array of callbacks?
#       - "addcallback func 'cmd one' 'cmd two'"
#       - crosware rcallbacks=( "targetfunc 'cmd1 ; cmd2' 'second set'" "targetgfunc2 'cmd3 | cmd4'" )
#       - serialze original function to a function hash (once, based on hash key existence)
#       - check hash keys for func, initialize to empty array () if not found
#       - if found, rehydrate to temp array
#       - append any args to the array
#       - serialize and save to hash value for func key
#       - rehydrate serialized original func and append all callbacks to array
#       - eval the new function array to replace it
#   - "callback 'callback_def callback_args' func func_arg1 'func_arg2-a func_arg2-b' func_arg..."
#   - shift off callback
#   - save function
#   - insert depth tracker above
#   - replace last element with "callback_def callback args"
#   - "eval newfunc func_arg1 'func_arg2-a func_arg2-b' func_arg..."
#   - restore oldfunc
#   - delete newfunc
# - call should not call itself
#   - if function is call just, eval "${@}"
#   - same for callback, if function is callbaack, eval call "${@}"
# - "callhook 'custom pre' 'custom post' func arg1 arg2 ..."
#   - both
# - "call{insert,replace} pos# 'custom command args' func"
#   - default position to 0
#   - insert a custom command at the specified location
#     - newfunc=( $(declare -f func | getfuncbody) )
#     - newfunc[0]="function function_${RANDOM}()"
#     - for e in $(seq ${#} -1 ${i}) ; do newfunc[${e}]="${newfunc[$((${e}-1))]}" ; done
#     - newfunc[${i}]="custom command args"
#   - replace is just newfunc[${i}]="custom command args"
# - "call{prepend,append} 'custom command' func"
#   - prepend: insert at line 0 of func body
#   - append: just tack onto the end of the func body
# - "callreinplace '^bash|(-|_)regex(\.pattern|)$' 'custom replacement' func
#   - if [[ $line =~ $pattern ]] ...
# - "callbuild func 'command 1' 'command 2' 'command3 | command4'
#   - append to func body
# - passing a whole lot of function bodies around
# - could lead to self-modifying shell script, o h t h e h o r r o r
#
# useful funcs
# - variables : "varexists varname"    "vartype varname"
# - array     : "arrayexists arrayvar" "isarray arrayvary" "createarray arrayvar" "savearray arrayvar" "uniqarray arrayvar"
# - hash      : "hashexists hashvar"   "ishash hashvar"    "createhash hashvar"   "getkeys hashvar"    "haskey hashvar key" "savehash hashvar"
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
  echo
}

function k_l_m_n() {
  showcallerinfo
}

function h_i_j() {
  k_l_m_n
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
}

showcallerinfo
runner
