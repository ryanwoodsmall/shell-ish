#!/bin/bash

instdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

rhinover="1.7.13"
rhinouri="https://repo1.maven.org/maven2/org/mozilla/rhino/${rhinover}/rhino-${rhinover}.jar"
rhinofile="$(basename ${rhinouri})"
rhinoclass="org.mozilla.javascript.tools.shell.Main"
rhinosha256sum="931dda33789d8e004ff5b5478ee3d6d224305de330c48266df7c3e49d52fc606"

jlinever="2.14.6"
jlineuri="https://repo1.maven.org/maven2/jline/jline/${jlinever}/jline-${jlinever}.jar"
jlinefile="$(basename ${jlineuri})"
jlinesha256sum="97d1acaac82409be42e622d7a54d3ae9d08517e8aefdea3d2ba9791150c2f02d"

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
