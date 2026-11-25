# Powercuff (roothide)

TARGET := iphone:clang:16.5:15.0
ARCHS := arm64e
THEOS_PACKAGE_SCHEME := roothide
FINALPACKAGE := 1
DEBUG := 0

include $(THEOS)/makefiles/common.mk

TWEAK_NAME := Powercuff
Powercuff_FILES := Powercuff.x
Powercuff_FRAMEWORKS := Foundation
Powercuff_LIBRARIES := roothide
Powercuff_CFLAGS := -fno-objc-arc -Wall -Wextra
Powercuff_USE_MODULES := 0
INSTALL_TARGET_PROCESSES := thermalmonitord SpringBoard

include $(THEOS_MAKE_PATH)/tweak.mk
