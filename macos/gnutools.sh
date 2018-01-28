#!/bin/bash

for gnutool in gawk gegrep gfgrep gfind ggrep gsed gxargs ; do
  which ${gnutool} >/dev/null && {
    alias ${gnutool#g}="${gnutool}"
  }
done
