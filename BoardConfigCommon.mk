#
# Copyright (C) 2024 The LineageOS Project
#
# SPDX-License-Identifier: Apache-2.0
#

USES_DEVICE_VIRT_VIRTIO_COMMON := true
COMMON_PATH := device/virt/virtio-common

# Bootloader
TARGET_NO_BOOTLOADER := true

# Display
TARGET_SCREEN_DENSITY := 160

# Filesystem
BOARD_EXT4_SHARE_DUP_BLOCKS :=
BOARD_EROFS_COMPRESSOR := none
BOARD_EROFS_SHARE_DUP_BLOCKS := true
TARGET_USERIMAGES_SPARSE_EXT_DISABLED := true
TARGET_USERIMAGES_USE_F2FS := true
TARGET_USERIMAGES_USE_EXT4 := true

# Graphics
ifeq ($(TARGET_USES_SWIFTSHADER),true)
include device/google/cuttlefish/shared/swiftshader/BoardConfig.mk
else
include device/google/cuttlefish/shared/virgl/BoardConfig.mk
endif

# Kernel
BOARD_KERNEL_CMDLINE := \
    loop.max_part=7 \
    printk.devkmsg=on \
    rw \
    androidboot.boot_devices=any \
    androidboot.hardware=virtio \
    androidboot.partition_map=vda,vendor;vdb,system \
    androidboot.verifiedbootstate=orange

BOARD_KERNEL_CMDLINE += \
    audit=0 \
    log_buf_len=4M \
    androidboot.selinux=permissive

ifneq ($(wildcard $(TARGET_KERNEL_SOURCE)/Makefile),)
TARGET_KERNEL_CONFIG := \
    gki_defconfig \
    lineageos/virtio.config
else
TARGET_NO_KERNEL := true

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

# OTA
TARGET_SKIP_OTA_PACKAGE := true

# Partitions
BOARD_FLASH_BLOCK_SIZE := 4096
BOARD_VENDORIMAGE_FILE_SYSTEM_TYPE := ext4
BOARD_VENDORIMAGE_PARTITION_RESERVED_SIZE := 67108864 # 64 MB
TARGET_COPY_OUT_VENDOR := vendor

BOARD_SYSTEMIMAGE_FILE_SYSTEM_TYPE ?= ext4
ifeq ($(BOARD_SYSTEMIMAGE_FILE_SYSTEM_TYPE),ext4)
    ifeq ($(PRODUCT_IS_AUTOMOTIVE),true)
        BOARD_SYSTEMIMAGE_PARTITION_RESERVED_SIZE := 67108864 # 64 MB
    else
        BOARD_SYSTEMIMAGE_PARTITION_RESERVED_SIZE := 1073741824 # 1 GB
    endif
else ifeq ($(BOARD_SYSTEMIMAGE_FILE_SYSTEM_TYPE),erofs)
# empty
else
$(error BOARD_SYSTEMIMAGE_FILE_SYSTEM_TYPE is invalid)
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

# RIL
ENABLE_VENDOR_RIL_SERVICE := true

# Security patch level
VENDOR_SECURITY_PATCH = $(PLATFORM_SECURITY_PATCH)

# SELinux
BOARD_VENDOR_SEPOLICY_DIRS := \
    $(COMMON_PATH)/sepolicy/vendor \
    device/google/cuttlefish/shared/graphics/sepolicy \
    external/minigbm/cros_gralloc/sepolicy

ifeq ($(TARGET_USES_SWIFTSHADER),true)
BOARD_VENDOR_SEPOLICY_DIRS += \
    device/google/cuttlefish/shared/swiftshader/sepolicy
else
BOARD_VENDOR_SEPOLICY_DIRS += \
    device/google/cuttlefish/shared/virgl/sepolicy
endif

# VINTF
DEVICE_MANIFEST_FILE := \
    $(COMMON_PATH)/config/manifest.xml
