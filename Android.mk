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

include $(call all-makefiles-under,$(LOCAL_PATH))

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
	EFI \
	super \
	cache \
	boot \
	recovery

# $(1): output file
# $(2): disk name
define make-diskimage-target
	$(call pretty,"Target $(2) disk image: $(1)")
	/bin/dd if=/dev/zero of=$(1) bs=$(DISK_$(call to-upper,$(2))_SECTOR_SIZE) count=$(DISK_$(call to-upper,$(2))_SECTORS)
	/bin/sh $(COMMON_PATH)/config/create_partition_table.sh $(SGDISK_EXEC) $(1)
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
