#!/bin/bash

#
# setup a simple alpine chroot based on their mini root filesystem archives
#
# if you have docker, use that instead
#
# alpine chroot stuff:
#  https://wiki.alpinelinux.org/wiki/Installing_Alpine_Linux_in_a_chroot
#  https://github.com/alpinelinux/alpine-chroot-install  

# options
#  -n name
#  -v version
#  -i inst (top) dir
#  -p port

# maybe
#  -u user to create
#  -a arch (needs qemu-$arch, not yet?)
#  -d download dir

# commands
#  setup
#   download
#   checksum
#   extract
#   chmod 755 / /home
#   chroot apk update
#   chroot apk upgrade
#   chroot apk add stuff
#  start
#   make bind mount directories
#   do bind mounts
#   start ssh? 
#  stop
#   kill ssh?
#   unmount bind mounts

# todo
#  user creation?
#  ssh key exchange?

# we'll use this a few times
scriptname="${BASH_SOURCE[0]}"
function scriptecho() {
  echo "${scriptname}: ${@}"
}

# default versions/names/arch
chrname="alpine"
alpver="3.7.0"
alparch="$(uname -m | sed 's/^\(arm\).*/\1hf/g')"
sshport="22222"

# where to download and install
dldir="/tmp"
instdir="/usr/local"

# system/bind mount stuff
erc="etc/resolv.conf"
bmds=( dev dev/pts dev/shm proc sys )
bmfs=( ${erc} )

# help/usage options
declare -A opt_help
opt_help["n"]="name : chroot name, default '${chrname}'"
opt_help["v"]="X.Y.Z : alpine version, default '${alpver}'"
opt_help["i"]="/path : top dir for chroot, default '${instdir}'"
opt_help["p"]="##### : dropbear ssh port for the chroot, default '${sshport}'"

# and commands
declare -A cmd_help
cmd_help["setup"]="download, extract and configure a new chroot"
cmd_help["start"]="setup chroot bind mounts"
cmd_help["stop"]="unmount chroot bind mounts"
cmd_help["startssh"]="start dropbear ssh in the chroot"
cmd_help["stopssh"]="stop dropbear ssh in the chroot"
cmd_help["status"]="dump bind mount status for the chroot"
cmd_help["update"]="upgrade packages in existing chroot via apk"

# get that help
function usage() {
  echo "usage:"
  echo
  echo "  ${scriptname} <opt> <opt> command"
  echo
  echo "  this script will download, configure, start and stop alpine chroots"
  echo "  by default an alpine ${alpver} chroot will be installed at ${instdir}/${chrname}"
  echo
  echo "options:"
  for opt in ${!opt_help[@]} ; do
    echo "  -${opt} ${opt_help[${opt}]}"
  done
  echo
  echo "commands:"
  for cmd in ${!cmd_help[@]} ; do
    echo "  ${cmd} : ${cmd_help[${cmd}]}"
  done
  echo
}

# we need at least one command
if [ ${#} -le 0 ] ; then
  scriptecho "please provide exactly one command"
  echo
  usage
  exit 1
fi

# want to be able to run help without root
if [[ ${@} =~ -h ]] ; then
  usage
  exit 1
fi

# check for root
whoami | grep -qi '^root$' || {
  scriptecho "please run this as the root user"
  exit 1
}

# parse options
optcount=0
while getopts ":n:v:i:p:h" opt ; do
  case ${opt} in
    n)
      chrname="${OPTARG}"
      ((optcount++))
      ;;
    v)
      alpver="${OPTARG}"
      ((optcount++))
      ;;
    i)
      instdir="${OPTARG}"
      ((optcount++))
      ;;
    p)
      sshport="${OPTARG}"
      ((optcount++))
      ;;
    h)
      usage
      exit
      ;;
    :)
      scriptecho "-${OPTARG} requires an argument"
      exit 1
      ;;
    \?)
      scriptecho "invalid option -${OPTARG}"
      exit 1
      ;;
  esac
done

