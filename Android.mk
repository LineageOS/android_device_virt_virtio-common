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
INSTALLED_COMBINED_RAMDISK_RECOVERY_TARGET := $(PRODUCT_OUT)/combined-ramdisk-recovery.img
INSTALLED_COMBINED_RAMDISK_RECOVERY_TARGET_DEPS := $(PRODUCT_OUT)/ramdisk-recovery.img $(PRODUCT_OUT)/vendor_ramdisk.img

$(INSTALLED_COMBINED_RAMDISK_TARGET): $(INSTALLED_COMBINED_RAMDISK_TARGET_DEPS)
	cat $^ > $@

$(INSTALLED_COMBINED_RAMDISK_RECOVERY_TARGET): $(INSTALLED_COMBINED_RAMDISK_RECOVERY_TARGET_DEPS)
	cat $^ > $@

.PHONY: combined-ramdisk
combined-ramdisk: $(INSTALLED_COMBINED_RAMDISK_TARGET)

.PHONY: combined-ramdisk-recovery
combined-ramdisk-recovery: $(INSTALLED_COMBINED_RAMDISK_RECOVERY_TARGET)

# Common definitions for boot managers
BOOTMGR_TOOLS_LINEAGE_BIN_DIR := prebuilts/tools-lineage/$(HOST_PREBUILT_TAG)/bin
BOOTMGR_PATH_OVERRIDE := PATH=$(BOOTMGR_TOOLS_LINEAGE_BIN_DIR):$$PATH
BOOTMGR_XORRISO_EXEC := $(BOOTMGR_TOOLS_LINEAGE_BIN_DIR)/xorriso

ifeq ($(TARGET_ARCH),arm64)
BOOTMGR_EFI_BOOT_FILENAME := BOOTAA64.EFI
else ifeq ($(TARGET_ARCH),x86_64)
BOOTMGR_EFI_BOOT_FILENAME := BOOTX64.EFI
endif

ifneq ($(LINEAGE_BUILD),)
BOOTMGR_ANDROID_DISTRIBUTION_NAME := LineageOS $(PRODUCT_VERSION_MAJOR).$(PRODUCT_VERSION_MINOR)
BOOTMGR_ANDROID_OTA_PACKAGE_NAME := lineage-$(LINEAGE_VERSION).zip
BOOTMGR_ARTIFACT_FILENAME_PREFIX := lineage-$(LINEAGE_VERSION)
BOOTMGR_THEME := lineage
else
LOCAL_BUILD_DATE := $(shell date -u +%Y%m%d)
BOOTMGR_ANDROID_DISTRIBUTION_NAME := Android $(PLATFORM_VERSION_LAST_STABLE) $(BUILD_ID)
BOOTMGR_ANDROID_OTA_PACKAGE_NAME := $(TARGET_PRODUCT)-ota.zip
BOOTMGR_ARTIFACT_FILENAME_PREFIX := Android-$(PLATFORM_VERSION_LAST_STABLE)-$(BUILD_ID)-$(LOCAL_BUILD_DATE)-$(TARGET_PRODUCT)
BOOTMGR_THEME := android
endif

ifeq ($(PRODUCT_IS_AUTOMOTIVE),true)
BOOTMGR_ANDROID_DISTRIBUTION_NAME += Car
else ifeq ($(PRODUCT_IS_ATV),true)
BOOTMGR_ANDROID_DISTRIBUTION_NAME += TV
endif

INSTALLED_ESPIMAGE_TARGET := $(TARGET_OUT_INTERMEDIATES)/CUSTOM_IMAGES/EFI.img
INSTALLED_ISOIMAGE_BOOT_TARGET := $(PRODUCT_OUT)/$(BOOTMGR_ARTIFACT_FILENAME_PREFIX)-boot.iso
INSTALLED_ISOIMAGE_INSTALL_TARGET := $(PRODUCT_OUT)/$(BOOTMGR_ARTIFACT_FILENAME_PREFIX).iso

INSTALLED_ESPIMAGE_TARGET_DEPS := \
	$(PRODUCT_OUT)/kernel \
	$(INSTALLED_COMBINED_RAMDISK_TARGET) \
	$(INSTALLED_COMBINED_RAMDISK_RECOVERY_TARGET)

INSTALLED_ISOIMAGE_BOOT_TARGET_DEPS := \
	$(INSTALLED_ESPIMAGE_TARGET_DEPS)

