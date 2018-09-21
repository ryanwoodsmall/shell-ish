#!/bin/bash

#
# exit w/return code 0 if JCE unlimited strength is available
#   shouldn't be necessary since 8u161
#

jrunscript -e 'exit (javax.crypto.Cipher.getMaxAllowedKeyLength("AES") < 256);'
