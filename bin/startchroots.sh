#!/bin/bash

#
# XXX - WIP
#
# - SELinux should probably be off
# - IPTABLES should probably be off
# - assumes CentOS (RHEL) style chroots (Live CD/DVD work)
# - unsquashfs /mnt/iso/LiveOS/squashfs.img # from the CentOS Live ISO
#   - for RHEL7, an updated squashfs-tools is needed on RHEL6 OS 
# - mount the ext3fs.img ro,loop to /mnt/img
# - rsync /mnt/img to /data/chroot/${CHROOTARCH}-centos-${RHELVER} e.g.:
#   - CentOS 5 i386 : /data/chroot/i686-centos-5
#   - CentOS 6 i386 : /data/chroot/i686-centos-6
#   - CentOS 5 x86_64 : /data/chroot/x86_64-centos-5
#   - CentOS 6 x86_64 : /data/chroot/x86_64-centos-6
#   - CentOS 7 x86_64 : /data/chroot/x86_64-centos-7
# - this assumes a user called "user" exists and has generated and exchanged SSH keys 
# - this assumes an SSH server is running on the host
# - SSH servers are started for each chroot starting at port 22222
# - you should be able to SSH in as "user" assuming your keys previously worked
#

#
# for building RPMs in chroots, something like this will work for ${HOME}/.rpmmacros (substitute 5/6/7)
#
#   %debug_package %{nil}
#   %_enable_debug_packages %{nil}
#   %dist .el5
#   %rhel 5
#   %_topdir %(echo ${HOME})/rpmbuild
#

whoami | grep -q ^root$ || {
	echo "run as root"
	exit 1
}

topdir="/data/chroot"

binddirs="sys proc dev dev/pts dev/shm"

sshport="22222"

user="user"

userhome="$(getent passwd ${user} | cut -d: -f6)"

for chrootdir in $(ls -d ${topdir}/*/) ; do
	chrootdirs+="${chrootdir%%/} "
done

for chrootdir in ${chrootdirs} ; do
	chroot="$(basename "${chrootdir}")"
	chrootarch="${chroot//-*/}"
	echo "setting up ${chroot} in ${chrootdir} for architecture ${chrootarch}"
	for binddir in ${binddirs} ; do
		test -e ${chrootdir}/${binddir} || mkdir -p ${chrootdir}/${binddir}
		mount | grep -q " ${chrootdir}/${binddir} " || mount -o bind /${binddir} ${chrootdir}/${binddir}
	done
	for sshhostkey in /etc/ssh/ssh_host_*_key* ; do
		test -e ${chrootdir}/etc/ssh/$(basename ${sshhostkey}) || cp -a ${sshhostkey} ${chrootdir}/etc/ssh/
	done
	sed -i '/wheel.*NOPASSWD/ s/^#//g' ${chrootdir}/etc/sudoers
	rm -rf ${chrootdir}/etc/mtab
	grep -v ${topdir} /proc/mounts > ${chrootdir}/etc/mtab
	rm -rf ${chrootdir}/etc/resolv.conf
	cat /etc/resolv.conf > ${chrootdir}/etc/resolv.conf
	setarch ${chrootarch} chroot ${chrootdir} id ${user} >/dev/null 2>&1 || setarch ${chrootarch} chroot ${chrootdir} useradd -m -d ${userhome} -G wheel ${user}
	test -e ${chrootdir}/${userhome}/.ssh || cp -a ${userhome}/.ssh ${chrootdir}/${userhome}/
	setarch ${chrootarch} chroot ${chrootdir} chown -R ${user} ${userhome}
	fuser -n tcp ${sshport} >/dev/null 2>&1 || setarch ${chrootarch} chroot ${chrootdir} /usr/sbin/sshd -p ${sshport}
	((sshport+=1))
done
