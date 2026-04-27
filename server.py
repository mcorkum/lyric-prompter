#!/usr/bin/env python3
"""
Lyric Prompter Server - Raspberry Pi 5
Scans USB sticks for .txt/.md lyric files and serves them via a local web UI.
"""

import os
import re
import glob
import threading
from pathlib import Path
from flask import Flask, jsonify, render_template, send_from_directory

app = Flask(__name__)

# ── USB mount search paths (Raspberry Pi OS mounts USB under /media/*)
USB_SEARCH_PATHS = [
    "/media",
    "/mnt",
]

SUPPORTED_EXTENSIONS = {".txt", ".md"}


def find_usb_mounts():
    """Return list of mounted USB directories."""
    mounts = []
    for base in USB_SEARCH_PATHS:
        if os.path.isdir(base):
            for entry in os.scandir(base):
                if entry.is_dir():
                    # /media/<user>/<label>  — go one level deeper if needed
                    inner = list(os.scandir(entry.path)) if entry.is_dir() else []
                    if any(e.is_dir() for e in inner):
                        for sub in inner:
                            if sub.is_dir():
                                mounts.append(sub.path)
                    else:
                        mounts.append(entry.path)
    return mounts


def scan_lyrics():
    """Walk USB mounts (and ~/Songs fallback) for lyric files."""
    songs = []
    search_roots = find_usb_mounts()

    # Fallback: local ~/Songs folder for development / testing
    local_songs = os.path.expanduser("~/Songs")
    if os.path.isdir(local_songs):
        search_roots.append(local_songs)

    seen_paths = set()
    for root in search_roots:
        for dirpath, _, filenames in os.walk(root):
            for fname in sorted(filenames):
                ext = Path(fname).suffix.lower()
                if ext in SUPPORTED_EXTENSIONS:
                    full = os.path.join(dirpath, fname)
                    if full not in seen_paths:
                        seen_paths.add(full)
                        # Build a clean title from filename
                        title = Path(fname).stem
                        title = re.sub(r"[-_]+", " ", title).strip()
                        songs.append({
                            "title": title,
                            "path": full,
                            "filename": fname,
                            "ext": ext,
                        })

    songs.sort(key=lambda s: s["title"].lower())
    return songs


def read_song(path: str) -> str:
    """Read a song file safely."""
    try:
        with open(path, "r", encoding="utf-8", errors="replace") as f:
            return f.read()
    except Exception as e:
        return f"[Error reading file: {e}]"


# ── Routes ────────────────────────────────────────────────────────────────────

@app.route("/")
def index():
    return render_template("index.html")


@app.route("/api/songs")
def api_songs():
    songs = scan_lyrics()
    # Strip full path from response for security; use index as ID
    return jsonify([
        {"id": i, "title": s["title"], "ext": s["ext"]}
        for i, s in enumerate(songs)
    ])


@app.route("/api/song/<int:song_id>")
def api_song(song_id):
    songs = scan_lyrics()
    if song_id < 0 or song_id >= len(songs):
        return jsonify({"error": "not found"}), 404
    s = songs[song_id]
    content = read_song(s["path"])
    return jsonify({
        "id": song_id,
        "title": s["title"],
        "content": content,
        "ext": s["ext"],
        "total": len(songs),
    })


@app.route("/api/refresh")
def api_refresh():
    songs = scan_lyrics()
    return jsonify({"count": len(songs)})


# ── Brightness control ────────────────────────────────────────────────────────

BRIGHTNESS_STEP = 20   # out of 255
BRIGHTNESS_MIN  = 10   # never go completely dark
BRIGHTNESS_MAX  = 255

def find_backlight_path():
    """Return the first writable brightness sysfs path, or None."""
    for pattern in [
        "/sys/class/backlight/*/brightness",
        "/sys/class/leds/*/brightness",
    ]:
        matches = glob.glob(pattern)
        for path in matches:
            if os.access(path, os.W_OK):
                return path
    return None

def get_brightness():
    path = find_backlight_path()
    if not path:
        return None
    try:
        with open(path) as f:
            return int(f.read().strip())
    except Exception:
        return None

def set_brightness(value: int):
    path = find_backlight_path()
    if not path:
        return False, "No writable backlight found. Run: sudo chmod a+w /sys/class/backlight/*/brightness"
    value = max(BRIGHTNESS_MIN, min(BRIGHTNESS_MAX, value))
    try:
        with open(path, "w") as f:
            f.write(str(value))
        return True, value
    except PermissionError:
        return False, f"Permission denied. Fix with:\nsudo chmod a+w {path}"
    except Exception as e:
        return False, str(e)

@app.route("/api/brightness")
def api_brightness_get():
    val = get_brightness()
    if val is None:
        return jsonify({"error": "No backlight found", "value": None})
    pct = round(val / BRIGHTNESS_MAX * 100)
    return jsonify({"value": val, "percent": pct, "max": BRIGHTNESS_MAX})

@app.route("/api/brightness/<direction>")
def api_brightness_change(direction):
    current = get_brightness()
    if current is None:
        return jsonify({"error": "No backlight found"}), 404
    if direction == "up":
        target = current + BRIGHTNESS_STEP
    elif direction == "down":
        target = current - BRIGHTNESS_STEP
    else:
        return jsonify({"error": "Use 'up' or 'down'"}), 400
    ok, result = set_brightness(target)
    if not ok:
        return jsonify({"error": result}), 500
    pct = round(result / BRIGHTNESS_MAX * 100)
    return jsonify({"value": result, "percent": pct, "max": BRIGHTNESS_MAX})


if __name__ == "__main__":
    print("🎵 Lyric Prompter starting on http://localhost:5000")
    app.run(host="0.0.0.0", port=5000, debug=False, threaded=True)
