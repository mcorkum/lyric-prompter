# Lyric Prompter — Keyboard Controls

---

## Navigation

| Key              | Action                          |
|------------------|---------------------------------|
| `Left Arrow`     | Previous song                   |
| `Right Arrow`    | Next song                       |
| `Up Arrow`       | Scroll up ~15% of screen        |
| `Down Arrow`     | Scroll down ~15% of screen      |
| `Page Up`        | Jump to top (also: foot pedal L)|
| `Page Down`      | Jump down 75% (also: foot pedal R)|
| `Home`           | Jump to top of song             |
| `End`            | Jump to bottom of song          |
| `T`              | Jump to top (Home alternate)    |
| `E`              | Jump to bottom (End alternate)  |
| `Space`          | Jump down 75% of screen         |

---

## Auto-scroll

| Key              | Action                          |
|------------------|---------------------------------|
| `Shift + Space`  | Toggle auto-scroll on / off     |
| `[`              | Slow down scroll speed          |
| `]`              | Speed up scroll speed           |
| `Esc`            | Stop auto-scroll                |

Default speed: 80 px/s. Range: 2 – 300 px/s. Current speed shown in badge while active.

---

## Display

| Key              | Action                          |
|------------------|---------------------------------|
| `+` or `=`       | Increase font size              |
| `-`              | Decrease font size              |
| `F`              | Toggle fullscreen               |

Font size is remembered per song and restored automatically next visit.

---

## Library

| Key              | Action                          |
|------------------|---------------------------------|
| `S`              | Open / close song list          |
| `R`              | Force-refresh USB / song list   |

USB is also detected automatically — the song list updates within a few seconds of plugging in.

---

## Misc

| Key              | Action                          |
|------------------|---------------------------------|
| `?`              | Show / hide this key reference  |
| `Esc`            | Close any open overlay          |

---

## Foot pedal — Donner DBM-20 (optional)

| Action                        | Pedal button         |
|-------------------------------|----------------------|
| Jump to top of song           | Left pedal           |
| Jump down 75%                 | Right pedal          |
| Scroll up 75%                 | Skip ◄◄ (media mode) |
| Scroll down 75%               | Skip ►► (media mode) |
| Toggle auto-scroll            | Play/Pause tap       |
| Ramp scroll speed up          | Play/Pause hold      |

Run `setup-pedal.sh` to pair. See the README for DBM-20 mode reference.

---

*Place `.txt` or `.md` lyric files on a USB stick or in `~/Songs/`. Songs are loaded and sorted automatically.*
