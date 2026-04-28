#!/bin/bash
# ============================================================
#  Lyric Prompter — Bluetooth Foot Pedal Setup
#  Optional. Run only if you have a BT page-turner pedal.
#    bash setup-pedal.sh
#
#  Safe to re-run any time — re-pairs the pedal and rewrites
#  the auto-reconnect service. Use it to fix a stuck pedal
#  or to swap to a different pedal.
# ============================================================
set -e

echo ""
echo "╔══════════════════════════════════════╗"
echo "║   🦶  Bluetooth Pedal Setup          ║"
echo "╚══════════════════════════════════════╝"
echo ""

# ── 1. Make sure Bluetooth is up ─────────────────────────────
echo "▶ Enabling Bluetooth..."
sudo systemctl enable --now bluetooth
sleep 1

# ── 2. Scan for the pedal ────────────────────────────────────
echo "▶ Scanning for devices (15s)..."
echo "   Put the pedal in pairing mode now"
echo "   (hold both buttons until the LED flashes blue)."
echo ""

{
  echo "power on"
  echo "agent on"
  echo "default-agent"
  echo "scan on"
  sleep 15
  echo "scan off"
  echo "devices"
  echo "quit"
} | bluetoothctl > /tmp/pedal-scan.txt 2>&1

echo "▶ Devices found:"
grep "^Device " /tmp/pedal-scan.txt | nl
echo ""

read -rp "Enter the MAC address of your pedal (e.g. AA:BB:CC:DD:EE:FF): " MAC
if ! [[ "$MAC" =~ ^([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}$ ]]; then
  echo "   ⚠ Invalid MAC address. Aborting." >&2
  exit 1
fi
MAC="${MAC^^}"   # uppercase for consistency

# ── 3. Pair, trust, connect ──────────────────────────────────
echo "▶ Pairing, trusting, and connecting..."
{
  echo "pair $MAC"
  sleep 3
  echo "trust $MAC"
  sleep 1
  echo "connect $MAC"
  sleep 2
  echo "quit"
} | bluetoothctl

echo "$MAC" > "$HOME/.lyric-prompter-pedal"
echo "   ✓ Saved MAC to ~/.lyric-prompter-pedal"

# ── 4. Auto-reconnect systemd unit ───────────────────────────
HELPER="$HOME/lyric-prompter/pedal-connect.sh"
if [ ! -x "$HELPER" ]; then
  if [ -f "$HELPER" ]; then
    chmod +x "$HELPER"
  else
    echo "   ⚠ Helper script not found at $HELPER" >&2
    echo "     Re-run install.sh first, then re-run this script." >&2
    exit 1
  fi
fi

SERVICE=/etc/systemd/system/pedal-connect.service
echo "▶ Installing auto-reconnect service..."
sudo tee "$SERVICE" > /dev/null << EOF
[Unit]
Description=Reconnect Lyric Prompter foot pedal on boot
After=bluetooth.service
Requires=bluetooth.service

[Service]
Type=oneshot
User=$USER
Environment=HOME=$HOME
ExecStart=/bin/bash $HELPER
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable pedal-connect.service
sudo systemctl restart pedal-connect.service || true
echo "   ✓ pedal-connect.service installed and enabled"

# ── 5. Done ──────────────────────────────────────────────────
echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║  ✅  Pedal paired and trusted                              ║"
echo "║                                                            ║"
echo "║  IMPORTANT — set the pedal to Page Up/Down mode:           ║"
echo "║    Hold both pedals ~3s until LED flashes, then tap        ║"
echo "║    to cycle modes. Stop on the PgUp/PgDn mode (refer       ║"
echo "║    to the slip in the box for indicator pattern).          ║"
echo "║                                                            ║"
echo "║  Then test in the prompter:                                ║"
echo "║    Left pedal  → jump to top of song                       ║"
echo "║    Right pedal → jump down 75% of screen                   ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""
