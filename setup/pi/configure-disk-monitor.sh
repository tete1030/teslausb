#!/bin/bash

# VENDOR_ID="0781"
# MODEL_ID="55ae"

if [ -z "${DISK_VENDOR_ID+x}" ] || [ -z "${DISK_PRODUCT_ID+x}" ]
then
  echo "USB Disk Monitor not configured." >&2
  exit 1
fi

chmod +x /root/bin/wait_and_reload_gadget.sh

echo 'ACTION=="add|change|remove|bind|unbind", SUBSYSTEM=="usb", ENV{ID_VENDOR_ID}=="'$DISK_VENDOR_ID'", ENV{ID_MODEL_ID}=="'$DISK_PRODUCT_ID'", RUN+="/root/bin/wait_and_reload_gadget.sh"' > /etc/udev/rules.d/99-usb-disk-monitor.rules
udevadm control --reload-rules && udevadm trigger
