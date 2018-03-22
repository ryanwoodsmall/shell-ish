#!/bin/bash

instdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

rhinover="1.7.9"
rhinouri="https://github.com/mozilla/rhino/releases/download/Rhino${rhinover//./_}_Release/rhino-${rhinover}.jar"
rhinofile="$(basename ${rhinouri})"
rhinoclass="org.mozilla.javascript.tools.shell.Main"
rhinosha256sum="8ef93957cd12cadbd39c2d34ff9b2224970740fa667820cf72af4f917a0e5fed"

jlinever="2.14.5"
jlineuri="http://repo1.maven.org/maven2/jline/jline/${jlinever}/jline-${jlinever}.jar"
jlinefile="$(basename ${jlineuri})"
jlinesha256sum="4f347bc90d6f5ce61c0f8928d44a7b993275ceaa7d7f237714518a9bdd5003ce"

test -e ${instdir} || mkdir -p ${instdir}
for u in ${rhinouri} ${jlineuri} ; do
  outfile="${instdir}/$(basename ${u})"
  test -e ${outfile} || {
    echo "${outfile}:"
    curl -k -L -o ${outfile} ${u}
    echo
  }
done

if [[ $(sha256sum ${instdir}/${rhinofile} | awk '{print $1}') != ${rhinosha256sum} || $(sha256sum ${instdir}/${jlinefile} | awk '{print $1}') != ${jlinesha256sum} ]] ; then
  echo "sha256sum mismatch - check ${instdir}/${rhinofile} and ${instdir}/${jlinefile}"
  exit 1
fi

java -Djava.awt.headless=true -cp ${instdir}/${rhinofile}:${instdir}/${jlinefile} ${rhinoclass} "${@}"
