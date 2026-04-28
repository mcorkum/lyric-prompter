#!/bin/bash
# ============================================================
#  pedal-connect.sh
#  Boot-time helper: reconnects the paired Bluetooth pedal.
#  Reads the MAC from ~/.lyric-prompter-pedal and retries up
#  to ~45s, since the BT stack on Pi can be slow to come up
#  and the pedal may be off at boot.
#  Called from pedal-connect.service — not run directly.
# ============================================================

PEDAL_FILE="$HOME/.lyric-prompter-pedal"
[ ! -f "$PEDAL_FILE" ] && exit 0
MAC="$(tr -d '[:space:]' < "$PEDAL_FILE")"
[ -z "$MAC" ] && exit 0

# Wait a moment for bluetoothd to be ready
sleep 5

for i in $(seq 1 12); do
  echo "connect $MAC" | bluetoothctl > /dev/null 2>&1
  sleep 2
  if bluetoothctl info "$MAC" 2>/dev/null | grep -q "Connected: yes"; then
    exit 0
  fi
  sleep 2
done

# Pedal probably off. Don't fail the unit — let the user power it on later.
exit 0
