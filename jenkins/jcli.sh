#!/bin/bash

wdir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
: ${jh:="jm"}
: ${jp:="8080"}
: ${js:="http://"}
ju="${js}${jh}:${jp}"
jcj="jenkins-cli.jar"
jcju="${ju}/jnlpJars/${jcj}"
copts="-k -L -s"
jcli="java -jar ${wdir}/${jcj} -s ${ju}"

test -e "${wdir}/${jcj}" || {
	curl "${copts}" -o "${wdir}/${jcj}" "${jcju}"
}

eval "${jcli}" "${@}"
