#
# Copyright (C) 2024 The LineageOS Project
#
# SPDX-License-Identifier: Apache-2.0
#

# Inherit from common
include device/virt/virt-common/BoardConfigVirtCommon.mk

USES_DEVICE_VIRT_VIRTIO_COMMON := true

# Boot manager
TARGET_GRUB_BOOT_CONFIGS += $(COMMON_PATH)/bootmgr/grub/grub-boot.cfg
TARGET_GRUB_INSTALL_CONFIGS += $(COMMON_PATH)/bootmgr/grub/grub-install.cfg
TARGET_REFIND_BOOT_CONFIG := $(COMMON_PATH)/bootmgr/rEFInd/refind-boot.conf
TARGET_REFIND_INSTALL_CONFIG := $(COMMON_PATH)/bootmgr/rEFInd/refind-install.conf

# Bootconfig
TARGET_BOOTCONFIG_FILES += $(COMMON_PATH)/configs/misc/bootconfig.txt

# Fstab
ifeq ($(AB_OTA_UPDATER),true)
$(call soong_config_set,VIRTIO_FSTAB,PARTITION_SCHEME,ab)
else
$(call soong_config_set,VIRTIO_FSTAB,PARTITION_SCHEME,a)
endif

# Graphics (Mesa)
BOARD_MESA3D_GALLIUM_DRIVERS += virgl
BOARD_MESA3D_VULKAN_DRIVERS += virtio

# Kernel
BOARD_KERNEL_CMDLINE += \
    console=tty0

ifneq ($(wildcard $(TARGET_KERNEL_SOURCE)/Makefile),)
TARGET_KERNEL_CONFIG += \
    lineageos/virtio.config
else ifneq ($(wildcard $(TARGET_PREBUILT_KERNEL_DIR)/kernel),)
BOARD_VENDOR_KERNEL_MODULES := \
    $(wildcard $(TARGET_PREBUILT_KERNEL_DIR)/*.ko)
else
VIRTUAL_DEVICE_KERNEL_MODULES_PATH := \
    kernel/prebuilts/common-modules/virtual-device/$(TARGET_PREBUILT_EMULATOR_KERNEL_USE)/$(TARGET_PREBUILT_KERNEL_MODULES_ARCH)

BOARD_SYSTEM_KERNEL_MODULES := $(wildcard $(KERNEL_ARTIFACTS_PATH)/*.ko)

BOARD_VENDOR_RAMDISK_KERNEL_MODULES := \
    $(wildcard $(VIRTUAL_DEVICE_KERNEL_MODULES_PATH)/*failover.ko) \
    $(wildcard $(VIRTUAL_DEVICE_KERNEL_MODULES_PATH)/nd_virtio.ko) \
    $(wildcard $(VIRTUAL_DEVICE_KERNEL_MODULES_PATH)/virtio*.ko)

BOARD_VENDOR_KERNEL_MODULES := \
    $(filter-out $(BOARD_VENDOR_RAMDISK_KERNEL_MODULES),\
                 $(wildcard $(VIRTUAL_DEVICE_KERNEL_MODULES_PATH)/*.ko))
endif

# Properties
TARGET_VENDOR_PROP += $(COMMON_PATH)/configs/properties/vendor.prop

# Recovery
TARGET_RECOVERY_FSTAB_GENRULE := gen_fstab_virtio
TARGET_RECOVERY_PIXEL_FORMAT := ARGB_8888

# SELinux
BOARD_VENDOR_SEPOLICY_DIRS += \
    $(COMMON_PATH)/sepolicy/vendor

ifeq ($(AB_OTA_UPDATER),true)
BOARD_VENDOR_SEPOLICY_DIRS += \
    $(COMMON_PATH)/sepolicy/vendor/ab
else
BOARD_VENDOR_SEPOLICY_DIRS += \
    $(COMMON_PATH)/sepolicy/vendor/a
endif

SYSTEM_EXT_PRIVATE_SEPOLICY_DIRS += $(COMMON_PATH)/sepolicy/private
SYSTEM_EXT_PUBLIC_SEPOLICY_DIRS += $(COMMON_PATH)/sepolicy/public

# VINTF
DEVICE_MANIFEST_FILE += \
    $(COMMON_PATH)/configs/vintf/manifest.xml
