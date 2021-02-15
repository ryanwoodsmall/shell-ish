#!/usr/bin/env bash

/bin/echo -n "$(/bin/date) : "
/sbin/ifconfig wlan0 | /bin/grep -q 'inet ' || {
  /bin/echo -n 'resetting... '
  /sbin/rmmod -f brcmfmac
  /sbin/modprobe brcmfmac
}
/bin/echo 'done'
/sbin/iw dev wlan0 set power_save off >/dev/null 2>&1
