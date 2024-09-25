#
# Copyright (C) 2024 The LineageOS Project
#
# SPDX-License-Identifier: Apache-2.0
#

# Inherit from common
$(call inherit-product, device/virt/virt-common/virt-common.mk)

COMMON_PATH := device/virt/virtio-common

# Graphics
PRODUCT_PACKAGES += \
    virtgpu_detect

# Graphics (Allocator)
PRODUCT_PACKAGES += \
    android.hardware.graphics.allocator-service.minigbm \
    gralloc.minigbm \
    mapper.minigbm

# Graphics (Composer)
PRODUCT_PACKAGES += \
    android.hardware.composer.hwc3-service.drm

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
TARGET_KERNEL_SOURCE := kernel/virt/virtio
ifneq ($(wildcard $(TARGET_KERNEL_SOURCE)/Makefile),)
    $(warning Using source built kernel)
endif

# Recovery
PRODUCT_COPY_FILES += \
    $(COMMON_PATH)/configs/init/init.recovery.virtio.rc:$(TARGET_COPY_OUT_RECOVERY)/root/init.recovery.virtio.rc

# Shipping API level
# (Stays on 30 due to target-level)
PRODUCT_SHIPPING_API_LEVEL := 30

# Soong namespaces
PRODUCT_SOONG_NAMESPACES += \
    $(COMMON_PATH)

# Vendor ramdisk
PRODUCT_PACKAGES += \
    fstab.virtio.vendor_ramdisk \
    fstab.virtio.gsi.sda.vendor_ramdisk \
    fstab.virtio.gsi.vdc.vendor_ramdisk
