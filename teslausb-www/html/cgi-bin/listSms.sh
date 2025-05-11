#!/bin/bash
# CGI script to list all SMS from all modems using ModemManager (mmcli)
# Outputs JSON HTTP response, using mmcli -J for correct structure

echo "Content-Type: application/json"
echo ""

# Find all modem paths
devices=$(mmcli -L | grep -o '/org/freedesktop/ModemManager1/Modem/[0-9]\+')

first_modem=true
printf '{"modems": ['

for modem in $devices; do
  # Get modem index (the last number in the path)
  modem_index=$(echo "$modem" | grep -o '[0-9]\+$')
  
  # List SMS for this modem
  sms_list=$(mmcli -m $modem_index --messaging-list-sms 2>/dev/null | grep -o '/org/freedesktop/ModemManager1/SMS/[0-9]\+')
  
  if [ "$first_modem" = false ]; then
    printf ','
  fi
  first_modem=false
  printf '\n  {"modem_index": %s, "sms": [' "$modem_index"
  first_sms=true
  for sms in $sms_list; do
    sms_index=$(echo "$sms" | grep -o '[0-9]\+$')
    # Get SMS details as JSON
    sms_json=$(mmcli -s $sms_index -J 2>/dev/null | jq -c '.sms')
    if [ "$first_sms" = false ]; then
      printf ','
    fi
    first_sms=false
    printf '\n    {"sms_index": %s, "details": %s}' "$sms_index" "$sms_json"
  done
  printf '\n  ]}'
done
printf '\n]}'
