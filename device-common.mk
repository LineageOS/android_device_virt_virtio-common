#
# SPDX-FileCopyrightText: The LineageOS Project
# SPDX-License-Identifier: Apache-2.0
#

# Inherit from common
$(call inherit-product, device/virt/virt-common/virt-common.mk)

COMMON_PATH := device/virt/virtio-common

# Audio
TARGET_AUDIO_MAINLINE_UCM_PROFILES := base

# Graphics
PRODUCT_PACKAGES += \
    virtgpu_detect

# Graphics (Allocator)
TARGET_GRAPHICS_ALLOCATOR_HAL := minigbm-upstream
TARGET_MINIGBM_PLATFORM := generic

# Graphics (Composer)
TARGET_GRAPHICS_COMPOSER_HAL := drm_hwcomposer

# Init
PRODUCT_COPY_FILES += \
    $(COMMON_PATH)/configs/init/init.virtio.rc:$(TARGET_COPY_OUT_VENDOR)/etc/init/hw/init.virtio.rc

PRODUCT_PACKAGES += \
    fstab.virtio \
    fstab.virtio.gsi.sda \
    fstab.virtio.gsi.vdc

# Input
PRODUCT_COPY_FILES += \
    $(COMMON_PATH)/configs/input/excluded-input-devices.xml:$(TARGET_COPY_OUT_VENDOR)/etc/excluded-input-devices.xml

# Kernel
TARGET_PREBUILT_KERNEL_USE ?= 6.18
TARGET_PREBUILT_KERNEL_DIR := device/virt/kernel-virtio/$(TARGET_PREBUILT_KERNEL_USE)/$(TARGET_PREBUILT_KERNEL_ARCH)/$(TARGET_PREBUILT_KERNEL_PAGE_SIZE)
TARGET_KERNEL_SOURCE := kernel/virt/virtio
ifneq ($(wildcard $(TARGET_KERNEL_SOURCE)/Makefile),)
    $(warning Using source built kernel)
else ifneq ($(wildcard $(TARGET_PREBUILT_KERNEL_DIR)/kernel),)
    PRODUCT_COPY_FILES += $(TARGET_PREBUILT_KERNEL_DIR)/kernel:kernel
    $(warning Using prebuilt kernel from $(TARGET_PREBUILT_KERNEL_DIR)/kernel)
endif

# Recovery
PRODUCT_COPY_FILES += \
    $(COMMON_PATH)/configs/init/init.recovery.virtio.rc:$(TARGET_COPY_OUT_RECOVERY)/root/init.recovery.virtio.rc

# Shipping API level
TARGET_FOLLOWS_LATEST_SHIPPING_API_LEVEL := true

# Soong namespaces
PRODUCT_SOONG_NAMESPACES += \
    $(COMMON_PATH)

# Vendor ramdisk
PRODUCT_PACKAGES += \
    fstab.virtio.vendor_ramdisk \
    fstab.virtio.gsi.sda.vendor_ramdisk \
    fstab.virtio.gsi.vdc.vendor_ramdisk

# VINTF
TARGET_FOLLOWS_LATEST_VINTF_TARGET_LEVEL := true
