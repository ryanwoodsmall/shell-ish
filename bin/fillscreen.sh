#!/bin/bash

a=( '-' '\' '|' '/' )

i=0
while true ; do
 echo -n ${a[${i}]}
 if [ $i -lt $((${#a[@]}-1)) ] ; then
   ((i++))
 else
   i=0
 fi
 usleep 100
done
