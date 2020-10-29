#!/usr/bin/env bash
#
# https://support.citrix.com/article/CTX135602
# https://geekflare.com/san-ssl-certificate/
# https://devcenter.heroku.com/articles/ssl-certificate-self
# https://security.stackexchange.com/questions/74345/provide-subjectaltname-to-openssl-directly-on-the-command-line
# https://github.com/openssl/openssl/issues/3536
# https://coderwall.com/p/b443ng/generating-a-self-signed-wildcard-certificate
#
# requires openssl 1.1.1+
#

test -e san.pem && mv san.pem{,.PRE-$(date +%Y%m%d%H%M%S)}

cat >san.cnf<<EOF
[req]
default_bits = 2048
distinguished_name = req_distinguished_name
x509_extensions = v3_req
prompt = no
[req_distinguished_name]
C = US
ST = MO
L = St. Louis
O = FakeCo, LLC
OU = DevOps
CN = *.domain.com
[v3_req]
keyUsage = keyEncipherment, dataEncipherment, digitalSignature
extendedKeyUsage = serverAuth
subjectAltName = @alt_names
[alt_names]
DNS.1 = *.cloud.domain.com
EOF

openssl req -x509 -nodes -days 3650 -newkey rsa:2048 -keyout san.pem -out san.pem -config san.cnf -extensions 'v3_req'
