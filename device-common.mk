#
# Copyright (C) 2024 The LineageOS Project
#
# SPDX-License-Identifier: Apache-2.0
#

# Inherit from common
$(call inherit-product, device/virt/virt-common/virt-common.mk)

# Graphics (Mesa)
ifneq ($(wildcard external/mesa/android/Android.mk),)
PRODUCT_PACKAGES += \
    libEGL_mesa \
    libGLESv1_CM_mesa \
    libGLESv2_mesa \
    libgallium_dri \
    libglapi

$(foreach vk_drv, virtio, \
    $(eval PRODUCT_PACKAGES += vulkan.$(vk_drv)))

PRODUCT_VENDOR_PROPERTIES += \
    ro.vendor.graphics.mesa.is_upstream=true
else
PRODUCT_PACKAGES += \
    libGLES_mesa

PRODUCT_VENDOR_PROPERTIES += \
    ro.vendor.graphics.mesa.is_upstream=false

PRODUCT_SOONG_NAMESPACES += \
    external/mesa3d
endif

# Graphics (Gralloc)
PRODUCT_PACKAGES += \
    android.hardware.graphics.allocator-service.minigbm \
    android.hardware.graphics.mapper@4.0-impl.minigbm \
    gralloc.minigbm \
    mapper.minigbm

# Init
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/config/init.virtio.rc:$(TARGET_COPY_OUT_VENDOR)/etc/init/hw/init.virtio.rc

PRODUCT_PACKAGES += \
    fstab.virtio \
    fstab.virtio.gsi.sda \
    fstab.virtio.gsi.vdc

# Input
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/config/.emptyfile:$(TARGET_COPY_OUT_VENDOR)/usr/keylayout/QEMU_QEMU_USB_Tablet.kl \
    $(LOCAL_PATH)/config/.emptyfile:$(TARGET_COPY_OUT_VENDOR)/usr/keylayout/QEMU_Virtio_Tablet.kl

# Kernel
TARGET_PREBUILT_KERNEL_USE ?= 6.1
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
    $(LOCAL_PATH)/config/init.recovery.virtio.rc:$(TARGET_COPY_OUT_RECOVERY)/root/init.recovery.virtio.rc

# Soong namespaces
PRODUCT_SOONG_NAMESPACES += \
    $(LOCAL_PATH)

# Vendor ramdisk
PRODUCT_PACKAGES += \
    fstab.virtio.vendor_ramdisk \
    fstab.virtio.gsi.sda.vendor_ramdisk \
    fstab.virtio.gsi.vdc.vendor_ramdisk
