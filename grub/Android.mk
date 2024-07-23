#
# Copyright (C) 2024 The LineageOS Project
#
# SPDX-License-Identifier: Apache-2.0
#

COMMON_GRUB_PATH := $(call my-dir)

ifeq ($(TARGET_GRUB_ARCH),)
$(warning TARGET_GRUB_ARCH is not defined, could not build GRUB)
else
GRUB_PREBUILT_DIR := prebuilts/grub/$(HOST_PREBUILT_TAG)/$(TARGET_GRUB_ARCH)
TOOLS_LINEAGE_BIN_DIR := prebuilts/tools-lineage/$(HOST_PREBUILT_TAG)/bin
PATH_OVERRIDE := PATH=$(TOOLS_LINEAGE_BIN_DIR):$$PATH
XORRISO_EXEC := $(TOOLS_LINEAGE_BIN_DIR)/xorriso

WORKDIR_BASE := $(TARGET_OUT_INTERMEDIATES)/GRUB_OBJ
WORKDIR_BOOT := $(WORKDIR_BASE)/boot

ifneq ($(LINEAGE_BUILD),)
ANDROID_DISTRIBUTION_NAME := LineageOS $(PRODUCT_VERSION_MAJOR).$(PRODUCT_VERSION_MINOR)
ARTIFACT_FILENAME_PREFIX := lineage-$(LINEAGE_VERSION)
else
LOCAL_BUILD_DATE := $(shell date -u +%Y%m%d)
ANDROID_DISTRIBUTION_NAME := Android $(PLATFORM_VERSION_LAST_STABLE) $(BUILD_ID)
ARTIFACT_FILENAME_PREFIX := Android-$(PLATFORM_VERSION_LAST_STABLE)-$(BUILD_ID)-$(LOCAL_BUILD_DATE)
endif

# $(1): output file
# $(2): dependencies
define make-isoimage-boot-target
	$(call pretty,"Target boot ISO image: $@")
	mkdir -p $(WORKDIR_BOOT)/boot/grub
	cp $(COMMON_GRUB_PATH)/grub-boot.cfg $(WORKDIR_BOOT)/boot/grub/grub.cfg
	sed -i "s|@ANDROID_DISTRIBUTION_NAME@|$(ANDROID_DISTRIBUTION_NAME)|g" $(WORKDIR_BOOT)/boot/grub/grub.cfg
	sed -i "s|@STRIPPED_TARGET_GRUB_KERNEL_CMDLINE@|$(strip $(TARGET_GRUB_KERNEL_CMDLINE))|g" $(WORKDIR_BOOT)/boot/grub/grub.cfg
	$(PATH_OVERRIDE) $(GRUB_PREBUILT_DIR)/bin/grub-mkrescue -d $(GRUB_PREBUILT_DIR)/lib/grub/$(TARGET_GRUB_ARCH) --xorriso=$(XORRISO_EXEC) -o $(1) $(2) $(WORKDIR_BOOT)
endef

INSTALLED_ISOIMAGE_BOOT_TARGET := $(PRODUCT_OUT)/$(ARTIFACT_FILENAME_PREFIX)-boot.iso
INSTALLED_ISOIMAGE_BOOT_TARGET_DEPS := $(PRODUCT_OUT)/kernel $(INSTALLED_COMBINED_RAMDISK_TARGET)
$(INSTALLED_ISOIMAGE_BOOT_TARGET): $(INSTALLED_ISOIMAGE_BOOT_TARGET_DEPS)
	$(call make-isoimage-boot-target,$(INSTALLED_ISOIMAGE_BOOT_TARGET),$(INSTALLED_ISOIMAGE_BOOT_TARGET_DEPS))

.PHONY: isoimage-boot
isoimage-boot: $(INSTALLED_ISOIMAGE_BOOT_TARGET)

.PHONY: isoimage-boot-nodeps
isoimage-boot-nodeps:
	@echo "make $(INSTALLED_ISOIMAGE_BOOT_TARGET): ignoring dependencies"
	$(call make-isoimage-boot-target,$(INSTALLED_ISOIMAGE_BOOT_TARGET),$(INSTALLED_ISOIMAGE_BOOT_TARGET_DEPS))

endif
