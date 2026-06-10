include $(THEOS)/makefiles/common.mk

TOOL_NAME = zxtouchb
zxtouchb_ARCHS = arm64 arm64e

zxtouchb_FILES = main.mm
zxtouchb_CFLAGS = -fobjc-arc -Wno-error -Wno-module-import-in-extern-c -O2 -DNDEBUG
zxtouchb_FRAMEWORKS = Foundation

include $(THEOS_MAKE_PATH)/tool.mk
