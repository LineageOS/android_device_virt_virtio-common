#
# Copyright (C) 2024 The LineageOS Project
#
# SPDX-License-Identifier: Apache-2.0
#

COMMON_REFIND_PATH := $(call my-dir)

ifeq ($(TARGET_BOOT_MANAGER),rEFInd)
REFIND_PREBUILT_DIR := prebuilts/rEFInd

REFIND_WORKDIR_BASE := $(TARGET_OUT_INTERMEDIATES)/REFIND_OBJ
REFIND_WORKDIR_BOOT := $(REFIND_WORKDIR_BASE)/boot
REFIND_WORKDIR_ESP := $(REFIND_WORKDIR_BASE)/esp
REFIND_WORKDIR_INSTALL := $(REFIND_WORKDIR_BASE)/install

ifeq ($(TARGET_ARCH),arm64)
REFIND_ARCH := aa64
else ifeq ($(TARGET_ARCH),x86_64)
REFIND_ARCH := x64
endif

# $(1): path to /EFI/BOOT
define copy-refind-files-to-efi-boot
	mkdir -p $(1)/drivers_$(REFIND_ARCH)
	$(foreach drv,ext4 iso9660,\
		cp $(REFIND_PREBUILT_DIR)/refind/drivers_$(REFIND_ARCH)/$(drv)_$(REFIND_ARCH).efi $(1)/drivers_$(REFIND_ARCH)/ &&\
	)true
	cp $(REFIND_PREBUILT_DIR)/refind/refind_$(REFIND_ARCH).efi $(1)/$(BOOTMGR_EFI_BOOT_FILENAME)
	cp -r $(REFIND_PREBUILT_DIR)/refind/icons $(1)/
	cp $(REFIND_PREBUILT_DIR)/refind/LICENSE.txt $(1)/
endef

##### espimage #####

# $(1): output file
# $(2): dependencies
define make-espimage-target
	$(call pretty,"Target EFI System Partition image: $(1)")
	$(call copy-refind-files-to-efi-boot,$(REFIND_WORKDIR_ESP)/fsroot/EFI/BOOT)

	cp $(COMMON_REFIND_PATH)/refind-boot.conf $(REFIND_WORKDIR_ESP)/fsroot/EFI/BOOT/refind.conf
	$(call process-bootmgr-cfg-common,$(REFIND_WORKDIR_ESP)/fsroot/EFI/BOOT/refind.conf)

	$(call create-espimage,$(1),$(REFIND_WORKDIR_ESP)/fsroot/EFI $(2))
endef

##### isoimage-boot #####

INSTALLED_ISOIMAGE_BOOT_TARGET_EXTRA_DEPS := $(INSTALLED_ESPIMAGE_TARGET)

# $(1): output file
# $(2): dependencies (unused for now)
define make-isoimage-boot-target
	$(call pretty,"Target boot ISO image: $(1)")
	$(call create-isoimage,$(1),$(INSTALLED_ESPIMAGE_TARGET),/EFI.img)
endef

##### isoimage-install #####

# $(1): output file
# $(2): dependencies (unused for now)
define make-isoimage-install-target
	$(call pretty,"Target installer ISO image: $(1)")
	$(call copy-refind-files-to-efi-boot,$(REFIND_WORKDIR_INSTALL)/EFI_fsroot/EFI/BOOT)

	cp $(COMMON_REFIND_PATH)/refind-install.conf $(REFIND_WORKDIR_INSTALL)/EFI_fsroot/EFI/BOOT/refind.conf
	$(call process-bootmgr-cfg-common,$(REFIND_WORKDIR_INSTALL)/EFI_fsroot/EFI/BOOT/refind.conf)

	$(call create-espimage,$(REFIND_WORKDIR_INSTALL)/EFI.img,$(REFIND_WORKDIR_ESP)/EFI_fsroot/EFI $(PRODUCT_OUT)/kernel $(INSTALLED_COMBINED_RAMDISK_RECOVERY_TARGET))

	$(call create-isoimage,$(1),$(PRODUCT_OUT)/$(BOOTMGR_ANDROID_OTA_PACKAGE_NAME) $(REFIND_WORKDIR_INSTALL)/EFI.img,/EFI.img)
endef

endif # TARGET_BOOT_MANAGER
