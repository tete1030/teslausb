#!/bin/bash

cat > /etc/modprobe.d/disable-brcm-dump-obss.conf << EOF
# https://github.com/raspberrypi/linux/issues/6049#issuecomment-2485431104
options brcmfmac feature_disable=0x200000
EOF
