#
# Copyright (C) 2024 The LineageOS Project
#
# SPDX-License-Identifier: Apache-2.0
#

LOCAL_PATH := $(call my-dir)

ifeq ($(USES_DEVICE_VIRT_VIRTIO_COMMON),true)

# Combine ramdisk
INSTALLED_COMBINED_RAMDISK_TARGET := $(PRODUCT_OUT)/combined-ramdisk.img
INSTALLED_COMBINED_RAMDISK_TARGET_DEPS := $(PRODUCT_OUT)/ramdisk.img $(PRODUCT_OUT)/vendor_ramdisk.img

$(INSTALLED_COMBINED_RAMDISK_TARGET): $(INSTALLED_COMBINED_RAMDISK_TARGET_DEPS)
	cat $^ > $@

.PHONY: combined-ramdisk
combined-ramdisk: $(INSTALLED_COMBINED_RAMDISK_TARGET)

include $(call all-makefiles-under,$(LOCAL_PATH))

endif