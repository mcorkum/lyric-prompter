# 🎵 Lyric Prompter — Raspberry Pi 5

A fullscreen teleprompter for live performance lyrics. Reads `.txt` and `.md` files from a USB stick (or `~/Songs/`) and displays them beautifully in kiosk mode.

---

## Quick Install

```bash
# 1. Copy these files to your Pi, then:
bash install.sh
```

Reboot and Chromium opens automatically in fullscreen kiosk mode. Chromium waits for the Flask server to actually respond before launching — typically <2s after login.

> **All setup scripts are safe to re-run any time** to fix issues:
> - `bash install.sh` — repairs the main app, services, and autostart
> - `bash setup-samba.sh` — resets the Samba share and password
> - `bash setup-pedal.sh` — re-pairs the Bluetooth pedal and rewrites the auto-reconnect service

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

Installs Samba, exposes `~/Songs/` as a password-protected share named **Songs**, and prints the connect URL for Windows, macOS, and Linux. The script will prompt you to set a Samba password for your Pi user during setup.

When connecting from another machine, enter your **Pi username** and the Samba password you just set. The prompter picks up new files automatically within ~6 seconds (no manual refresh).

```bash
# Forgot the Samba password? Reset it without re-running the whole setup:
sudo smbpasswd <pi-username>
```

> Why password auth? Windows 10/11 disables anonymous guest SMB access by default for security, so a password-protected share works on every OS without client-side tweaks.

---

## Bluetooth Foot Pedal — Donner DBM-20 (optional)

Hands-free control via the Donner DBM-20 BT page-turner.

```bash
bash setup-pedal.sh
```

Walks you through pairing and installs an auto-reconnect service so the pedal comes back on every boot.

### DBM-20 Modes

The DBM-20 has 4 modes. Cycle modes by holding both foot pedals ~3 s, then tapping. Two of them work with the prompter:

**Mode: Page Up / Page Down** (simple, just the foot pedals)
- Left pedal → jump to top of song
- Right pedal → jump down 75% of screen

**Mode: Media keys** (all buttons live)
- Left pedal → jump to top of song
- Right pedal → jump down 75%
- Skip ◄◄ → scroll up 75%
- Skip ►► → scroll down 75%
- Play/Pause: **tap** → start/stop auto-scroll · **hold** → ramp scroll speed up while held
- Stop (■) → stop auto-scroll

All keyboard shortcuts keep working alongside the pedal in any mode. Decreasing speed is keyboard-only (`[`).

### Troubleshooting the pedal

If a button does nothing in either mode, the pedal may be sending an unrecognised key code. Open Chromium devtools (`F12`) → Console, then run:

```js
document.addEventListener('keydown', e => console.log('key:', e.key));
```

Press the pedal button and read the logged key name. Send that name and we can map it.

---

## Troubleshooting

| Issue | Fix |
|-------|-----|
| No songs found | Press `R` to refresh; check USB is mounted under `/media/` |
| Text too small | Press `+` to increase; or edit `--font-size: 2.2rem` in the CSS |
| Cursor visible | `sudo apt install unclutter` and add `@unclutter -idle 0.5 -root` to LXDE autostart |
| Kiosk doesn't launch | Check `systemctl status lyric-prompter` and the autostart file |
| USB not detected | Run `lsblk` — Pi OS mounts USB under `/media/<username>/<label>` |
