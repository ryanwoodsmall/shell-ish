#!/bin/bash

#
# use openwrt/lede luci json rpc to get ip(s) matching a pattern
# 
#   https://github.com/openwrt/luci/wiki/JsonRpcHowTo
#
# i.e., use tmux-nodes to ssh as "pi" user
#   tmux-nodes.sh $(thisscript | sed 's/^/pi@/g')
# *or*
#   env TMUX_NODES_CMD="ssh -l pi" tmux-nodes.sh $(thisscript)
#

read -p "host: " host
read -p "match: " match
read -p "user: " user
read -s -p "pass: " pass

copts="-k -L -s"
url="http://${host}/cgi-bin/luci"
rpc="${url}/rpc"

authjson=''
authjson+='{ "method": "login", "params": [ "'
authjson+="${user}"
authjson+='", "'
authjson+="${pass}"
authjson+='" ] }'

tok="$(curl ${copts} ${rpc}/auth --data "${authjson}" | jq -r .result)"

curl ${copts} "${rpc}/sys?auth=${tok}" --data '{ "method": "net.ipv4_hints" }' \
| jq -r '.result[]|.[]' \
| grep -B1 "${match}" \
| egrep -vi "^(${match}|--)"
