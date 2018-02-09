#!/bin/bash

#
# jcli.sh
#  shell wrapper around jenkins cli jnlp jar
#
# environment vars:
#  jo - options to pass to the cli, default empty
#  js - scheme, either http or https, default http
#  jh - jenkins master hostname or ip, default localhost
#  jc - jenkins context including slash (path, ala /jenkins), default empty
#  jp - jenkins master port, default 8080
#

for prereq in curl java unzip ; do
  which ${prereq} >/dev/null 2>&1 || {
    echo "${prereq} not found"
    exit 1
  }
done

wdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
: ${jo:=""}
: ${js:="http://"}
: ${jh:="localhost"}
: ${jp:="8080"}
: ${jc:=""}
# repeated slashes (//) will be squashed to a single slash
ju="${jh}:${jp}/${jc}"
ju="${js}${ju//\/\///}"
jcj="jenkins-cli.jar"
jcju="${ju}/jnlpJars/${jcj}"
copts="-k -L -s"
jcli="java -jar ${wdir}/${jcj} -s ${ju} ${jo}"

# set default url
export JENKINS_URL="${ju}"

test -e "${wdir}/${jcj}" || {
  curl ${copts} -o "${wdir}/${jcj}" "${jcju}"
}
unzip -l "${wdir}/${jcj}" >/dev/null 2>&1 || {
  echo "${wdir}/${jcj} doesn't appear to be a valid zip file"
  rm -f "${wdir}/${jcj}"
  exit 1
}

eval "${jcli}" "${@}"
