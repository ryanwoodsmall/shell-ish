#!/bin/bash

test -z "${oldgitdir}" && {
  echo 'please set ${oldgitdir} to a git checkout with "export oldgitdir=/full/path/to/git/clone"'
  exit 1
}

set -eu

#: ${oldgitdir:="${OLDPWD}"}
: ${newgitdir:="${PWD}"}
: ${outfile:="/tmp/$$_git.patch"}
export oldgitdir newgitdir outfile

# get commit of old dir
gc="$(cd ${oldgitdir} ; git log -p . | grep ^commit | tac | head -1 | awk '{print $NF}')"
if $(cd $oldgitdir ; git format-patch "${gc}^" >/dev/null 2>&1) ; then
  gc="${gc}^"
fi
( cd ${oldgitdir} ; git format-patch --stdout "${gc}" ) > ${outfile}

cat <<EOF
# outfile saved to ${outfile}"
# check/apply in ${newgitdir} with...
  git apply --stat ${outfile}
  git apply --check ${outfile}
  git am < ${outfile}
EOF