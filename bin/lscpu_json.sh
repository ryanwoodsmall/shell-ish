#!/bin/bash

lscpu | \
  tr -s ' ' | \
  sed 's/: /" : "/g;s/^/"/g;s/$/",/g' | \
  tr -d '\n' | \
  sed 's/^/{/g;s/$/}/g;s/,}/}/g' | \
  jq -r .
