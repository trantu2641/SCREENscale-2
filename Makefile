TARGET := iphone:clang:16.5:16.0
ARCHS := arm64 arm64e

include $(THEOS)/makefiles/common.mk

TWEAK_NAME := ScreenScale16

ScreenScale16_FILES := Tweak.xm
ScreenScale16_CFLAGS := -fobjc-arc
ScreenScale16_FRAMEWORKS := UIKit Foundation QuartzCore CoreGraphics

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 SpringBoard"
