#!/bin/bash

whoami | grep -qi ^root$ || {
  echo "please run as root"
  exit 1
}

which -a ipcalc >/dev/null 2>/dev/null || {
  echo "no ipcalc found"
  exit 1
}

netstat -rn | awk '/tun/{print $1"/"$3}' | while read r ; do
  p=$(ipcalc -p $(echo $r | tr / \ ) | cut -f2 -d=)
  echo "deleting $r"
  if [ $p -lt 32 ] ; then
    route del -net ${r//\/*/}/$p
  else
    route del -host ${r//\/*/}/$p
  fi
done
