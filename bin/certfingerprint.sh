#!/usr/bin/env sh

# read fingerprint (thumbprint in VMware parlance) from an HTTPS cert

openssl \
  x509 \
  -noout \
  -fingerprint | \
    grep -i ^'SHA1 Fingerprint=' | \
    cut -f2 -d=
