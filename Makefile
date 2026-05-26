TARGET := iphone:clang:latest:14.0
ARCHS := arm64

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = RegTelTweak

RegTelTweak_FILES = Tweak.xm RegressSettings.swift AyuThemeManager.swift AyuMessageTracker.swift
RegTelTweak_CFLAGS = -fobjc-arc
RegTelTweak_FRAMEWORKS = UIKit Foundation CoreGraphics Security

include $(THEOS_MAKE_PATH)/tweak.mk
