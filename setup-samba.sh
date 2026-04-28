#!/bin/bash
# ============================================================
#  Lyric Prompter — Samba Songs Share (optional)
#  Exposes ~/Songs/ as a password-protected network share so
#  you can drag lyric files onto the Pi from any laptop on
#  the same Wi-Fi.
#    bash setup-samba.sh
#
#  Safe to re-run any time — restores the original smb.conf
#  from backup, rewrites the [Songs] section, and resets the
#  Samba password. Use it to fix a broken share or change
#  the password.
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

# ── 3. Back up or restore smb.conf (idempotent re-run) ───────
if [ ! -f "${SMB_CONF}.lyric-bak" ]; then
  sudo cp "$SMB_CONF" "${SMB_CONF}.lyric-bak"
  echo "   ✓ Backed up original smb.conf to ${SMB_CONF}.lyric-bak"
else
  # Restore from backup so any previous [Songs] / guest config is wiped
  sudo cp "${SMB_CONF}.lyric-bak" "$SMB_CONF"
  echo "   ✓ Restored smb.conf from backup (clean slate)"
fi

# ── 4. Append the password-protected share ───────────────────
echo "▶ Adding [$SHARE_NAME] share to smb.conf..."
sudo tee -a "$SMB_CONF" > /dev/null << EOF

# ── Lyric Prompter share (added by setup-samba.sh) ──
[$SHARE_NAME]
   comment = Lyric Prompter songs folder
   path = $SONGS_DIR
   browseable = yes
   read only = no
   writable = yes
   valid users = $USER
   create mask = 0664
   directory mask = 0775
   force user = $USER
   force group = $USER
EOF
echo "   ✓ Share section added"

# ── 5. Set Samba password for the Pi user ────────────────────
echo ""
echo "▶ Setting Samba password for user '$USER'."
echo "   You'll use this password (with username '$USER') when"
echo "   Windows / macOS / Linux prompts you for credentials."
echo ""
sudo smbpasswd -a "$USER"
sudo smbpasswd -e "$USER" > /dev/null

# ── 6. Validate and restart Samba ────────────────────────────
echo "▶ Validating smb.conf..."
sudo testparm -s "$SMB_CONF" > /dev/null
echo "   ✓ Config OK"

echo "▶ Enabling and restarting Samba..."
sudo systemctl enable --now smbd nmbd 2>/dev/null || sudo systemctl enable --now smbd
sudo systemctl restart smbd
sudo systemctl restart nmbd 2>/dev/null || true
echo "   ✓ Samba running"

# ── 7. Get IP and print connect info ─────────────────────────
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
echo "║  Username: $USER"
echo "║  Password: (the one you just set)                          ║"
echo "║                                                            ║"
echo "║  Forgot the password? Reset it any time:                   ║"
echo "║    sudo smbpasswd $USER"
echo "║                                                            ║"
echo "║  Drop .txt or .md files into the share; the prompter       ║"
echo "║  picks them up automatically within ~6 seconds.            ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""
