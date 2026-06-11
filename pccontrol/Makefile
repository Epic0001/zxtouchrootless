include $(THEOS)/makefiles/common.mk

TWEAK_NAME = pccontrol

pccontrol_FILES = Tweak.xm SocketServer.xm Touch.xm Screen.xm Task.xm Process.xm AlertBox.xm Common.xm Record.xm Play.xm Window.xm Popup.xm Toast.xm UIKeyboard.xm DeviceInfo.xm TouchIndicator/TouchIndicatorWindow.xm TouchIndicator/TouchIndicatorView.xm TouchIndicator/TouchIndicatorCoordinateView.xm TouchIndicator/TouchIndicatorViewList.xm ScriptPlayer.xm TextRecognization/VKOcrManager.xm TextRecognization/TextRecognizer.xm UpdateCache.xm ColorPicker.xm
pccontrol_CFLAGS = -Wno-error -Wno-module-import-in-extern-c -fobjc-arc \
	-Wno-deprecated-declarations -Wno-unused-variable -Wno-unused-function \
	-Wno-format -Wno-return-type -Wno-incomplete-implementation \
	-Wno-unused-but-set-variable -Wno-macro-redefined -Wno-unicode-whitespace \
	-Wno-block-capture-autoreleasing -Wno-shadow-ivar -Wno-nonnull \
	-Wno-format-extra-args
pccontrol_FRAMEWORKS = UIKit AssetsLibrary AVFoundation CoreMedia CoreVideo IOSurface IOMobileFramebuffer
pccontrol_ARCHS = arm64 arm64e

pccontrol_PRIVATE_FRAMEWORKS = IOKit
pccontrol_LIBRARIES = substrate
pccontrol_CODESIGN_FLAGS = -Sentitlements.plist

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "chown -R mobile:mobile /var/mobile/Library/ZXTouch && killall -9 SpringBoard;"
