#!/bin/bash

IP="$(ip -f inet -o a | tr '/' ' ' | tr -s ' ' | egrep -v ': (docker|veth|virbr|lo)' | cut -f4 -d' ' | head -1)"
export OLDPS1="${PS1}"
export PS1='\u@'${IP}':\w\$ '
unset IP
