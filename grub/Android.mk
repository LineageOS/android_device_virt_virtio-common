#
# Copyright (C) 2024 The LineageOS Project
#
# SPDX-License-Identifier: Apache-2.0
#

COMMON_GRUB_PATH := $(call my-dir)

ifeq ($(GRUB_ARCH),)
$(warning GRUB_ARCH is not defined, could not build GRUB)
else
GRUB_PREBUILT_DIR := prebuilts/grub/$(HOST_PREBUILT_TAG)/$(GRUB_ARCH)
TOOLS_LINEAGE_BIN_DIR := prebuilts/tools-lineage/$(HOST_PREBUILT_TAG)/bin
XORRISO_EXEC := $(TOOLS_LINEAGE_BIN_DIR)/xorriso

ARTIFACT_FILENAME_PREFIX := grub
PATH_OVERRIDE := PATH=$(TOOLS_LINEAGE_BIN_DIR):$$PATH
WORKDIR := $(TARGET_OUT_INTERMEDIATES)/GRUB_OBJ

ifneq ($(LINEAGE_BUILD),)
ANDROID_DISTRIBUTION_NAME := LineageOS 21
else
ANDROID_DISTRIBUTION_NAME := Android
endif

INSTALLED_ISOIMAGE_TARGET := $(PRODUCT_OUT)/$(ARTIFACT_FILENAME_PREFIX).iso
INSTALLED_ISOIMAGE_TARGET_DEPS := $(PRODUCT_OUT)/kernel $(PRODUCT_OUT)/ramdisk.img $(PRODUCT_OUT)/ramdisk-recovery.img
$(INSTALLED_ISOIMAGE_TARGET): $(INSTALLED_ISOIMAGE_TARGET_DEPS)
	$(call pretty,"Target ISO image: $@")
	mkdir -p $(WORKDIR)/boot/grub
	cp $(COMMON_GRUB_PATH)/grub.cfg $(WORKDIR)/boot/grub/
	sed -i "s|@ANDROID_DISTRIBUTION_NAME@|$(ANDROID_DISTRIBUTION_NAME)|g" $(WORKDIR)/boot/grub/grub.cfg
	sed -i "s|@STRIPPED_BOARD_KERNEL_CMDLINE_BASE@|$(strip $(BOARD_KERNEL_CMDLINE_BASE))|g" $(WORKDIR)/boot/grub/grub.cfg
	$(PATH_OVERRIDE) $(GRUB_PREBUILT_DIR)/bin/grub-mkrescue -d $(GRUB_PREBUILT_DIR)/lib/grub/$(GRUB_ARCH) --xorriso=$(XORRISO_EXEC) -o $(INSTALLED_ISOIMAGE_TARGET) $(INSTALLED_ISOIMAGE_TARGET_DEPS) $(WORKDIR)

.PHONY: isoimage
isoimage: $(INSTALLED_ISOIMAGE_TARGET)
endif
