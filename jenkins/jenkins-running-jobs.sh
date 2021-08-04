#!/usr/bin/env bash
#
# show running jenkins jobs using JSON API
#
# environment vars:
#  js - jenkins scheme, either http or https, default http
#  jh - jenkins master hostname or ip, default localhost
#  jc - jenkins context including slash (path, ala /jenkins), default empty
#  jp - jenkins master port, default 8080
#  jf - jenkins token file in "user:token" format, defaults to ${HOME}/.jenkins/token
#  jt - jenkins http token in "user:token" format, defaults to output of "$(cat ${HOME}/.jenkins/token)"
#
# ideas via:
#  https://stackoverflow.com/questions/14843874/from-jenkins-how-do-i-get-a-list-of-the-currently-running-jobs-in-json
#

set -eu
set -o pipefail

s="$(basename ${BASH_SOURCE[0]})"

function failexit() {
  echo "${s}: ${@}" 1>&2
  exit 1
}

: ${copts:='-g -k -L -s'}
: ${js:='http'}
: ${jh:='localhost'}
: ${jc:=''}
: ${jp:='8080'}
: ${jf:="${HOME}/.jenkins/token"}
: ${jt:=""}

if [ -z "${jt}" ] ; then
  test -e "${jf}" || failexit "no jenkins token! set token with 'jt=user:token' or path to file with 'jf=/path/to/jenkins/token'"
  jt="$(cat ${jf})"
fi

for p in curl jq ; do
  hash ${p} >/dev/null 2>&1 || failexit "${p} not found"
done

curl \
  ${copts} \
    "${js}://${jt}@${jh}:${jp}${jc}"'/computer/api/json?tree=computer[executors[currentExecutable[url]],oneOffExecutors[currentExecutable[url]]]&xpath=//url&wrapper=builds' \
| jq '.computer[]|(.executors[],.oneOffExecutors[])|select(.currentExecutable!=null)|.currentExecutable.url' \
| sort -u
