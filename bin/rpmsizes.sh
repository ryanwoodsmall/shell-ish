#!/bin/bash
for instrpm in $(rpm -qa) ; do
  rpm -qi ${instrpm} \
  | awk '/Size/{print $3}' \
  | sed "s/\$/ : ${instrpm}/g"
done | sort -n
