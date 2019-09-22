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

declare -a lines
declare -a certs
i=0
n=0
OLDIFS="${IFS}"
IFS="$(printf '\r')"
for l in $(keytool -list -keystore ${cacertsfile} -storepass ${storepass} -rfc | sed -n '/BEGIN CERTIFICATE/,/END CERTIFICATE/!d;p' | unix2dos) ; do
  echo "${l}" | grep -q 'BEGIN CERTIFICATE' && n=$((${n}+1)) || true
  lines[${i}]="${l}"
  i=$((${i}+1))
  certs[${n}]+="$(echo "${l}" | dos2unix)"
done
export IFS="${OLDIFS}"
echo "${#lines[@]} lines, ${#certs[@]} certs" 1>&2
for n in ${!certs[@]} ; do
  openssl x509 -noout -in <(echo "${certs[${n}]}") -{fingerprint,hash,serial,{subject,issuer},dates} | sed 's/^/# /g' >> ${outfile}
  echo "${certs[${n}]}" | dos2unix | grep -v '^$' >> ${outfile}
  echo >> ${outfile}
done
