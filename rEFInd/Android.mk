#
# Copyright (C) 2024 The LineageOS Project
#
# SPDX-License-Identifier: Apache-2.0
#

COMMON_REFIND_PATH := $(call my-dir)

ifeq ($(TARGET_BOOT_MANAGER),rEFInd)
REFIND_PREBUILT_DIR := prebuilts/rEFInd

REFIND_WORKDIR_BASE := $(TARGET_OUT_INTERMEDIATES)/REFIND_OBJ
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
	$(foreach drv,ext4,\
		cp $(REFIND_PREBUILT_DIR)/refind/drivers_$(REFIND_ARCH)/$(drv)_$(REFIND_ARCH).efi $(1)/drivers_$(REFIND_ARCH)/ &&\
	)true
	cp $(REFIND_PREBUILT_DIR)/refind/refind_$(REFIND_ARCH).efi $(1)/$(BOOTMGR_EFI_BOOT_FILENAME)
	cp -r $(REFIND_PREBUILT_DIR)/refind/icons $(1)/
	cp $(REFIND_PREBUILT_DIR)/LICENSE.txt $(1)/
endef

# $(1): output file
# $(2): dependencies
# $(3): workdir
# $(4): purpose (boot or install)
define make-espimage
	$(call copy-refind-files-to-efi-boot,$(3)/fsroot/EFI/BOOT)

	cp $(COMMON_REFIND_PATH)/refind-$(4).conf $(3)/fsroot/EFI/BOOT/refind.conf
	$(call process-bootmgr-cfg-common,$(3)/fsroot/EFI/BOOT/refind.conf)

	$(if $(LINEAGE_BUILD),\
		cp $(COMMON_REFIND_PATH)/icons/os_lineage.png $(3)/fsroot/EFI/BOOT/icons/ && \
		sed -i "s|os_linux.png|os_lineage.png|g" $(3)/fsroot/EFI/BOOT/refind.conf \
	)

	$(call create-espimage,$(1),$(3)/fsroot/EFI $(2),$(4))
endef

##### espimage #####

# $(1): output file
# $(2): dependencies
define make-espimage-target
	$(call pretty,"Target EFI System Partition image: $(1)")
	$(call make-espimage,$(1),$(2),$(REFIND_WORKDIR_ESP),boot)
endef

##### espimage-install #####

# $(1): output file
# $(2): dependencies (unused for now)
define make-espimage-install-target
	$(call pretty,"Target installer ESP image: $(1)")
	$(call make-espimage,$(1),$(2),$(REFIND_WORKDIR_INSTALL),install)
endef

endif # TARGET_BOOT_MANAGER
