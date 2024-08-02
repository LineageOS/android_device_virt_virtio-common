#
# Copyright (C) 2024 The LineageOS Project
#
# SPDX-License-Identifier: Apache-2.0
#

USES_DEVICE_VIRT_VIRTIO_COMMON := true
COMMON_PATH := device/virt/virtio-common

# Bootloader
BOARD_BOOT_HEADER_VERSION := 3
BOARD_MKBOOTIMG_ARGS += --header_version $(BOARD_BOOT_HEADER_VERSION)
TARGET_NO_BOOTLOADER := true

# Fastboot
TARGET_BOARD_FASTBOOT_INFO_FILE := $(COMMON_PATH)/fastboot-info.txt

# Filesystem
BOARD_EXT4_SHARE_DUP_BLOCKS :=
BOARD_EROFS_COMPRESSOR := none
BOARD_EROFS_SHARE_DUP_BLOCKS := true
TARGET_USERIMAGES_SPARSE_EXT_DISABLED := true
TARGET_USERIMAGES_USE_F2FS := true
TARGET_USERIMAGES_USE_EXT4 := true

# Graphics
BOARD_GPU_DRIVERS := virgl

# Init
TARGET_INIT_VENDOR_LIB ?= //$(COMMON_PATH):init_virtio
TARGET_RECOVERY_DEVICE_MODULES ?= init_virtio

# Kernel
BOARD_KERNEL_CMDLINE_BASE := \
    console=tty0 \
    log_buf_len=4M \
    loop.max_part=7 \
    printk.devkmsg=on \
    rw \
    androidboot.boot_devices=any \
    androidboot.first_stage_console=0 \
    androidboot.hardware=virtio \
    androidboot.verifiedbootstate=orange

BOARD_KERNEL_CMDLINE_CONSOLE += \
    androidboot.console=hvc0

BOARD_KERNEL_CMDLINE := \
    $(BOARD_KERNEL_CMDLINE_BASE) \
    $(BOARD_KERNEL_CMDLINE_CONSOLE)

TARGET_BOOTMGR_KERNEL_CMDLINE := \
    $(BOARD_KERNEL_CMDLINE)

ifneq ($(wildcard $(TARGET_KERNEL_SOURCE)/Makefile),)
TARGET_KERNEL_CONFIG := \
    gki_defconfig \
    lineageos/virtio.config \
    lineageos/feature/fbcon.config
