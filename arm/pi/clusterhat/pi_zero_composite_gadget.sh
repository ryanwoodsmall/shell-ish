#!/bin/bash

#
# WIP Raspberry Pi Zero composite USB gadget setup; provides:
#  - ttyGS0 serial console
#  - usb0 NIC
#
# add this to /boot/config.txt
#   dtoverlay=dwc2
#
# throw this script into /opt/scripts, then set it to run at boot vi /etc/rc.local
#   chmod 755 /opt/script/pi_zero_composite_gadget.sh
#   cp /etc/rc.local{,.ORIG}
#   sed -i '/^exit 0/d' /etc/rc.local
#   echo "/opt/scripts/pi_zero_composite_gadget.sh" >> /etc/rc.local
#
# enable the console with:
#  systemctl enable getty@ttyGS0.service
#  systemctl start  getty@ttyGS0.service
#
# NIC works, should be usb#
#
# installation/systemd integration necessary too
#
# see:
#  pi:
#    http://isticktoit.net/?p=1383
#    http://irq5.io/2016/12/22/raspberry-pi-zero-as-multiple-usb-gadgets/
#    https://github.com/wismna/HackPi
#  beagle:
#    https://github.com/RobertCNelson/boot-scripts/blob/master/boot/omap3_beagle.sh
#    https://github.com/RobertCNelson/boot-scripts/blob/master/boot/am335x_evm.sh
#    https://github.com/RobertCNelson/boot-scripts/blob/master/boot/autoconfigure_usb0.sh
#

kmods="dwc2 libcomposite"

gadget="pi0composite"
gadgetdir="/sys/kernel/config/usb_gadget/${gadget}"

serialcons="ttyGS0"
conssvc="getty@${serialcons}.service"

usbnic="usb0"
iffile="/etc/network/interfaces"

loopback="127.1.1.1"
hosts="/etc/hosts"
hnpref="pizero"

sn="$(cat /proc/device-tree/serial-number | xargs -0 echo -n)"
mn="$(cat /proc/device-tree/model | xargs -0 echo -n)"
echo "my serial number is: ${sn}"
echo "my model name is: ${mn}"

for kmod in ${kmods} ; do
  lsmod | grep -q ${kmod} || modprobe ${kmod}
done

mkdir -p ${gadgetdir}

echo "0x1d6b" > ${gadgetdir}/idVendor # Linux Foundation
echo "0x0104" > ${gadgetdir}/idProduct # Multifunction Composite Gadget
echo "0x0100" > ${gadgetdir}/bcdDevice # v1.0.0
echo "0x0200" > ${gadgetdir}/bcdUSB # USB2

mkdir -p ${gadgetdir}/strings/0x409

echo "Raspberry Pi Foundation" > ${gadgetdir}/strings/0x409/manufacturer
echo "${sn}" > ${gadgetdir}/strings/0x409/serialnumber
echo "${mn}" > ${gadgetdir}/strings/0x409/product

mkdir -p ${gadgetdir}/configs/c.1/strings/0x409
echo "Multifunction with RNDIS" > ${gadgetdir}/configs/c.1/strings/0x409/configuration

echo "250" > ${gadgetdir}/configs/c.1/MaxPower

mkdir -p ${gadgetdir}/functions/rndis.usb0
mkdir -p ${gadgetdir}/functions/acm.usb0

HOST=$(echo "${sn}" | md5sum | sed 's/^\(..\)\(..\)\(..\)\(..\)\(..\).*$/02:\1:\2:\3:\4:\5/')
SELF=$(echo "${sn} ${mn}" | md5sum | sed 's/^\(..\)\(..\)\(..\)\(..\)\(..\).*$/02:\1:\2:\3:\4:\5/')
echo ${HOST} > ${gadgetdir}/functions/rndis.usb0/host_addr
echo ${SELF} > ${gadgetdir}/functions/rndis.usb0/dev_addr
echo "host mac is ${HOST}"
echo "self mac is ${SELF}"

ln -sf ${gadgetdir}/functions/acm.usb0 ${gadgetdir}/configs/c.1/
ln -sf ${gadgetdir}/functions/rndis.usb0 ${gadgetdir}/configs/c.1/

ls /sys/class/udc > ${gadgetdir}/UDC
echo "made it through gadget setup"

newhostname="${hnpref}-${SELF//:/}"
sed -i "/${newhostname}/d" ${hosts}
echo "${loopback} ${newhostname}" >> ${hosts}
hostname ${newhostname}
echo "my new hostname should be ${newhostname}"

# XXX - startup doesn't work on first boot, just enable console for now and it will come up on subsequent boots
#systemctl | grep -q "${conssvc}.*running" || {
  systemctl enable ${conssvc}
  #systemctl start  ${conssvc}
#}
echo "made it through ${serialcons} setup"

grep -q ${usbnic} ${iffile} || {
  cp ${iffile}{,.ORIG}
  echo >> ${iffile}
  echo "allow-hotplug ${usbnic}" >> ${iffile}
  echo "auto ${usbnic}" >> ${iffile}
  echo "iface ${usbnic} inet dhcp" >> ${iffile}
}
systemctl restart networking.service
echo "made it through network restart"

echo "made it through gadget setup script"
