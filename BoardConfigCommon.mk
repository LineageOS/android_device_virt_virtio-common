#
# Copyright (C) 2024 The LineageOS Project
#
# SPDX-License-Identifier: Apache-2.0
#

# Inherit from common
include device/virt/virt-common/BoardConfigVirtCommon.mk

USES_DEVICE_VIRT_VIRTIO_COMMON := true
COMMON_PATH := device/virt/virtio-common

# Boot manager
TARGET_GRUB_BOOT_CONFIG := $(COMMON_PATH)/bootmgr/grub/grub-boot.cfg
TARGET_GRUB_INSTALL_CONFIG := $(COMMON_PATH)/bootmgr/grub/grub-install.cfg
TARGET_REFIND_BOOT_CONFIG := $(COMMON_PATH)/bootmgr/rEFInd/refind-boot.conf
TARGET_REFIND_INSTALL_CONFIG := $(COMMON_PATH)/bootmgr/rEFInd/refind-install.conf

# Graphics (Mesa)
ifneq ($(wildcard external/mesa/android/Android.mk),)
BUILD_BROKEN_INCORRECT_PARTITION_IMAGES := true
BOARD_MESA3D_USES_MESON_BUILD := true
BOARD_MESA3D_GALLIUM_DRIVERS := virgl
BOARD_MESA3D_VULKAN_DRIVERS := virtio
else
BOARD_GPU_DRIVERS := virgl
endif

# Kernel
BOARD_KERNEL_CMDLINE += \
    console=tty0 \
    androidboot.console=hvc0 \
    androidboot.hardware=virtio

# Recovery
TARGET_RECOVERY_FSTAB := $(COMMON_PATH)/config/fstab.virtio
TARGET_RECOVERY_PIXEL_FORMAT := ARGB_8888

# SELinux
BOARD_VENDOR_SEPOLICY_DIRS += \
    $(COMMON_PATH)/sepolicy/vendor

SYSTEM_EXT_PRIVATE_SEPOLICY_DIRS += $(COMMON_PATH)/sepolicy/private
SYSTEM_EXT_PUBLIC_SEPOLICY_DIRS += $(COMMON_PATH)/sepolicy/public

# VINTF
DEVICE_MANIFEST_FILE += \
    $(COMMON_PATH)/config/manifest.xml
