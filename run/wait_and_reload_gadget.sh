#!/bin/bash

function log() {
  echo $1 | systemd-cat -t "wait_and_reload_gadget"
}

case "$ACTION" in
  add|change)
    log "[UDEV] USB device $ACTION (Vendor=$ID_VENDOR_ID, Product=$ID_MODEL_ID)"
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
    log "[UDEV] USB device $ACTION (Vendor=$ID_VENDOR_ID, Product=$ID_MODEL_ID)"
    /root/bin/disable_gadget.sh
    ;;
  bind|unbind)
    log "[UDEV] USB device $ACTION (Vendor=$ID_VENDOR_ID, Product=$ID_MODEL_ID)"
    ;;
  *)
    log "[UDEV] Unhandled action: $ACTION (Vendor=$ID_VENDOR_ID, Product=$ID_MODEL_ID)"
    ;;
esac

