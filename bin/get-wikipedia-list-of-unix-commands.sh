#!/bin/sh

#
# get list of stuff from https://en.wikipedia.org/wiki/List_of_Unix_commands
#
# see if it's installed, combine with box-utils.sh and crosware busybox/coreutils/toybox/sbase-box/ubase-box/9base
#

# XXX - lsb? http://refspecs.linuxfoundation.org/LSB_5.0.0/LSB-Common/LSB-Common/rcommands.html
# XXX - better source for sus? posix? free ones?

curl -kLs https://en.wikipedia.org/wiki/List_of_Unix_commands \
| sed -n '/<table.*sortable/,/<\/table/p' \
| grep -A1 '^<tr' \
| sed 's#</td>$##g;s#</a>$##g' \
| awk -F'>' '/^<td>/{print $NF}'

# XXX - figure these out not found stuff:
#
# asa - text - opt
# at - proc_mgmt - mand
# batch - proc_mgmt - mand
# fort77 - fort_prog - opt (gcc/g77)
# lp - text_proc - mand
# mailx - misc - mand
# pax - misc - mand
# talk - misc - opt
# uucp - net - opt
# uustat - net - opt
# uux - proc_mgmt - opt
#
