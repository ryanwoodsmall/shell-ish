#!/bin/bash

#
# qemu-arm should be static
#
# to unmount chroot use:
#
#   umount /opt/chroot/raspbian/{dev{/{pts,shm},},sys,proc,etc/resolv.conf,boot,}
#   kpartx -d blah
#   losetup -d blah
#
# see:
#   https://gist.github.com/mikkeloscar/a85b08881c437795c1b9
#   https://github.com/mikkeloscar/binfmt-manager
#

rimg="/opt/chroot/img/2017-04-10-raspbian-jessie-lite.img"
rmnt="/opt/chroot/raspbian"
qemu="/opt/qemu/current/bin/qemu-arm"
bfmt="/proc/sys/fs/binfmt_misc"
bfmtarm="${bfmt}/arm"
bfmtreg="${bfmt}/register"
rpart="2"
bpart="1"

whoami | grep -q ^root$ || {
  echo "please run this as root"
  exit 1
}

lsmod | grep -q binfmt_misc || \
  modprobe binfmt_misc

grep -q ${qemu} ${bfmtarm} >/dev/null 2>&1 || \
  echo ':arm:M::\x7fELF\x01\x01\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x02\x00\x28\x00:\xff\xff\xff\xff\xff\xff\xff\x00\xff\xff\xff\xff\xff\xff\xff\xff\xfe\xff\xff\xff:'${qemu}':' > ${bfmtreg}

losetup -a 2>&1 | grep -q ${rimg} || \
  losetup -v -f ${rimg}

lodev="$(losetup -a | grep ${rimg} | awk -F: '{print $1}')"
if [[ ! ${lodev} =~ ^/dev/loop ]] ; then
  echo "loop device for ${rimg} missing; giving up"
  exit 1
fi
bdev="/dev/mapper/$(basename ${lodev})p${bpart}"
rdev="/dev/mapper/$(basename ${lodev})p${rpart}"

test -e ${rdev} || {
  kpartx -v -a ${lodev}
}
test -e ${rdev} || {
  echo "mapper dev ${rdev} not found; giving up"
  exit 1
}

mount | grep -q " on ${rmnt}" || \
  mount -o noatime ${rdev} ${rmnt}

mount | grep -q " on ${rmnt}/boot" || \
  mount ${bdev} ${rmnt}/boot

for d in dev dev/pts dev/shm sys proc etc/resolv.conf ; do
  mount | grep -q "${rmnt}/${d}" || \
    mount -o bind /${d} ${rmnt}/${d}
done

rm -f ${rmnt}/etc/mtab
ln -sf /proc/mounts ${rmnt}/etc/mtab

sed -i '/^\// s/^/#/g' ${rmnt}/etc/ld.so.preload

mkdir -p ${rmnt}/$(dirname ${qemu})
cp -a ${qemu} ${rmnt}/$(dirname ${qemu})