INSTALLED_ISOIMAGE_INSTALL_TARGET_DEPS := \
	$(PRODUCT_OUT)/kernel \
	$(INSTALLED_COMBINED_RAMDISK_RECOVERY_TARGET) \
	$(PRODUCT_OUT)/$(BOOTMGR_ANDROID_OTA_PACKAGE_NAME)

INSTALLED_ESPIMAGE_TARGET_EXTRA_DEPS :=
INSTALLED_ISOIMAGE_BOOT_TARGET_EXTRA_DEPS :=
INSTALLED_ISOIMAGE_INSTALL_TARGET_EXTRA_DEPS :=

# $(1): output file
# $(2): list of contents to include
define create-espimage
	/bin/dd if=/dev/zero of=$(1) bs=1M count=$$($(COMMON_PATH)/.calc_fat32_img_size.sh $(2))
	$(BOOTMGR_TOOLS_LINEAGE_BIN_DIR)/mformat -F -i $(1) ::
	$(foreach content,$(2),$(BOOTMGR_TOOLS_LINEAGE_BIN_DIR)/mcopy -i $(1) -s $(content) :: &&)true
endef

# $(1): output file
# $(2): list of contents to include
# $(3): path to EFI image in ISO image
define create-isoimage
	$(BOOTMGR_XORRISO_EXEC) -as mkisofs -no-emul-boot -e $(3) -volid "$(TARGET_DEVICE) with $(TARGET_BOOT_MANAGER)" -o $(1) $(2)
endef

# $(1): path to boot manager config file
define process-bootmgr-cfg-common
	sed -i "s|@BOOTMGR_ANDROID_DISTRIBUTION_NAME@|$(BOOTMGR_ANDROID_DISTRIBUTION_NAME)|g" $(1)
	sed -i "s|@BOOTMGR_EFI_BOOT_FILENAME@|$(BOOTMGR_EFI_BOOT_FILENAME)|g" $(1)
	sed -i "s|@STRIPPED_BOARD_KERNEL_CMDLINE_CONSOLE@|$(strip $(BOARD_KERNEL_CMDLINE_CONSOLE))|g" $(1)
	sed -i "s|@STRIPPED_TARGET_BOOTMGR_KERNEL_CMDLINE@|$(strip $(TARGET_BOOTMGR_KERNEL_CMDLINE))|g" $(1)
endef

include $(call all-makefiles-under,$(LOCAL_PATH))

# Build boot manager images

ifneq ($(TARGET_BOOT_MANAGER),)

##### espimage #####

$(INSTALLED_ESPIMAGE_TARGET): $(INSTALLED_ESPIMAGE_TARGET_DEPS) $(INSTALLED_ESPIMAGE_TARGET_EXTRA_DEPS)
	$(hide) mkdir -p $(dir $@)
	$(call make-espimage-target,$(INSTALLED_ESPIMAGE_TARGET),$(INSTALLED_ESPIMAGE_TARGET_DEPS))

.PHONY: espimage
espimage: $(INSTALLED_ESPIMAGE_TARGET)

.PHONY: espimage-nodeps
espimage-nodeps:
	@echo "make $(INSTALLED_ESPIMAGE_TARGET): ignoring dependencies"
	$(hide) mkdir -p $(dir $@)
	$(call make-espimage-target,$(INSTALLED_ESPIMAGE_TARGET),$(INSTALLED_ESPIMAGE_TARGET_DEPS))

ALL_DEFAULT_INSTALLED_MODULES += $(PRODUCT_OUT)/EFI.img

##### isoimage-boot #####

$(INSTALLED_ISOIMAGE_BOOT_TARGET): $(INSTALLED_ISOIMAGE_BOOT_TARGET_DEPS) $(INSTALLED_ISOIMAGE_BOOT_TARGET_EXTRA_DEPS)
	$(call make-isoimage-boot-target,$(INSTALLED_ISOIMAGE_BOOT_TARGET),$(INSTALLED_ISOIMAGE_BOOT_TARGET_DEPS))

.PHONY: isoimage-boot
isoimage-boot: $(INSTALLED_ISOIMAGE_BOOT_TARGET)

.PHONY: isoimage-boot-nodeps
isoimage-boot-nodeps:
	@echo "make $(INSTALLED_ISOIMAGE_BOOT_TARGET): ignoring dependencies"
	$(call make-isoimage-boot-target,$(INSTALLED_ISOIMAGE_BOOT_TARGET),$(INSTALLED_ISOIMAGE_BOOT_TARGET_DEPS))

##### isoimage-install #####

