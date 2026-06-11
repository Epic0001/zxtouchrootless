# ZXTouch Rootless

**iOS 16 Rootless (Dopamine) port by [Epic0001](https://github.com/Epic0001/zxtouchrootless)**

A **system wide** touch event simulation library for iOS. Simulate touches, run scripts, and automate your device — system level, no app injection required.

> Forked from [IOS13-SimulateTouch](https://github.com/xuan32546/IOS13-SimulateTouch) by xuan32546. This fork adds full **iOS 16 rootless (Dopamine)** support.

Discord: https://discord.gg/acSXfyz

---

## What's New in This Fork

- **iOS 16 rootless (Dopamine)** — installs under `/var/jb/`, compatible with ElleKit
- **Rebuilt panel UI** — floating script panel with ⚙️ settings popup (repeat / speed / interval), dark mode, orientation-aware layout
- **Dark mode** — toggle in the app for both the app UI and the panel
- **Touch indicator coordinates toggle** — show or hide (x, y) labels per finger
- **Python scripts fully working** — fixed `/bin/sh` rootless path, output logging, socket handling
- **Color picker & color searcher re-enabled** — reimplemented in pure CoreGraphics
- **OCR** working via Vision framework
- **Volume-down stop** working for Python scripts
- **Accurate script finished popup** — shows correct play count and script name

---

## Requirements

- iOS 16.x (tested on 16.6.1)
- [Dopamine](https://ellekit.space/dopamine/) jailbreak
- Python 3 from Procursus repo (for `.py` scripts)

---

## Installation

### Through GitHub Releases:
1. Download the latest `.deb` from [Releases](https://github.com/Epic0001/zxtouchrootless/releases)
2. Copy the `.deb` to your iOS device (AirDrop, Filza, or SSH)
3. Install via Filza or SSH:
```sh
dpkg -i com.zjx.ioscontrol_0.1.0_iphoneos-arm64.deb
killall -9 SpringBoard
```

### Through GitHub Actions (latest build):
1. Go to [Actions](https://github.com/Epic0001/zxtouchrootless/actions)
2. Open the latest successful run
3. Download the `ZXTouch-rootless-deb` artifact

---

## Demo Videos (original)

**Remote Controlling:**
[![Watch the video](img/remote_control_demo.jpg)](https://youtu.be/gdSGO6rJIL4)

**Instant Controlling (PUBG Mobile):**
[![Watch the video](img/pubg_mobile_demo.jpg)](https://youtu.be/XvvWHL6B3Tk)

**Recording & Playback:**
[![Watch the video](img/record_playback.jpg)](https://youtu.be/WeYMx4z8N2M)

Demo #4: [OCR](https://youtu.be/xt4BvgsSGkc)

Demo #5: [Touch Indicator](https://youtu.be/AU7zG_-W2tM)

Demo #6: [Color Picker](https://youtu.be/tserB05_B9E)

---

## Features

1. **Touch Simulation**
   - Multitouch supported
   - Programmable — scripts can be written in Python or any language with socket support
   - System-level simulation (does not inject into any app process)
   - Touch recording and playback
2. **GUI Application**
3. **Others**
   - Bring application to foreground
   - System-wide alert box
   - Shell command execution
   - Color picker — get pixel RGB from screen
   - Color searcher — find a color in a screen region
   - Device info and battery info
   - Toast notifications
   - OCR (text recognition)
   - Touch indicator with optional coordinate display
   - Accurate sleep

---

## Usage

After installation the tweak listens on **port 6000**. Send commands in the defined format from any language. The Python client is provided for convenience.

### Panel (Volume Button)
Double-click **volume down** to open/close the panel.
- Tap a script to run it immediately
- Enable **⚙️** first to set repeat count, speed, and interval before running
- **⏺ REC** — start recording touches
- **⏹ STOP** — stop a running script
- Settings → **Dark Mode** to toggle dark theme on app and panel

---

## Documentation (Python)

### Installation

**On your iOS device:** The ZXTouch Python module is installed automatically with the `.deb`.

**On a computer (remote control):** Copy the `zxtouch` folder from [`layout/usr/lib/python3.7/site-packages`](https://github.com/xuan32546/IOS13-SimulateTouch/tree/0.0.6/layout/usr/lib/python3.7/site-packages) to your Python `site-packages` directory.

### Create a ZXTouch Instance

```python
from zxtouch.client import zxtouch
device = zxtouch("127.0.0.1")  # use device IP for remote control
```

---

## Instance Methods

### API Status on iOS 16

| Method | iOS 16 Status |
|--------|--------------|
| `touch` / `touch_with_list` | ✅ Working |
| `switch_to_app` | ✅ Working |
| `show_alert_box` | ✅ Working |
| `run_shell_command` | ✅ Working |
| `show_toast` | ✅ Working |
| `pick_color` | ✅ Working |
| `find_color` | ✅ Working |
| `accurate_usleep` | ✅ Working |
| `play_script` / `force_stop_script_play` | ✅ Working |
| `get_screen_size` / `get_screen_orientation` / `get_screen_scale` | ✅ Working |
| `get_device_info` / `get_battery_info` | ✅ Working |
| `start_touch_recording` / `stop_touch_recording` | ✅ Working |
| `ocr` / `get_supported_ocr_languages` | ✅ Working |
| `image_match` | ❌ Requires OpenCV (not bundled) |
| `insert_text` / `show_keyboard` / `hide_keyboard` / `move_cursor` | ❌ Requires process injection |

---

## Touch

Two methods for sending touch events.

```python
def touch(type, finger_index, x, y):
	"""Perform a touch event
	
	Args:
		type: touch event type. Import from zxtouch.touchtypes
		finger_index: finger index 1-19
		x: x coordinate
		y: y coordinate
	"""
```

```python
def touch_with_list(self, touch_list: list):
    """Perform multiple touch events simultaneously
    
    Args:
    	touch_list: [{"type": ?, "finger_index": ?, "x": ?, "y": ?}, ...]
    """
```

**Code Example**

```python
from zxtouch.client import zxtouch
from zxtouch.touchtypes import *
import time

device = zxtouch("127.0.0.1")

device.touch(TOUCH_DOWN, 5, 400, 400)
time.sleep(1)
device.touch(TOUCH_MOVE, 5, 400, 600)
time.sleep(1)
device.touch(TOUCH_UP, 5, 400, 600)
time.sleep(1)

# Multitouch
device.touch_with_list([
    {"type": TOUCH_DOWN, "finger_index": 1, "x": 300, "y": 300},
    {"type": TOUCH_DOWN, "finger_index": 2, "x": 500, "y": 500}
])
time.sleep(1)
device.touch_with_list([
    {"type": TOUCH_UP, "finger_index": 1, "x": 300, "y": 300},
    {"type": TOUCH_UP, "finger_index": 2, "x": 500, "y": 500}
])

device.disconnect()
```

---

## Bring Application to Foreground

```python
def switch_to_app(bundle_identifier):
	"""Bring an application to foreground
	
	Args:
		bundle_identifier: bundle ID of the app (e.g. "com.apple.springboard")
	
	Returns:
		Result tuple (success, error_or_empty)
	"""
```

**Code Example**

```python
from zxtouch.client import zxtouch

device = zxtouch("127.0.0.1")
device.switch_to_app("com.apple.springboard")  # go to home screen
device.disconnect()
```

---

## Show Alert Box

```python
def show_alert_box(title, content, duration):
    """Show a system-wide alert box

    Args:
        title: alert title
        content: alert message
        duration: seconds before auto-dismiss (0 = manual dismiss only)

    Returns:
        Result tuple (success, error_or_empty)
    """
```

**Code Example**

```python
from zxtouch.client import zxtouch

device = zxtouch("127.0.0.1")
device.show_alert_box("Alert", "This is a system-wide alert box that lasts for 3 seconds", 3)
device.disconnect()
```

---

## Run Shell Command As Root

```python
def run_shell_command(command):
    """Run a shell command as root
	
    Args:
    	command: shell command string
        
    Returns:
        Result tuple (success, error_or_empty)
    """
```

---

## Image Matching

> ⚠️ Not available on iOS 16 rootless (requires OpenCV which is not bundled)

```python
def image_match(template_path, acceptable_value=0.8, max_try_times=4, scaleRation=0.8):
    """Match screen against a template image
	
    Args:
    	template_path: absolute path to template image on device
    	acceptable_value: similarity threshold (0-1)
    	scaleRation: scale factor per retry attempt
    	max_try_times: max number of retries
        
    Returns:
        Result tuple. On success, result[1] is a dict: {"x", "y", "width", "height"}
        If width and height are both 0, no match was found.
    """
```

---

## Toast

```python
def show_toast(toast_type, content, duration, position=0, fontSize=0):
	"""Show a toast notification
	
	Args:
        toast_type: TOAST_SUCCESS / TOAST_ERROR / TOAST_WARNING / TOAST_MESSAGE
        content: text to display
        duration: seconds to show
        position: TOAST_TOP (default) or TOAST_BOTTOM
	
	Returns:
        Result tuple (success, error_or_empty)
	"""
```

**Code Example**

```python
from zxtouch.client import zxtouch
from zxtouch.toasttypes import *
import time

device = zxtouch("127.0.0.1")
device.show_toast(TOAST_SUCCESS, "Success!", 1.5)
time.sleep(1.5)
device.show_toast(TOAST_ERROR, "Error!", 1.5)
time.sleep(1.5)
device.show_toast(TOAST_WARNING, "Warning!", 1.5)
time.sleep(1.5)
device.show_toast(TOAST_MESSAGE, "Message", 1.5)
time.sleep(1.5)
device.show_toast(TOAST_ERROR, "Shown at bottom", 3, TOAST_BUTTOM)
device.disconnect()
```

---

## Color Picker

```python
def pick_color(x, y):
    """Get the RGB value of a pixel on screen
	
    Args:
   		x: x coordinate
   		y: y coordinate

    Returns:
        Result tuple. On success, result[1] is {"red", "green", "blue"}
    """
```

**Code Example**

```python
from zxtouch.client import zxtouch
import time

device = zxtouch("127.0.0.1")
time.sleep(1.5)
result = device.pick_color(100, 100)
if result[0]:
    print("R:", result[1]["red"], "G:", result[1]["green"], "B:", result[1]["blue"])
device.disconnect()
```

---

## Accurate Sleep

```python
def accurate_usleep(microseconds):
    """Sleep for an accurate duration
	
    Args:
    	microseconds: time to sleep in microseconds
        
    Returns:
        Result tuple (success, error_or_empty)
    """
```

---

## Hide Keyboard

```python
def hide_keyboard():
    """Hide the on-screen keyboard
    
    Returns:
        Result tuple (success, error_or_empty)
    """
```

---

## Show Keyboard

```python
def show_keyboard():
    """Show the on-screen keyboard
    
    Returns:
        Result tuple (success, error_or_empty)
    """
```

---

## Text Input

> ⚠️ Not available on iOS 16 rootless (requires process injection into front app)

Insert text into the current text field. Use `"\b"` to delete a character.

```python
def insert_text(text):
    """Insert text into the focused text field
    
    Args:
    	text: text to insert (\b = backspace)
    	        
    Returns:
        Result tuple (success, error_or_empty)
    """
```

---

## Move Cursor

> ⚠️ Not available on iOS 16 rootless

```python
def move_cursor(offset):
    """Move the text cursor
	
    Args:
		offset: positions to move (negative = left, positive = right)
		    	        
    Returns:
        Result tuple (success, error_or_empty)
    """
```

---

## Play A Script

```python
def play_script(script_absolute_path):
    """Play a ZXTouch script (.bdl folder)
	
    Args:
    	script_absolute_path: absolute path to the .bdl script folder
    	        
    Returns:
        Result tuple (success, error_or_empty)
    """
```

---

## Force Stop Script Playing

```python
def force_stop_script_play():
    """Force stop the currently running script
	
    Returns:
        Result tuple (success, error_or_empty)
    """
```

---

## Get Screen Size

```python
def get_screen_size():
    """Get screen size in pixels
	
    Returns:
        Result tuple. On success, result[1] is {"width", "height"}
    """
```

---

## Get Screen Orientation

```python
def get_screen_orientation():
    """Get current screen orientation
	
    Returns:
        Result tuple. On success, result[1] is an orientation int as string.
        1 = Portrait, 2 = PortraitUpsideDown, 3 = LandscapeLeft, 4 = LandscapeRight
    """
```

---

## Get Screen Scale

```python
def get_screen_scale():
    """Get screen scale factor (e.g. 2.0 for Retina)
	
    Returns:
        Result tuple. On success, result[1] is a float as string.
    """
```

---

## Get Device Information

```python
def get_device_info():
    """Get device information
	
    Returns:
        Result tuple. On success, result[1] is:
        {"name", "system_name", "system_version", "model", "identifier_for_vendor"}
    """
```

---

## Get Battery Information

```python
def get_battery_info():
    """Get battery information
	
    Returns:
        Result tuple. On success, result[1] is:
        {"battery_state", "battery_level", "battery_state_string"}
    """
```

---

## Start Touch Recording

```python
def start_touch_recording():
    """Start recording touch events
    A green dot appears at the top of the screen while recording.
	
    Returns:
        Result tuple (success, error_or_empty)
    """
```

---

## Stop Touch Recording

```python
def stop_touch_recording():
    """Stop recording touch events
    You can also double-click volume down to stop.
	
    Returns:
        Result tuple (success, error_or_empty)
    """
```

---

## OCR

```python
def ocr(self, region, custom_words=[], minimum_height="", recognition_level=0, languages=[], auto_correct=0, debug_image_path=""):
    """Recognize text in a screen region

    Args:
        region: (x, y, width, height) tuple
        custom_words: extra words to supplement recognition
        minimum_height: min text height relative to image height (default 1/32)
        recognition_level: 0 = accurate, 1 = fast
        languages: list of language codes in priority order (default: English)
        auto_correct: 0 = off, 1 = on
        debug_image_path: path to save debug image (leave blank to skip)

    Returns:
        Result tuple. On success, result[1] is a list of recognized text strings.
    """
```

```python
def get_supported_ocr_languages(self, recognition_level):
    """Get list of languages supported by OCR

    Args:
        recognition_level: 0 = accurate, 1 = fast

    Returns:
        Result tuple. On success, result[1] is a list of language codes.
    """
```

---

## Building From Source

Every push to `main` triggers a GitHub Actions build — Xcode compiles the app on a macOS runner, Theos builds the tweak, and the `.deb` is uploaded as an artifact. **No Mac required.**

See [`.github/workflows/build.yml`](.github/workflows/build.yml).

---

## Credits

| | |
|--|--|
| **iOS 16 rootless port** | [Epic0001](https://github.com/Epic0001) |
| **Original ZXTouch** | [xuan32546](https://github.com/xuan32546) |
