#!/bin/bash

# Sample output:
# modem_status,imei=867936077005400,icc=89860123801352133387,imsi=460012150436266,operatorid=46001,phone_number=+8615502151102 power_state="On",cellid="",lac="",tac="",registered=false,connected=false,state="Enabled",operatorcode=0,roaming=false,regstate="Idle",packet_service_state="Detached",signal_quality=0,signal_quality_recent=true,message_count=9 1746961940471213533
# modem_signal,imei=867936077005400,icc=89860123801352133387,imsi=460012150436266,operatorid=46001,phone_number=+8615502151102,signaltype=Gsm rssi=-53.000000,ber=0.000000 1746961940471213533
# modem_signal,imei=867936077005400,icc=89860123801352133387,imsi=460012150436266,operatorid=46001,phone_number=+8615502151102,signaltype=Lte rssi=0.000000,rsrp=-84.000000,rsrq=-14.000000,snr=0.000000,ber=0.000000 1746961940471213533

DATA=$(curl -s http://localhost:9898/influx)

STATUS_LINE=$(echo "$DATA" | grep 'modem_status' | head -n1)
IMEI=$(echo "$STATUS_LINE" | awk -F'imei=' '{print $2}' | awk -F',' '{print $1}')
ICCID=$(echo "$STATUS_LINE" | awk -F'icc=' '{print $2}' | awk -F',' '{print $1}')
IMSI=$(echo "$STATUS_LINE" | awk -F'imsi=' '{print $2}' | awk -F',' '{print $1}')
OPERATORID=$(echo "$STATUS_LINE" | awk -F'operatorid=' '{print $2}' | awk -F',' '{print $1}')
PHONE_NUMBER=$(echo "$STATUS_LINE" | awk -F'phone_number=' '{print $2}' | awk '{print $1}')

POWER_STATE=$(echo "$STATUS_LINE" | awk -F'power_state=' '{print $2}' | awk -F',' '{print $1}' | tr -d '"')
CELL_ID=$(echo "$STATUS_LINE" | awk -F'cellid=' '{print $2}' | awk -F',' '{print $1}' | tr -d '"')
LAC=$(echo "$STATUS_LINE" | awk -F'lac=' '{print $2}' | awk -F',' '{print $1}' | tr -d '"')
TAC=$(echo "$STATUS_LINE" | awk -F'tac=' '{print $2}' | awk -F',' '{print $1}' | tr -d '"')
STATE=$(echo "$STATUS_LINE" | awk -F',state=' '{print $2}' | awk -F',' '{print $1}' | tr -d '"')
REGSTATE=$(echo "$STATUS_LINE" | awk -F'regstate=' '{print $2}' | awk -F',' '{print $1}' | tr -d '"')
PACKET_SERVICE_STATE=$(echo "$STATUS_LINE" | awk -F'packet_service_state=' '{print $2}' | awk -F',' '{print $1}' | tr -d '"')
SIGNAL_QUALITY=$(echo "$STATUS_LINE" | awk -F'signal_quality=' '{print $2}' | awk -F',' '{print $1}')
SIGNAL_QUALITY_RECENT=$(echo "$STATUS_LINE" | awk -F'signal_quality_recent=' '{print $2}' | awk -F',' '{print $1}')
SMS_COUNT=$(echo "$STATUS_LINE" | awk -F'message_count=' '{print $2}' | awk '{print $1}')


# Extract values from GSM line
GSM_LINE=$(echo "$DATA" | grep 'modem_signal' | grep 'signaltype=Gsm' | head -n1)
RSSI=$(echo "$GSM_LINE" | awk -F'rssi=' '{print $2}' | awk -F',' '{print $1}')

# Print as JSON
cat << EOF
HTTP/1.0 200 OK
Content-type: application/json

{
  "imei": "$IMEI",
  "icc": "$ICCID",
  "imsi": "$IMSI",
  "operatorid": "$OPERATORID",
  "phone_number": "$PHONE_NUMBER",
  "power_state": "$POWER_STATE",
  "cell_id": "$CELL_ID",
  "lac": "$LAC",
  "tac": "$TAC",
  "state": "$STATE",
  "regstate": "$REGSTATE",
  "packet_service_state": "$PACKET_SERVICE_STATE",
  "signal_quality": "$SIGNAL_QUALITY",
  "signal_quality_recent": "$SIGNAL_QUALITY_RECENT",
  "sms_count": "$SMS_COUNT",
  "rssi": "$RSSI"
}
EOF
