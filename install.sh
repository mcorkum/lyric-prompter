#!/bin/bash
# ============================================================
#  Lyric Prompter — Raspberry Pi 5 Setup Script
#  Run as your normal pi user (NOT root):  bash install.sh
# ============================================================
set -e

INSTALL_DIR="$HOME/lyric-prompter"
SERVICE_NAME="lyric-prompter"

echo ""
echo "╔══════════════════════════════════════╗"
echo "║   🎵  Lyric Prompter Installer       ║"
echo "╚══════════════════════════════════════╝"
echo ""

# ── 1. Dependencies ──────────────────────────────────────────
echo "▶ Installing system dependencies..."
sudo apt-get update -qq
# Bookworm uses 'chromium', Bullseye uses 'chromium-browser'
sudo apt-get install -y python3-pip python3-flask unclutter
sudo apt-get install -y chromium 2>/dev/null || sudo apt-get install -y chromium-browser

# Detect which binary is available
if command -v chromium &>/dev/null; then
  CHROMIUM_BIN="chromium"
elif command -v chromium-browser &>/dev/null; then
  CHROMIUM_BIN="chromium-browser"
else
  echo "   ⚠ Could not find Chromium — install it manually and re-run"
  CHROMIUM_BIN="chromium"
fi
echo "   ✓ Using Chromium binary: $CHROMIUM_BIN"

echo "▶ Installing Python dependencies..."
pip3 install flask --break-system-packages 2>/dev/null || pip3 install flask

# ── 2. Copy files ────────────────────────────────────────────
echo "▶ Setting up app directory at $INSTALL_DIR..."
mkdir -p "$INSTALL_DIR"

# Copy files from current directory to install location
cp -r . "$INSTALL_DIR/" 2>/dev/null || true

# ── 3. Test song folder ──────────────────────────────────────
mkdir -p "$HOME/Songs"
if [ ! -f "$HOME/Songs/Example Song.txt" ]; then
  cat > "$HOME/Songs/Example Song.txt" << 'LYRICS'
[Verse 1]
This is an example song
To show the prompter working fine
Drop your lyric files on a USB
Or place them right in ~/Songs/

[Chorus]
Every line displayed in full
Big text that you can read from far
Scroll up and down with arrow keys
Or let it auto-scroll so far

[Verse 2]
Press left and right to change the song
Plus and minus for the size
Hit S to see your setlist
And F to go full-screen wide

[Chorus]
Every line displayed in full
Big text that you can read from far
Scroll up and down with arrow keys
Or let it auto-scroll so far

[Outro]
Press Space to start auto-scroll
Press R to reload from USB
Press ? for the full key guide
Enjoy your gig — play free!
LYRICS
  echo "   ✓ Created example song at ~/Songs/Example Song.txt"
fi

# ── 4. systemd service: Flask server ────────────────────────
echo "▶ Creating Flask server systemd service..."
sudo tee /etc/systemd/system/${SERVICE_NAME}.service > /dev/null << EOF
[Unit]
Description=Lyric Prompter Flask Server
After=network.target

[Service]
Type=simple
User=$USER
WorkingDirectory=$INSTALL_DIR
ExecStart=/usr/bin/python3 $INSTALL_DIR/server.py
Restart=always
RestartSec=3
Environment=PYTHONUNBUFFERED=1

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable ${SERVICE_NAME}
sudo systemctl restart ${SERVICE_NAME}
echo "   ✓ Flask server service enabled and started"

# ── 5. Autostart Chromium kiosk on login ────────────────────
echo "▶ Setting up Chromium kiosk autostart..."

AUTOSTART_LXDE="$HOME/.config/lxsession/LXDE-pi/autostart"
AUTOSTART_WAYFIRE="$HOME/.config/wayfire.ini"

mkdir -p "$(dirname $AUTOSTART_LXDE)"

# For Raspberry Pi OS Bookworm (Wayfire compositor)
if [ -f "$AUTOSTART_WAYFIRE" ]; then
  mkdir -p "$HOME/.config/autostart"
  cat > "$HOME/.config/autostart/lyric-prompter-kiosk.desktop" << EOF
[Desktop Entry]
Type=Application
Name=Lyric Prompter Kiosk
Exec=bash -c 'sleep 5 && $CHROMIUM_BIN --kiosk --noerrdialogs --disable-infobars --no-first-run --ozone-platform=wayland http://localhost:5000'
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
EOF
  echo "   ✓ Created Wayfire autostart entry"
fi

# For Raspberry Pi OS Bullseye (LXDE)
if [ -d "$(dirname $AUTOSTART_LXDE)" ]; then
  grep -q "localhost:5000" "$AUTOSTART_LXDE" 2>/dev/null || \
    echo "@$CHROMIUM_BIN --kiosk --noerrdialogs --disable-infobars --no-first-run http://localhost:5000" >> "$AUTOSTART_LXDE"
  grep -q "unclutter" "$AUTOSTART_LXDE" 2>/dev/null || \
    echo "@unclutter -idle 0.5 -root" >> "$AUTOSTART_LXDE"
  echo "   ✓ Added LXDE autostart entry"
fi

# ── 6. USB automount hook ────────────────────────────────────
echo "▶ Adding udev rule to notify on USB insert..."
sudo tee /etc/udev/rules.d/99-lyric-usb.rules > /dev/null << 'EOF'
# Trigger a song refresh in Lyric Prompter when USB storage is plugged in
ACTION=="add", SUBSYSTEM=="block", ENV{ID_FS_TYPE}!="", \
  RUN+="/bin/systemctl try-restart lyric-prompter.service"
EOF
sudo udevadm control --reload-rules
echo "   ✓ USB udev rule installed"

# ── 7. Backlight permissions (permanent) ─────────────────────
echo "▶ Making backlight brightness writable permanently..."
sudo tee /etc/udev/rules.d/98-backlight.rules > /dev/null << 'EOF'
# Allow all users to set screen brightness (for Lyric Prompter b/B keys)
SUBSYSTEM=="backlight", ACTION=="add", RUN+="/bin/chmod a+w /sys%p/brightness"
EOF
sudo udevadm control --reload-rules
for f in /sys/class/backlight/*/brightness; do
  [ -f "$f" ] && sudo chmod a+w "$f" && echo "   ✓ Applied to $f"
done
echo "   ✓ Backlight udev rule installed (permanent across reboots)"

# ── 8. Done ──────────────────────────────────────────────────
echo ""
echo "╔══════════════════════════════════════════════════════╗"
echo "║  ✅  Installation complete!                          ║"
echo "║                                                      ║"
echo "║  • Server running at http://localhost:5000           ║"
echo "║  • Drop .txt or .md lyrics in ~/Songs/ or USB        ║"
echo "║  • Chromium will open in kiosk mode on next boot     ║"
echo "║                                                      ║"
echo "║  To test now (without rebooting):                    ║"
echo "║    $CHROMIUM_BIN --kiosk http://localhost:5000       ║"
echo "╚══════════════════════════════════════════════════════╝"
echo ""
