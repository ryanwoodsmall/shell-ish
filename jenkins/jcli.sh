#!/bin/bash

wdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
: ${js:="http://"}
: ${jh:="jm"}
: ${jp:="8080"}
ju="${js}${jh}:${jp}"
jcj="jenkins-cli.jar"
jcju="${ju}/jnlpJars/${jcj}"
copts="-k -L -s"
jcli="java -jar ${wdir}/${jcj} -s ${ju} ${jopts}"

test -e "${wdir}/${jcj}" || {
	curl ${copts} -o "${wdir}/${jcj}" "${jcju}"
}

eval "${jcli}" "${@}"
