# ZXTouch Rootless

**iOS 16 Rootless (Dopamine) port by [Epic0001](https://github.com/Epic0001)**

A system-wide touch simulation and automation library for jailbroken iOS devices. Simulate touches, run scripts, interact with your screen programmatically — system level, no app injection.

> Forked from [IOS13-SimulateTouch](https://github.com/xuan32546/IOS13-SimulateTouch) by xuan32546. This fork brings full **rootless iOS 16 (Dopamine)** support.

---

## What's New

- **iOS 16 rootless (Dopamine)** — installs under `/var/jb/`, compatible with ElleKit
- **Rebuilt panel UI** — floating script panel with ⚙️ settings popup (repeat / speed / interval), dark mode support, orientation-aware positioning
- **Dark mode** — toggle in the app for both the app and the panel
- **Touch indicator** — show/hide coordinate labels per finger
- **Python scripts fully working** — fixed `/bin/sh` path on rootless, output logging, socket handling
- **Color picker & searcher re-enabled** — reimplemented in pure CoreGraphics (no OpenCV)
- **OCR** working via Vision framework
- **Accurate play count** in "Script Finished" popup
- **Volume-down stop** working for Python scripts

---

## Requirements

- iOS 16.x (tested on 16.6.1)
- [Dopamine](https://ellekit.space/dopamine/) jailbreak
- Python 3 from Procursus (for `.py` scripts)

---

## Installation

Download the latest `.deb` from [Releases](https://github.com/Epic0001/zxtouchrootless/releases) or [Actions](https://github.com/Epic0001/zxtouchrootless/actions).

Install via Filza or SSH:
```sh
dpkg -i com.zjx.ioscontrol_*.deb
killall -9 SpringBoard
```

---

## Usage

### Panel
Double-click **volume down** to open/close the script panel.

- **Tap a script** → runs immediately
- **Enable ⚙️ first** → shows a popup to set repeat count, speed, and interval before running
- **⏺ REC** → start recording touches
- **⏹ STOP** → stop a running script

### Python Client

```python
from zxtouch.client import zxtouch
from zxtouch.touchtypes import *
import time

device = zxtouch("127.0.0.1")

# Single touch
device.touch(TOUCH_DOWN, 1, 400, 400)
time.sleep(0.1)
device.touch(TOUCH_UP, 1, 400, 400)

# Multi-touch
device.touch_with_list([
    {"type": TOUCH_DOWN, "finger_index": 1, "x": 300, "y": 300},
    {"type": TOUCH_DOWN, "finger_index": 2, "x": 600, "y": 600}
])

device.show_alert_box("Done", "Script finished", 2)
device.disconnect()
```

---

## API Status on iOS 16

| Method | Status |
|--------|--------|
| `touch` / `touch_with_list` | ✅ |
| `show_alert_box` | ✅ |
| `show_toast` | ✅ |
| `switch_to_app` | ✅ |
| `run_shell_command` | ✅ |
| `pick_color` | ✅ |
| `find_color` | ✅ |
| `ocr` | ✅ |
| `accurate_usleep` | ✅ |
| `get_screen_size` / `get_screen_orientation` / `get_screen_scale` | ✅ |
| `get_device_info` / `get_battery_info` | ✅ |
| `play_script` / `force_stop_script_play` | ✅ |
| `start_touch_recording` / `stop_touch_recording` | ✅ |
| `image_match` | ❌ Requires OpenCV |
| `insert_text` / `show_keyboard` / `move_cursor` | ❌ Requires process injection |

---

## Building

Every push to `ios16-rootless` triggers a GitHub Actions build on a macOS runner — Xcode compiles the app, Theos builds the tweak, and the `.deb` is uploaded as an artifact. **No Mac required.**

See [`.github/workflows/build.yml`](.github/workflows/build.yml).

---

## Credits

| | |
|--|--|
| **iOS 16 rootless port** | [Epic0001](https://github.com/Epic0001) |
| **Original ZXTouch** | [xuan32546](https://github.com/xuan32546) |