else ifneq ($(wildcard $(TARGET_PREBUILT_KERNEL_DIR)/kernel),)
BOARD_VENDOR_KERNEL_MODULES := \
    $(wildcard $(TARGET_PREBUILT_KERNEL_DIR)/*.ko)
else
VIRTUAL_DEVICE_KERNEL_MODULES_PATH := \
    kernel/prebuilts/common-modules/virtual-device/$(TARGET_PREBUILT_KERNEL_USE)/$(TARGET_PREBUILT_KERNEL_MODULES_ARCH)

BOARD_RECOVERY_KERNEL_MODULES := \
    $(wildcard $(VIRTUAL_DEVICE_KERNEL_MODULES_PATH)/*failover.ko) \
    $(wildcard $(VIRTUAL_DEVICE_KERNEL_MODULES_PATH)/nd_virtio.ko) \
    $(wildcard $(VIRTUAL_DEVICE_KERNEL_MODULES_PATH)/virtio*.ko)

BOARD_GENERIC_RAMDISK_KERNEL_MODULES := \
    $(wildcard $(KERNEL_ARTIFACTS_PATH)/*.ko) \
    $(wildcard $(VIRTUAL_DEVICE_KERNEL_MODULES_PATH)/*.ko)
endif

# Partitions
BOARD_FLASH_BLOCK_SIZE := 4096
BOARD_USES_METADATA_PARTITION := true

BOARD_CACHEIMAGE_FILE_SYSTEM_TYPE := ext4
BOARD_CACHEIMAGE_PARTITION_SIZE := 52428800 # 50 MB

DLKM_PARTITIONS := system_dlkm vendor_dlkm
SSI_PARTITIONS := product system system_ext
TREBLE_PARTITIONS := odm vendor
ALL_PARTITIONS := $(DLKM_PARTITIONS) $(SSI_PARTITIONS) $(TREBLE_PARTITIONS)

$(foreach p, $(DLKM_PARTITIONS), \
    $(eval BOARD_USES_$(call to-upper, $(p))IMAGE := true))

TARGET_LOGICAL_PARTITIONS_FILE_SYSTEM_TYPE ?= ext4
ifeq ($(TARGET_LOGICAL_PARTITIONS_FILE_SYSTEM_TYPE),ext4)
    BOARD_SUPER_PARTITION_SIZE := 4294967296 # 4 GB
    BOARD_SYSTEMIMAGE_EXTFS_INODE_COUNT := 8192
    BOARD_PRODUCTIMAGE_EXTFS_INODE_COUNT := 6144
    BOARD_SYSTEM_EXTIMAGE_EXTFS_INODE_COUNT := 4096
    BOARD_VENDORIMAGE_EXTFS_INODE_COUNT := 2048
    BOARD_ODMIMAGE_EXTFS_INODE_COUNT := 1024
    $(foreach p, $(call to-upper, $(SSI_PARTITIONS) $(TREBLE_PARTITIONS)), \
        $(eval BOARD_$(p)IMAGE_PARTITION_RESERVED_SIZE := 134217728)) # 128 MB
    ifneq ($(WITH_GMS),true)
        BOARD_PRODUCTIMAGE_PARTITION_RESERVED_SIZE := 1073741824 # 1 GB
    endif
else ifeq ($(TARGET_LOGICAL_PARTITIONS_FILE_SYSTEM_TYPE),erofs)
    BOARD_SUPER_PARTITION_SIZE := 3221225472 # 3 GB
else
    $(error TARGET_LOGICAL_PARTITIONS_FILE_SYSTEM_TYPE is invalid)
endif

BOARD_SUPER_PARTITION_GROUPS := virtio_dynamic_partitions
BOARD_VIRTIO_DYNAMIC_PARTITIONS_PARTITION_LIST := $(ALL_PARTITIONS)
BOARD_VIRTIO_DYNAMIC_PARTITIONS_SIZE := $(shell expr $(BOARD_SUPER_PARTITION_SIZE) - 4194304 )

$(foreach p, $(call to-upper, $(ALL_PARTITIONS)), \
    $(eval BOARD_$(p)IMAGE_FILE_SYSTEM_TYPE := $(TARGET_LOGICAL_PARTITIONS_FILE_SYSTEM_TYPE)) \
    $(eval TARGET_COPY_OUT_$(p) := $(call to-lower, $(p))))

ifneq ($(TARGET_BOOT_MANAGER),)
BOARD_CUSTOMIMAGES_PARTITION_LIST := EFI
BOARD_AVB_EFI_IMAGE_LIST := $(PRODUCT_OUT)/obj/CUSTOM_IMAGES/EFI.img
endif

# Platform
TARGET_BOARD_PLATFORM := virtio

# Properties
TARGET_PRODUCT_PROP := $(COMMON_PATH)/properties/product.prop
TARGET_VENDOR_PROP := $(COMMON_PATH)/properties/vendor.prop

# Ramdisk
BOARD_RAMDISK_USE_LZ4 := true

# Recovery
TARGET_RECOVERY_FSTAB := $(COMMON_PATH)/config/fstab.virtio
TARGET_RECOVERY_PIXEL_FORMAT := ARGB_8888
TARGET_RECOVERY_UI_LIB := librecovery_ui_virtio

# Releasetools
TARGET_RELEASETOOLS_EXTENSIONS := $(COMMON_PATH)

# RIL
ENABLE_VENDOR_RIL_SERVICE := true

# Security patch level
VENDOR_SECURITY_PATCH = $(PLATFORM_SECURITY_PATCH)

# SELinux
BOARD_VENDOR_SEPOLICY_DIRS := \
    $(COMMON_PATH)/sepolicy/vendor \
    device/google/cuttlefish/shared/graphics/sepolicy \
    device/google/cuttlefish/shared/swiftshader/sepolicy \
    device/google/cuttlefish/shared/virgl/sepolicy \
    external/minigbm/cros_gralloc/sepolicy

SYSTEM_EXT_PRIVATE_SEPOLICY_DIRS += $(COMMON_PATH)/sepolicy/private

# VINTF
DEVICE_MANIFEST_FILE := \
    $(COMMON_PATH)/config/manifest.xml \
    device/google/cuttlefish/guest/hals/audio/effects/manifest.xml
