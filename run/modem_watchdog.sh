#!/bin/bash

# Configurable settings
DEVICE_NAME="${DEVICE_NAME:-USB-4G-Dongle}"
VENDOR_ID="${VENDOR_ID:-2c7c}"
PRODUCT_ID="${PRODUCT_ID:-6005}"
CHECK_INTERVAL="${CHECK_INTERVAL:-30}"

CACHE_DIR="/tmp/usb-watchdog"
CACHE_FILE="$CACHE_DIR/last_known_path"
LOG_TAG="usb-watchdog"

find_usb_path() {
    for dev in /sys/bus/usb/devices/*; do
        if [[ -f "$dev/idVendor" && -f "$dev/idProduct" ]]; then
            vendor=$(cat "$dev/idVendor")
            product=$(cat "$dev/idProduct")
            if [[ "$vendor" == "$VENDOR_ID" && "$product" == "$PRODUCT_ID" ]]; then
                echo "$(basename "$dev")"
                return 0
            fi
        fi
    done
    return 1
}

persist_usb_path() {
    mkdir -p "$CACHE_DIR"
    echo "$1" > "$CACHE_FILE"
}

get_persisted_usb_path() {
    [[ -f "$CACHE_FILE" ]] && cat "$CACHE_FILE" || echo ""
}

reset_usb() {
    local path="$1"
    if [[ -w "/sys/bus/usb/devices/$path/authorized" ]]; then
        echo 0 > "/sys/bus/usb/devices/$path/authorized"
        sleep 1
        echo 1 > "/sys/bus/usb/devices/$path/authorized"
        echo "$DEVICE_NAME - Reset performed on USB device at path $path" | systemd-cat -t "$LOG_TAG"
    else
        echo "$DEVICE_NAME - Could not reset USB device at path $path: insufficient permissions" | systemd-cat -t "$LOG_TAG"
    fi
}

ensure_usb_path() {
    local cache_path
    if [[ -f "$CACHE_FILE" ]]; then
        cache_path="$(cat $CACHE_FILE 2>/dev/null)"
        if [[ -n "$cache_path" && -d "/sys/bus/usb/devices/$cache_path" ]]; then
            # Check if the device is our device
            vendor=$(cat "/sys/bus/usb/devices/$cache_path/idVendor")
            product=$(cat "/sys/bus/usb/devices/$cache_path/idProduct")
            if [[ "$vendor" == "$VENDOR_ID" && "$product" == "$PRODUCT_ID" ]]; then
                return 0
            fi
        fi
    fi

    echo "$DEVICE_NAME - Device not found in cache or not our device, rescanning." | systemd-cat -t "$LOG_TAG"

    local new_path
    new_path=$(find_usb_path)
    if [[ -n "$new_path" ]]; then
        persist_usb_path "$new_path"
        echo "$DEVICE_NAME - Discovered and cached device path: $new_path" | systemd-cat -t "$LOG_TAG"
    else
        echo "$DEVICE_NAME - Device not found during scan" | systemd-cat -t "$LOG_TAG"
    fi
}

main_loop() {
    local path
    while true; do
        # Check if device is present
        lsusb | grep -qi "${VENDOR_ID}:${PRODUCT_ID}"
        if [[ $? -ne 0 ]]; then
            path=$(get_persisted_usb_path)
            if [[ -n "$path" && -d "/sys/bus/usb/devices/$path" ]]; then
                echo "$DEVICE_NAME - Device missing, attempting reset on path $path" | systemd-cat -t "$LOG_TAG"
                reset_usb "$path"
            else
                echo "$DEVICE_NAME - Device missing, but no valid cached path. Skipping reset." | systemd-cat -t "$LOG_TAG"
            fi
        else
            ensure_usb_path
        fi
        sleep "$CHECK_INTERVAL"
    done
}

# Initial setup
ensure_usb_path
main_loop
