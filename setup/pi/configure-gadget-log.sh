#!/bin/bash

cat <<- EOF > /etc/modprobe.d/usb-gadget.conf
options usb_f_mass_storage dyndbg="file drivers/usb/gadget/* +p"
options dwc3 dyndbg="file drivers/usb/dwc3/* +p"
EOF
