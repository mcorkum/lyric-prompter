#!/bin/bash
# ============================================================
#  Lyric Prompter — Samba Songs Share (optional)
#  Exposes ~/Songs/ as a network share so you can drag lyric
#  files onto the Pi from any laptop on the same Wi-Fi.
#    bash setup-samba.sh
# ============================================================
set -e

SHARE_NAME="Songs"
SONGS_DIR="$HOME/Songs"
SMB_CONF="/etc/samba/smb.conf"

echo ""
echo "╔══════════════════════════════════════╗"
echo "║   📁  Samba Songs Share Setup        ║"
echo "╚══════════════════════════════════════╝"
echo ""

# ── 1. Install Samba ─────────────────────────────────────────
echo "▶ Installing Samba..."
sudo apt-get update -qq
sudo apt-get install -y samba samba-common-bin
echo "   ✓ Samba installed"

# ── 2. Make sure the songs folder exists ─────────────────────
mkdir -p "$SONGS_DIR"
echo "   ✓ Share path: $SONGS_DIR"

# ── 3. Back up smb.conf and write our share ──────────────────
if [ ! -f "${SMB_CONF}.lyric-bak" ]; then
  sudo cp "$SMB_CONF" "${SMB_CONF}.lyric-bak"
  echo "   ✓ Backed up original smb.conf to ${SMB_CONF}.lyric-bak"
fi

# Add the share section if it isn't already there (idempotent)
if ! sudo grep -q "^\[$SHARE_NAME\]" "$SMB_CONF"; then
  echo "▶ Adding [$SHARE_NAME] share to smb.conf..."
  sudo tee -a "$SMB_CONF" > /dev/null << EOF

# ── Lyric Prompter share (added by setup-samba.sh) ──
[$SHARE_NAME]
   comment = Lyric Prompter songs folder
   path = $SONGS_DIR
   browseable = yes
   read only = no
   writable = yes
   guest ok = yes
   guest only = yes
   create mask = 0664
   directory mask = 0775
   force user = $USER
   force group = $USER
EOF
  echo "   ✓ Share section added"
else
  echo "   ✓ [$SHARE_NAME] share already present — leaving as-is"
fi

# Make sure guest access is enabled in [global]
if ! sudo grep -q "map to guest" "$SMB_CONF"; then
  echo "▶ Enabling guest access in [global]..."
  sudo sed -i '/^\[global\]/a    map to guest = bad user' "$SMB_CONF"
  echo "   ✓ map to guest = bad user added"
fi

# ── 4. Validate and restart Samba ────────────────────────────
echo "▶ Validating smb.conf..."
sudo testparm -s "$SMB_CONF" > /dev/null
echo "   ✓ Config OK"

echo "▶ Enabling and restarting Samba..."
sudo systemctl enable --now smbd nmbd 2>/dev/null || sudo systemctl enable --now smbd
sudo systemctl restart smbd
sudo systemctl restart nmbd 2>/dev/null || true
echo "   ✓ Samba running"

# ── 5. Get IP and print connect info ─────────────────────────
IP=$(hostname -I | awk '{print $1}')
HOST=$(hostname)

echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║  ✅  Samba share active                                    ║"
echo "║                                                            ║"
echo "║  Connect from another machine on the same network:         ║"
echo "║    Windows:  \\\\$IP\\$SHARE_NAME"
echo "║              \\\\$HOST\\$SHARE_NAME"
echo "║    macOS:    smb://$IP/$SHARE_NAME"
echo "║              smb://$HOST.local/$SHARE_NAME"
echo "║    Linux:    smb://$IP/$SHARE_NAME (in file manager)       ║"
echo "║                                                            ║"
echo "║  No password needed — guest access is enabled.             ║"
echo "║  Drop .txt or .md files into the share; the prompter       ║"
echo "║  picks them up automatically within ~6 seconds.            ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""