$(INSTALLED_ISOIMAGE_INSTALL_TARGET): $(INSTALLED_ISOIMAGE_INSTALL_TARGET_DEPS) $(INSTALLED_ISOIMAGE_INSTALL_TARGET_EXTRA_DEPS)
	$(call make-isoimage-install-target,$(INSTALLED_ISOIMAGE_INSTALL_TARGET),$(INSTALLED_ISOIMAGE_INSTALL_TARGET_DEPS))

.PHONY: isoimage-install
isoimage-install: $(INSTALLED_ISOIMAGE_INSTALL_TARGET)

.PHONY: isoimage-install-nodeps
isoimage-install-nodeps:
	@echo "make $(INSTALLED_ISOIMAGE_INSTALL_TARGET): ignoring dependencies"
	$(call make-isoimage-install-target,$(INSTALLED_ISOIMAGE_INSTALL_TARGET),$(INSTALLED_ISOIMAGE_INSTALL_TARGET_DEPS))

endif # TARGET_BOOT_MANAGER

# Create vda disk image

SGDISK_EXEC := out/host/linux-x86/bin/sgdisk

DISK_VDA_SECTOR_SIZE := 512
DISK_VDA_SECTORS := 12582912
DISK_VDA_PARTITION_EFI_START_SECTOR := 2048
DISK_VDA_PARTITION_SUPER_START_SECTOR := 264192
DISK_VDA_PARTITION_MISC_START_SECTOR := 8663040
DISK_VDA_PARTITION_METADATA_START_SECTOR := 8665088
DISK_VDA_PARTITION_CACHE_START_SECTOR := 8730624
DISK_VDA_PARTITION_BOOT_START_SECTOR := 8834816
DISK_VDA_PARTITION_RECOVERY_START_SECTOR := 8965888
DISK_VDA_PARTITION_EFI_SECTORS := 262144
DISK_VDA_PARTITION_SUPER_SECTORS := 8388608
DISK_VDA_PARTITION_MISC_SECTORS := 2048
DISK_VDA_PARTITION_METADATA_SECTORS := 65536
DISK_VDA_PARTITION_CACHE_SECTORS := 102400
DISK_VDA_PARTITION_BOOT_SECTORS := 131072
DISK_VDA_PARTITION_RECOVERY_SECTORS := 131072

DISK_VDA_WRITE_PARTITIONS := \
	$(BOARD_CUSTOMIMAGES_PARTITION_LIST) \
	super \
	cache \
	boot \
	recovery

# $(1): output file
# $(2): disk name
define make-diskimage-target
	$(call pretty,"Target $(2) disk image: $(1)")
	/bin/dd if=/dev/zero of=$(1) bs=$(DISK_$(call to-upper,$(2))_SECTOR_SIZE) count=$(DISK_$(call to-upper,$(2))_SECTORS)
	/bin/sh -e $(COMMON_PATH)/config/create_partition_table.sh $(SGDISK_EXEC) $(1) $(2)
	$(foreach p,$(DISK_$(call to-upper,$(2))_WRITE_PARTITIONS),\
		/bin/dd if=$(PRODUCT_OUT)/$(p).img of=$(1) bs=$(DISK_$(call to-upper,$(2))_SECTOR_SIZE) seek=$(DISK_$(call to-upper,$(2))_PARTITION_$(call to-upper,$(p))_START_SECTOR) count=$(DISK_$(call to-upper,$(2))_PARTITION_$(call to-upper,$(p))_SECTORS) conv=notrunc &&\
	)true
endef

INSTALLED_DISKIMAGE_VDA_TARGET := $(PRODUCT_OUT)/disk-vda.img
INSTALLED_DISKIMAGE_VDA_TARGET_DEPS := $(SGDISK_EXEC)
$(foreach p,$(DISK_VDA_WRITE_PARTITIONS),\
	$(eval INSTALLED_DISKIMAGE_VDA_TARGET_DEPS += $(PRODUCT_OUT)/$(p).img))
$(INSTALLED_DISKIMAGE_VDA_TARGET): $(INSTALLED_DISKIMAGE_VDA_TARGET_DEPS)
	$(call make-diskimage-target,$(INSTALLED_DISKIMAGE_VDA_TARGET),vda)

.PHONY: diskimage-vda
diskimage-vda: $(INSTALLED_DISKIMAGE_VDA_TARGET)

.PHONY: diskimage-vda-nodeps
diskimage-vda-nodeps:
	@echo "make $(INSTALLED_DISKIMAGE_VDA_TARGET): ignoring dependencies"
	$(call make-diskimage-target,$(INSTALLED_DISKIMAGE_VDA_TARGET),vda)

endif
