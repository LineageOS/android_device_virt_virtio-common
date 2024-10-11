#
# Copyright (C) 2024 The LineageOS Project
#
# SPDX-License-Identifier: Apache-2.0
#

# Inherit from common
$(call inherit-product, device/virt/virt-common/virt-common.mk)

COMMON_PATH := device/virt/virtio-common

# Graphics (Composer)
PRODUCT_PACKAGES += \
    com.android.hardware.graphics.composer.drm_hwcomposer

# Graphics (Gralloc)
PRODUCT_PACKAGES += \
    android.hardware.graphics.allocator-service.minigbm \
    gralloc.minigbm \
    mapper.minigbm

# Init
PRODUCT_COPY_FILES += \
    $(COMMON_PATH)/configs/init/init.virtio.rc:$(TARGET_COPY_OUT_VENDOR)/etc/init/hw/init.virtio.rc

PRODUCT_PACKAGES += \
    fstab.virtio \
    fstab.virtio.gsi.sda \
    fstab.virtio.gsi.vdc

# Input
PRODUCT_COPY_FILES += \
    $(COMMON_PATH)/configs/.emptyfile:$(TARGET_COPY_OUT_VENDOR)/usr/keylayout/QEMU_QEMU_USB_Tablet.kl \
    $(COMMON_PATH)/configs/.emptyfile:$(TARGET_COPY_OUT_VENDOR)/usr/keylayout/QEMU_Virtio_Tablet.kl

# Kernel
TARGET_PREBUILT_KERNEL_USE ?= 6.6
TARGET_PREBUILT_KERNEL_DIR := device/virt/kernel-virtio/$(TARGET_PREBUILT_KERNEL_USE)/$(TARGET_PREBUILT_KERNEL_ARCH)
TARGET_KERNEL_SOURCE := kernel/virt/virtio
ifneq ($(wildcard $(TARGET_KERNEL_SOURCE)/Makefile),)
    $(warning Using source built kernel)
else ifneq ($(wildcard $(TARGET_PREBUILT_KERNEL_DIR)/kernel),)
    PRODUCT_COPY_FILES += $(TARGET_PREBUILT_KERNEL_DIR)/kernel:kernel
    $(warning Using prebuilt kernel from $(TARGET_PREBUILT_KERNEL_DIR)/kernel)
else
    KERNEL_ARTIFACTS_PATH := kernel/prebuilts/$(TARGET_PREBUILT_EMULATOR_KERNEL_USE)/$(TARGET_PREBUILT_KERNEL_ARCH)
    EMULATOR_KERNEL_FILE := $(KERNEL_ARTIFACTS_PATH)/kernel-$(TARGET_PREBUILT_EMULATOR_KERNEL_USE)
    PRODUCT_COPY_FILES += $(EMULATOR_KERNEL_FILE):kernel
    $(warning Using prebuilt kernel from $(EMULATOR_KERNEL_FILE))
endif

# Recovery
PRODUCT_COPY_FILES += \
    $(COMMON_PATH)/configs/init/init.recovery.virtio.rc:$(TARGET_COPY_OUT_RECOVERY)/root/init.recovery.virtio.rc

# Shipping API level
PRODUCT_SHIPPING_API_LEVEL := 35
PRODUCT_SHIPPING_VENDOR_API_LEVEL := 202504

# Soong namespaces
PRODUCT_SOONG_NAMESPACES += \
    $(COMMON_PATH)

# Vendor ramdisk
PRODUCT_PACKAGES += \
    fstab.virtio.vendor_ramdisk \
    fstab.virtio.gsi.sda.vendor_ramdisk \
    fstab.virtio.gsi.vdc.vendor_ramdisk
