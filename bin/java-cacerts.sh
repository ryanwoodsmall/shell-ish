#!/bin/bash

#
# dump java keystore to a pem for system openssl usage
#
# https://www.calazan.com/how-to-convert-a-java-keystore-jks-to-pem-format/
#   keytool -importkeystore -srckeystore myapp.jks -destkeystore myapp.p12 -srcalias myapp-dev -srcstoretype jks -deststoretype pkcs12
#   openssl pkcs12 -in myapp.p12 -out myapp.pem
#
# should use fewer p12/pem temp files but keytool and openssl are relatively unfriendly
#

set -eu
set -o pipefail

: ${outdir:="/tmp/$$_java-cacerts"}
: ${outfile:="${outdir}/ca-bundle.crt"}
: ${storepass:="changeit"}

function failexit() {
  echo "${1}"
  exit 1
}

for p in java jrunscript keytool openssl ; do
  hash ${p} >/dev/null 2>&1 || failexit "${p} not found"
done

javahome="$(jrunscript -e 'java.lang.System.out.println(java.lang.System.getProperty("java.home"));')"
: ${cacertsfile:="${javahome}/lib/security/cacerts"}

test -e "${cacertsfile}" || failexit "cacerts not found at ${cacertsfile}"

mkdir -p "${outdir}" || failexit "could not create ${outdir}"
echo -n > ${outfile}
echo "outdir is ${outdir}" 1>&2
echo "outfile is ${outfile}" 1>&2

aliases=( $(keytool -list -keystore ${cacertsfile} -storepass ${storepass} | awk -F, '/trustedCertEntry/{print $1}' | sort) )
declare -A b64a
for a in ${aliases[@]} ; do
  b64a["${a}"]="$(echo "${a}" | base64)"
done

for a in ${aliases[@]} ; do
  b64="${b64a[${a}]}"
  echo "converting alias ${a} with base64 value ${b64}" 1>&2
  p12="${outdir}/${b64}.p12"
  pem="${outdir}/${b64}.pem"
  #{
    rm -f ${p12} ${pem}{,.{tmp,hdr}}
    keytool -importkeystore -srckeystore ${cacertsfile} -srcstorepass ${storepass} -srcstoretype jks -srcalias "${a}" -destkeystore ${p12} -deststorepass ${storepass} -deststoretype pkcs12
    openssl pkcs12 -in ${p12} -out ${pem}.tmp -passin pass:${storepass}
    echo "a: ${a}" > ${pem}
    echo "b64: ${b64}" >> ${pem}
    echo "jks: ${cacertsfile}" >> ${pem}
    echo "p12: $(basename ${p12})" >> ${pem}
    echo "pem: $(basename ${pem})" >> ${pem}
    keytool -list -keystore ${p12} -storepass ${storepass} >> ${pem}
    sed -n '/BEGIN CERTIFICATE/,/END CERTIFICATE/d;p' ${pem}.tmp >> ${pem}
    sed -i 's/^/# /g' ${pem}
    sed -n '/BEGIN CERTIFICATE/,/END CERTIFICATE/p' ${pem}.tmp >> ${pem}
    rm -f ${p12} ${pem}.{tmp,hdr}
  #} &
done
wait

for a in ${aliases[@]} ; do
  pem="${outdir}/${b64a[${a}]}.pem"
  cat ${pem} >> ${outfile}
  echo >> ${outfile}
  rm -f ${pem}
done
