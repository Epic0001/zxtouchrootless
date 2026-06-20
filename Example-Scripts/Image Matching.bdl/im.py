from zxtouch.client import zxtouch
from zxtouch.toasttypes import *
import time

device = zxtouch("127.0.0.1")
template = "/var/mobile/Library/ZXTouch/scripts/examples/Image Matching.bdl/examples_folder.jpg"

device.show_toast(TOAST_WARNING, "Matching the visible word: examples", 1.5, TOAST_BUTTOM)
time.sleep(1.0)

started = time.time()
result_tuple = device.image_match(template)
elapsed = time.time() - started
print("image_match result:", result_tuple, "elapsed:", round(elapsed, 3))

if not result_tuple[0]:
    device.show_alert_box(
        "Image Match Failed",
        "Target: examples\nElapsed: %.3fs\n\n%s\n\nOpen a screen where the word examples is visible, then run this again." % (elapsed, result_tuple[1]),
        0
    )
else:
    result_dict = result_tuple[1]
    message = "X: {x}\nY: {y}\nWidth: {width}\nHeight: {height}\nElapsed: %.3fs" % elapsed
    device.show_alert_box("Image Match Found", message.format(**result_dict), 0)

device.disconnect()
