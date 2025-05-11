#!/bin/bash

# VENDOR_ID="0781"
# MODEL_ID="55ae"

if [ -z "${DISK_VENDOR_ID+x}" ] || [ -z "${DISK_MODEL_ID+x}" ]
then
  echo "USB Disk Monitor not configured." >&2
  exit 1
fi

cat <<- EOF > /root/bin/wait_and_reload_gadget.sh
#!/bin/bash

function log() {
  echo \$1 | systemd-cat -t "wait_and_reload_gadget"
}

case "\$ACTION" in
  add|change)
    log "[UDEV] USB device \$ACTION (Vendor=\$ID_VENDOR_ID, Product=\$ID_MODEL_ID)"
    sleep 1
    if ! mountpoint -q /backingfiles ; then
      log "/backingfiles not found after udev event"
      exit 1
    fi
  
    /root/bin/disable_gadget.sh
    sleep 1
    /root/bin/enable_gadget.sh
    ;;
  remove)
    log "[UDEV] USB device \$ACTION (Vendor=\$ID_VENDOR_ID, Product=\$ID_MODEL_ID)"
    /root/bin/disable_gadget.sh
    ;;
  bind|unbind)
    log "[UDEV] USB device \$ACTION (Vendor=\$ID_VENDOR_ID, Product=\$ID_MODEL_ID)"
    ;;
  *)
    log "[UDEV] Unhandled action: \$ACTION (Vendor=\$ID_VENDOR_ID, Product=\$ID_MODEL_ID)"
    ;;
esac

EOF

chmod +x /root/bin/wait_and_reload_gadget.sh

echo 'ACTION=="add|change|remove|bind|unbind", SUBSYSTEM=="usb", ENV{ID_VENDOR_ID}=="'$DISK_VENDOR_ID'", ENV{ID_MODEL_ID}=="'$DISK_MODEL_ID'", RUN+="/root/bin/wait_and_reload_gadget.sh"' > /etc/udev/rules.d/99-usb-disk-monitor.rules
udevadm control --reload-rules

