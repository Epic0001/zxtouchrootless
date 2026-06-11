# ZXTouch Rootless 0.08

**iOS 16 Rootless (Dopamine) port by [Epic0001](https://github.com/Epic0001)**

A system-wide touch simulation and automation library for iOS. Controls your device programmatically via a Python client or recorded scripts — no app injection required.

> Based on [IOS13-SimulateTouch](https://github.com/xuan32546/IOS13-SimulateTouch) by xuan32546. This fork adds full **iOS 16 rootless (Dopamine)** support.

---

## What's New in This Fork

- **iOS 16 / Dopamine rootless** support — installs under `/var/jb/`, no rootful required
- **Dark mode** support for both the app and the floating panel
- **Panel redesign** — cleaner UI, settings popup with repeat/speed/interval fields
- **Touch indicator coordinates** toggle — show or hide the (x, y) label per finger
- **Python scripts fully working** — fixed `/bin/sh` path, `add_datetime.sh`, and socket timeouts
- **Color picker & color searcher re-enabled** — no OpenCV needed (pure CoreGraphics)
- **OCR** working via Vision framework
- **Volume-down stop** working for Python scripts
- **Script finished popup** shows accurate play count and script name
- Credits: by Epic0001 — `github.com/Epic0001`

---

## Requirements

- iOS 16.x (tested on 16.6.1)
- [Dopamine](https://ellekit.space/dopamine/) jailbreak
- ElleKit (included with Dopamine)
- Python 3 (install from Sileo via Procursus repo for Python scripts)

---

## Installation

Download the latest `.deb` from [GitHub Actions](https://github.com/Epic0001/IOS13-SimulateTouch/actions/workflows/build.yml) → pick the most recent successful run → download `ZXTouch-rootless-deb` artifact.

Install via SSH:
```bash
dpkg -i com.zjx.ioscontrol_0.1.0_iphoneos-arm64.deb
killall -9 SpringBoard
```
Or transfer to your device and open in Filza.

---

## Usage

### Panel (volume button)
Double-click volume down to show/hide the script panel. From the panel you can:
- Play scripts (tap to run directly, or enable ⚙️ to set repeat/speed/interval first)
- Start/stop touch recording
- Stop a running script

### Python Client
```python
from zxtouch.client import zxtouch
device = zxtouch("127.0.0.1")

device.touch(TOUCH_DOWN, 1, 400, 400)   # finger down
device.touch(TOUCH_UP,   1, 400, 400)   # finger up
device.show_alert_box("Hello", "World", 3)
device.show_toast(TOAST_SUCCESS, "Done!", 2)
device.disconnect()
```

Full API: see [original documentation](https://github.com/xuan32546/IOS13-SimulateTouch#instance-methods)

### API Status on iOS 16

| API | Status |
|-----|--------|
| Touch / MultiTouch | ✅ Working |
| Bring App to Foreground | ✅ Working |
| Show Alert Box | ✅ Working |
| Toast | ✅ Working |
| Run Shell Command | ✅ Working |
| Color Picker | ✅ Working |
| Color Searcher (find_color) | ✅ Working |
| OCR | ✅ Working |
| Accurate Sleep | ✅ Working |
| Get Screen Info / Device Info / Battery | ✅ Working |
| Play / Force Stop Script | ✅ Working |
| Start / Stop Recording | ✅ Working |
| Image Matching | ❌ Requires OpenCV (not bundled) |
| Text Input / Keyboard | ❌ Requires process injection into front app |

---

## Settings

Open the **ZXTouch app** → Settings:

| Setting | Description |
|---------|-------------|
| Touch Indicator | Show finger-position dots on screen |
| Show Coordinates | Toggle (x, y) label next to each dot |
| Double-click Volume | Enable volume-down shortcut for panel |
| Dark Mode | Dark theme for app and panel |
| Switch App Before Playing | Bring script's target app to foreground |

---

## Building from Source

Push to the `ios16-rootless` branch — GitHub Actions automatically builds the app (Xcode on macOS runner) and tweak (Theos), packages them into a `.deb`, and uploads it as an artifact. No Mac required.

Workflow: [`.github/workflows/build.yml`](.github/workflows/build.yml)

---

## Credits

- **iOS 16 rootless port**: [Epic0001](https://github.com/Epic0001)
- **Original ZXTouch**: [xuan32546](https://github.com/xuan32546/IOS13-SimulateTouch)
