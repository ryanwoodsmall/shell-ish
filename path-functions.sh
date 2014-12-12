##################
# path functions #
##################

# chomp trailing slash (if any)
chomp_trailing_slash() {
  echo ${@} | \
    sed 's#/$##g'
}

# is $1 in $PATH?
in_path() {
  echo ${PATH} | \
    tr ':' '\n' | \
    grep -q ^"`chomp_trailing_slash ${1}`"$
  return $?
}

# add $1 to end of $PATH
append_path() {
  in_path "${1}" || \
    export PATH="${PATH}:${1}"
}

# remove $1 from $PATH
remove_path() {
  in_path "${1}" && \
    export PATH=$(echo ${PATH} | \
    tr ':' '\n' | \
    grep -v ^"`chomp_trailing_slash ${1}`"$ | \
    tr '\n' ':' | \
    sed 's#:$##g')
}

# add $1 to beginning of path
prepend_path() {
  in_path "${1}" || \
    export PATH="${1}:${PATH}"
}
