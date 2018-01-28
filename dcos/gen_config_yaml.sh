#!/bin/bash

bh="dhcphost"
vms="/opt/scripts/getvmips.sh"

myip="$(ip -f inet -o a | tr -s \  | awk '!/: (lo|docker)/{print $4}' | cut -f1 -d/ | head -1 | xargs echo)"

mc="3"
pubc="1"
hc="$(ssh ${bh} bash ${vms} | grep -v "^${myip}$" | wc -l)"
privc="$((${hc}-(${mc}+${pubc})))"
ms="$(ssh ${bh} bash ${vms} | grep -v "^${myip}$" | head -${mc} | xargs echo | tr ' ' ,)"
pubs="$(ssh ${bh} bash ${vms} | grep -v "^${myip}$" | head -$((${mc}+${pubc})) | tail -${pubc} | xargs echo | tr ' ' ,)"
privs="$(ssh ${bh} bash ${vms} | grep -v "^${myip}$" | tail -${privc} | xargs echo | tr ' ' ,)"

gcd="${HOME}/genconf"
yt="${gcd}/config.yaml.template"
yc="${yt//.template/}"
ipd="${gcd}/ip-detect"
ns="$(awk '/^nameserver/{print $NF}' /etc/resolv.conf | head -1)"

cat ${yt} > ${yc}

sed -i "s#%%MASTERS%%#- ${ms}#g" ${yc}
sed -i "s#%%PUBS%%#- ${pubs}#g" ${yc}
sed -i "s#%%PRIVS%%#- ${privs}#g" ${yc}
sed -i "s#%%NS%%#- ${ns}#g" ${yc}
sed -i "s#%%MYIP%%#${myip}#g" ${yc}
sed -i "s#%%WD%%#${HOME}#g" ${yc}
sed -i "/^-.*,/ s/,/,- /g" ${yc}
tr ',' '\n' < ${yc} > ${yc}.2 && mv ${yc}{.2,}
