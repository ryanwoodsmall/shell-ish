#!/bin/sh

#
# get list of stuff from https://en.wikipedia.org/wiki/List_of_Unix_commands
# see if it's installed
# combine with box-utils.sh and crosware busybox/coreutils/toybox/sbase-box/ubase-box/9base
#

curl -kLs https://en.wikipedia.org/wiki/List_of_Unix_commands \
| sed -n '/<table.*sortable/,/<\/table/p' \
| grep -A1 '^<tr' \
| sed 's#</td>$##g;s#</a>$##g' \
| awk -F'>' '/^<td>/{print $NF}'

# XXX - figure these out not found stuff:
#
# admin - sccs - opt                                                                                                                                                                                         [1/40]
# asa - text - opt
# at - proc_mgmt - mand
# batch - proc_mgmt - mand
# c99 - c_prog - opt (gcc)
# cflow - c_prog - opt
# ctags - c_prog - opt
# cxref - c_prog - opt
# delta - sccs - opt
# fort77 - fort_prog - opt
# get - sccs - opt
# hash - db - mand (bash builtin)
# lex - c_prog - opt (flex)
# lp - text_proc - mand
# m4 - misc - mand (gnu m4)
# mailx - misc - mand
# pax - misc - mand
# prs - proc_mgmt - mand
# qalter - batch - obs
# qdel - batch - obs
# qhold - batch - obs
# qmove - batch - obs
# qmsg - batch - obs
# qrerun - batch - obs
# qrls - batch - obs
# qselect - batch - obs
# qsig - batch - obs
# qstat - batch - obs
# qsub - batch - obs
# rmdel - sccs - opt
# sact - sccs - opt
# sccs - sccs - opt
# talk - misc - opt
# type - misc - opt
# unget - sccs - opt
# uucp - net - opt
# uustat - net - opt
# uux - proc_mgmt - opt
# val - sccs - opt
# what - sccs - opt
#
