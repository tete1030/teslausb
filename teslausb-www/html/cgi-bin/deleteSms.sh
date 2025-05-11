#!/bin/bash
# deleteSms.sh - Delete an SMS message from the modem using mmcli
# Usage: deleteSms.sh?modem=<modem_index>&sms=<sms_index>

# Output JSON content type header
echo "Content-Type: application/json"
echo ""

# Parse query string for modem and sms indices
QUERY_STRING="$QUERY_STRING"
if [ -z "$QUERY_STRING" ]; then
  QUERY_STRING="$1"
fi

modem=""
sms=""
IFS='&' read -ra params <<< "$QUERY_STRING"
for param in "${params[@]}"; do
  key="${param%%=*}"
  value="${param#*=}"
  case "$key" in
    modem)
      modem="$value"
      ;;
    sms)
      sms="$value"
      ;;
  esac
done

if [ -z "$modem" ] || [ -z "$sms" ]; then
  echo '{"success":false, "error":"Missing modem or sms parameter"}'
  exit 1
fi

# Delete the SMS using mmcli
if mmcli -m "$modem" --messaging-delete-sms="$sms" 2>&1 | grep -q 'successfully deleted'; then
  echo '{"success":true}'
else
  err=$(mmcli -m "$modem" --messaging-delete-sms="$sms" 2>&1)
  echo '{"success":false, "error":"'$(echo "$err" | head -n 1 | sed 's/"/\\"/g')'"}'
  exit 1
fi
