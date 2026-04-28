# 🎵 Lyric Prompter — Raspberry Pi 5

A fullscreen teleprompter for live performance lyrics. Reads `.txt` and `.md` files from a USB stick (or `~/Songs/`) and displays them beautifully in kiosk mode.

---

## Quick Install

```bash
# 1. Copy these files to your Pi, then:
bash install.sh
```

Reboot and Chromium opens automatically in fullscreen kiosk mode.

---

## File Structure

```
lyric-prompter/
├── server.py          ← Flask backend
├── templates/
│   └── index.html     ← Fullscreen UI
├── install.sh         ← One-shot setup script
└── README.md          ← This file
```

---

## Keyboard Controls

| Key | Action |
|-----|--------|
| `←` / `→` | Previous / Next song |
| `↑` / `↓` | Scroll up / down (~15% of screen) |
| `Page Up` / `Page Down` | Page scroll |
| `Home` / `End` | Jump to top / bottom |
| `T` / `E` | Jump to top / bottom (K400-friendly alternate) |
| `+` / `=` | Bigger text |
| `-` | Smaller text |
| `Space` | Jump down 75% of screen |
| `Shift + Space` | Toggle auto-scroll |
| `[` / `]` | Scroll speed down / up (live, while scrolling) |
| `S` | Toggle song list sidebar |
| `F` | Toggle fullscreen |
| `R` | Force-refresh USB / song list |
| `?` | Show key reference |
| `Esc` | Close overlays / stop scroll |

See [CONTROLS.md](CONTROLS.md) for a printable one-page cheatsheet.

---

## Lyric File Format

### Plain Text (`.txt`)
```
[Verse 1]
Your lyrics here
One line per line

[Chorus]
Chorus lyrics
```
Square-bracket labels like `[Verse 1]` are highlighted automatically.

### Markdown (`.md`)
```markdown
# Song Title

## Chorus
Your chorus lyrics

## Verse 1
Your verse here

**Important word** for emphasis
*Softer word* in italics
```

---

## USB Stick Layout

Just copy your lyric files anywhere on a FAT32 USB:

```
USB/
├── 01 - Amazing Grace.txt
├── 02 - Hallelujah.md
├── Originals/
│   └── My Song.txt
└── Covers/
    └── Bohemian Rhapsody.md
```

Songs are sorted alphabetically by filename. Plug in the USB — the song list refreshes automatically within a few seconds. Press `R` to force an immediate refresh.

---

## Manual Start (without rebooting)

```bash
# Start the server manually
python3 ~/lyric-prompter/server.py &

# Open kiosk (Wayland/Bookworm)
chromium-browser --kiosk --ozone-platform=wayland http://localhost:5000

# Open kiosk (X11/Bullseye)
chromium-browser --kiosk http://localhost:5000
```

---

## Auto-scroll Speed

Auto-scroll defaults to 55 px/s. Adjust it **live** with `[` (slower) and `]` (faster) while the prompter is running — no need to edit code. The badge in the corner shows the current speed.

To change the default, edit this line in `templates/index.html`:

```js
let scrollSpeed = 55;   // px/s — increase for faster, decrease for slower
```

---

## Samba Network Share (optional)

Drop lyric files onto the Pi from any laptop on the same Wi-Fi — no USB stick required.

```bash
bash setup-samba.sh
```

Installs Samba, exposes `~/Songs/` as a guest-writable share named **Songs**, and prints the connect URL for Mac, Windows, and Linux. Once mounted, drag `.txt` or `.md` files into the share — the prompter picks them up automatically within ~6 seconds (no manual refresh).

Guest access is enabled by default for convenience on a private band setup. If you need password protection, edit `/etc/samba/smb.conf` to set `guest ok = no` for the `[Songs]` section and add a Samba user with `sudo smbpasswd -a <user>`.

---

## Bluetooth Foot Pedal (optional)

Hands-free page control via a Donner BT pedal (or any HID page-turner that sends Page Up / Page Down).

```bash
bash setup-pedal.sh
```

Walks you through pairing and installs an auto-reconnect service so the pedal comes up on every boot. Set the pedal to **Page Up / Page Down** mode (button combo on the pedal — see the manufacturer's slip).

Once paired:
- **Left pedal** → jump to top of song
- **Right pedal** → jump down 75% of screen (same as `Space`)

All keyboard controls keep working alongside the pedal.

---

## Troubleshooting

| Issue | Fix |
|-------|-----|
| No songs found | Press `R` to refresh; check USB is mounted under `/media/` |
| Text too small | Press `+` to increase; or edit `--font-size: 2.2rem` in the CSS |
| Cursor visible | `sudo apt install unclutter` and add `@unclutter -idle 0.5 -root` to LXDE autostart |
| Kiosk doesn't launch | Check `systemctl status lyric-prompter` and the autostart file |
| USB not detected | Run `lsblk` — Pi OS mounts USB under `/media/<username>/<label>` |