# we should only have one more thing left - our command
shift $((${optcount}*2))
if [ ${#} -ne 1 ] ; then
  scriptecho "please provide exactly one commnad"
  echo
  usage
  exit 1
fi

# our script command is the "last" thing on the stack
command="${1}"

# split versions apart
vermaj="${alpver%%.*}"
vermin="${alpver#*.}"
vermin="${vermin%%.*}"

# form dl url/file and sha256 sum file
alpminirootarurl="http://dl-cdn.alpinelinux.org/alpine/v${vermaj}.${vermin}/releases/${alparch}/alpine-minirootfs-${alpver}-${alparch}.tar.gz"
alpminirootarsha256="${alpminirootarurl}.sha256"
alpminirootar="$(basename ${alpminirootarurl})"

# we'll use these multiple times
dlfile="${dldir}/${alpminirootar}"
chrdir="${instdir}/${chrname}"

# download/checksum functions
function download() {
  scriptecho "downloading ${alpminirootarurl} to ${dlfile}"
  curl -k -L -o ${dlfile} ${alpminirootarurl}
  test -e "${dlfile}" || {
    scriptecho "download of ${dlfile} failed"
    exit 1
  }
}

function checksum() {
  scriptecho "checksumming ${dlfile}"
  local storedsum="$(curl -kLs ${alpminirootarsha256} | awk '{print $1}')"
  local localsum="$(sha256sum ${dlfile} | awk '{print $1}')"
  if [ ! ${storedsum} == ${localsum} ] ; then
     scriptecho "${dlfile} failed sha256sum"
    exit
  fi
}

# setup
function chrsetup() {
  test -e "${chrdir}" && {
    scriptecho "${chrdir} already exists; cowardly failing"
    exit 1
  }
  download
  checksum
  mkdir -p "${chrdir}"
  test -e "${chrdir}" || {
    scriptecho "it does not appear we can create ${chrdir}"
    exit 1
  }
  scriptecho "extracting ${dlfile} into ${chrdir}"
  tar --directory "${chrdir}" -zxf "${dlfile}"
  scriptecho "fixing up ${chrdir} and ${chrdir}/home perms"
  chmod 755 ${chrdir} ${chrdir}/home
  scriptecho "creating bind mount directories: ${bmds[@]}"
  for bmd in ${bmds[@]} ; do
    mkdir -p ${chrdir}/${bmd}
  done
  scriptecho "creating bind mount files: ${bmfs[@]}"
  for bmf in ${bmfs[@]} ; do
    touch ${chrdir}/${bmf}
  done
  echo
  scriptecho "run '${scriptname} -n ${chrname} start' to bind mount directories"
  scriptecho "you can enter the chroot with 'sudo chroot ${chrdir} /bin/ash -l'"
  scriptecho "run '${scriptname} -n ${chrname} stop' to unmount bound directories"
  echo
}

# start
function chrstart() {
  test -e "${chrdir}" || {
    scriptecho "${chrdir} chroot does not seem to exist"
    exit 1
  }
  for bm in ${bmds[@]} ${bmfs[@]} ; do
    mount | grep -q " ${chrdir}/${bm} " && {
      scriptecho "${chrdir}/${bm} already bind mounted"
      continue
    }
    scriptecho "bind mounting ${bm}"
    mount -o bind /${bm} ${chrdir}/${bm}
  done
}

# stop
function chrstop() {
  test -e "${chrdir}" || {
    scriptecho "${chrdir} chroot does not seem to exist"
    exit 1
  }
  chrstopssh
  mount | grep "${chrdir}" | awk '{print $3}' | tac | while read -r bm ; do
    scriptecho "attempting unmount of ${bm}"
    sudo umount -f "${bm}"
  done 
}

# startssh
function chrstartssh() {
  test -e "${chrdir}" || {
    scriptecho "${chrdir} chroot does not seem to exist"
    exit 1
  }
  chrstart # should be safe to run
  mkdir -p "${chrdir}/etc/dropbear"
  test -e "${chrdir}/etc/dropbear" || {
    scriptecho "could not create dropbear keys directory in chroot"
    exit 1
  }
  chroot "${chrdir}" /sbin/apk update
  test -e "${chrdir}/usr/sbin/dropbear" || {
    scriptecho "installing dropbear"
    chroot "${chrdir}" /sbin/apk add dropbear dropbear-scp dropbear-dbclient dropbear-convert dropbear-ssh psmisc
  }
  chroot "${chrdir}" /usr/sbin/dropbear -B -R -p ${sshport}
}

# stop ssh in the chroot
function chrstopssh() {
  test -e "${chrdir}" || {
    scriptecho "${chrdir} chroot does not seem to exist"
    exit 1
  }
  sshpid="$(chroot "${chrdir}" /usr/bin/fuser -n tcp ${sshport} 2>/dev/null)"
  if [ ! -z "${sshpid}" ] ; then
    kill -KILL ${sshpid}
  fi
}

# update/upgrade via apk
function chrupdate() {
  test -e "${chrdir}" || {
    scriptecho "${chrdir} chroot does not seem to exist"
    exit 1
  }
  chrstart # should be safe to run
  chroot "${chrdir}" /sbin/apk update
  chroot "${chrdir}" /sbin/apk upgrade
}

# just dump our bind mount status for now
function chrstatus() {
  test -e "${chrdir}" || {
    scriptecho "${chrdir} chroot does not seem to exist"
    exit 1
  }
  for bm in ${bmds[@]} ${bmfs[@]} ; do
    mount | grep -q " ${chrdir}/${bm} " || {
      scriptecho "${chrdir}/${bm} does not appear to be bind mounted"
    }
  done
}

case ${command} in
  setup)
    chrsetup
    ;;
  start)
    chrstart
    ;;
  stop)
    chrstop
    ;;
  startssh)
    chrstartssh
    ;;
  stopssh)
    chrstopssh
    ;;
  status)
    chrstatus
    ;;
  update)
    chrupdate
    ;;
  *)
    scriptecho "command ${command} not understood"
    echo
    usage
    exit 1
    ;;
esac