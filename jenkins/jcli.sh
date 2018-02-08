#!/bin/bash

wdir="$(dirname "${BASH_SOURCE[0]}")"
jcj="jenkins-cli.jar"
jh="jm"
jp="8080"
js="http://"
ju="${js}${jh}:${jp}"
copts="-k -L -s"
jcli="java -jar ${wdir}/${jcj} -s ${ju}"

test -e ${wdir}/${jcj} || {
	curl ${copts} -o ${wdir}/${jcj} ${ju}/jnlpJars/${jcj}
}

eval ${jcli} "${@}"
