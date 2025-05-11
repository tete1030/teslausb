#!/bin/bash

# MODEM_VENDOR_ID="2c7c"
# MODEM_PRODUCT_ID="6005"

if [ -z "${MODEM_VENDOR_ID}" ] || [ -z "${MODEM_PRODUCT_ID}" ]
then
  echo "Modem device not configured." >&2
  exit 1
fi

cat > /etc/polkit-1/rules.d/50-modemmanager.rules << 'EOF'
polkit.addRule(function(action, subject) {
  if (action.id == "org.freedesktop.ModemManager1.Messaging" &&
      subject.user == "www-data") {
    return polkit.Result.YES;
  }
});
EOF

cat > /etc/udev/rules.d/77-ignore-4g-modem.rules << EOF
# Ignore this 4G USB dongle entirely from ModemManager
# ATTRS{idVendor}=="$MODEM_VENDOR_ID", ATTRS{idProduct}=="$MODEM_PRODUCT_ID", ENV{ID_MM_DEVICE_IGNORE}="1"
SUBSYSTEM=="net", KERNEL=="usb*", ENV{ID_USB_DRIVER}=="cdc_ether", \
  ENV{ID_VENDOR_ID}=="$MODEM_VENDOR_ID", ENV{ID_MODEL_ID}=="$MODEM_PRODUCT_ID", \
  ENV{ID_MM_DEVICE_IGNORE}="1"
# SUBSYSTEM=="net", KERNEL=="usb0", ENV{ID_MM_DEVICE_IGNORE}="1"
EOF

cat > /etc/default/modem-watchdog << EOF
MODEM_VENDOR_ID="$MODEM_VENDOR_ID"
MODEM_PRODUCT_ID="$MODEM_PRODUCT_ID"
EOF

cat > /etc/systemd/system/modem-watchdog.service << 'EOF'
[Unit]
Description=Modem Watchdog Service
After=local-fs.target sysfs.target

[Service]
Type=simple
ExecStart=/root/bin/modem_watchdog.sh
Restart=always
RestartSec=10
User=root
EnvironmentFile="/etc/default/modem-watchdog"

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl restart polkit

udevadm control --reload-rules && udevadm trigger

chmod +x /root/bin/modem_watchdog.sh
systemctl daemon-reload && systemctl enable --now modem-watchdog.service
