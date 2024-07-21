#
# Copyright (C) 2024 The LineageOS Project
#
# SPDX-License-Identifier: Apache-2.0
#

# Audio
PRODUCT_PACKAGES += \
    com.android.hardware.audio

PRODUCT_COPY_FILES += \
    device/generic/goldfish/audio/policy/audio_policy_configuration.xml:$(TARGET_COPY_OUT_VENDOR)/etc/audio_policy_configuration.xml \
    device/generic/goldfish/audio/policy/primary_audio_policy_configuration.xml:$(TARGET_COPY_OUT_VENDOR)/etc/primary_audio_policy_configuration.xml \
    hardware/interfaces/audio/aidl/default/audio_effects_config.xml:$(TARGET_COPY_OUT_VENDOR)/etc/audio_effects_config.xml \
    frameworks/av/services/audiopolicy/config/audio_policy_volumes.xml:$(TARGET_COPY_OUT_VENDOR)/etc/audio_policy_volumes.xml \
    frameworks/av/services/audiopolicy/config/bluetooth_audio_policy_configuration_7_0.xml:$(TARGET_COPY_OUT_VENDOR)/etc/bluetooth_audio_policy_configuration_7_0.xml \
    frameworks/av/services/audiopolicy/config/default_volume_tables.xml:$(TARGET_COPY_OUT_VENDOR)/etc/default_volume_tables.xml \
    frameworks/av/services/audiopolicy/config/r_submix_audio_policy_configuration.xml:$(TARGET_COPY_OUT_VENDOR)/etc/r_submix_audio_policy_configuration.xml

# Dalvik heap
$(call inherit-product, frameworks/native/build/tablet-10in-xhdpi-2048-dalvik-heap.mk)

# Gatekeeper
PRODUCT_PACKAGES += \
    android.hardware.gatekeeper@1.0-service.software

# Graphics (Mesa)
$(call inherit-product, device/google/cuttlefish/shared/virgl/device_vendor.mk)

# Graphics (Swiftshader)
PRODUCT_PACKAGES += \
    com.google.cf.vulkan
TARGET_VULKAN_SUPPORT := true
$(call inherit-product, device/google/cuttlefish/shared/swiftshader/device_vendor.mk)

# Graphics (Composer)
PRODUCT_PACKAGES += \
    android.hardware.graphics.composer@2.4-service \
    hwcomposer.drm

PRODUCT_VENDOR_PROPERTIES += \
    ro.hardware.hwcomposer=drm

# Graphics (Gralloc)
PRODUCT_PACKAGES += \
    android.hardware.graphics.allocator-service.minigbm \
    android.hardware.graphics.mapper@4.0-impl.minigbm \
    mapper.minigbm

# Health
PRODUCT_PACKAGES += \
    android.hardware.health-service.cuttlefish_recovery \
    com.google.cf.health

# Init
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/config/fstab.utm:$(TARGET_COPY_OUT_VENDOR)/etc/fstab.utm \
    $(LOCAL_PATH)/config/fstab.virtio:$(TARGET_COPY_OUT_VENDOR)/etc/fstab.virtio \
    $(LOCAL_PATH)/config/init.utm.rc:$(TARGET_COPY_OUT_VENDOR)/etc/init/hw/init.utm.rc \
    $(LOCAL_PATH)/config/init.virtio.rc:$(TARGET_COPY_OUT_VENDOR)/etc/init/hw/init.virtio.rc \
    $(LOCAL_PATH)/config/ueventd.rc:$(TARGET_COPY_OUT_VENDOR)/etc/ueventd.rc

# Input
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/config/Generic.kl:$(TARGET_COPY_OUT_VENDOR)/usr/keylayout/Generic.kl

# Images
PRODUCT_BUILD_BOOT_IMAGE := true
PRODUCT_BUILD_RAMDISK_IMAGE := true
PRODUCT_BUILD_RECOVERY_IMAGE := true
PRODUCT_USE_DYNAMIC_PARTITION_SIZE := true

# Kernel
TARGET_KERNEL_SOURCE := kernel/virt/virtio
ifneq ($(wildcard $(TARGET_KERNEL_SOURCE)/Makefile),)
$(warning Using source built kernel)
else
$(warning Using prebuilt kernel)
KERNEL_ARTIFACTS_PATH := kernel/prebuilts/$(TARGET_PREBUILT_KERNEL_USE)/$(TARGET_PREBUILT_KERNEL_ARCH)
EMULATOR_KERNEL_FILE := $(KERNEL_ARTIFACTS_PATH)/kernel-$(TARGET_PREBUILT_KERNEL_USE)
PRODUCT_COPY_FILES += $(EMULATOR_KERNEL_FILE):kernel
endif
PRODUCT_OTA_ENFORCE_VINTF_KERNEL_REQUIREMENTS := false

# Keymint
PRODUCT_PACKAGES += \
    android.hardware.security.keymint-service

# Low performance optimizations
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/low_performance/init.low_performance.rc:$(TARGET_COPY_OUT_VENDOR)/etc/init/hw/init.low_performance.rc

PRODUCT_PACKAGES += \
    LowPerformanceSettingsProviderOverlay

# Overlays
DEVICE_PACKAGE_OVERLAYS += \
    $(LOCAL_PATH)/overlay

PRODUCT_ENFORCE_RRO_TARGETS := *

# Permissions
PRODUCT_COPY_FILES += \
    frameworks/native/data/etc/android.hardware.ethernet.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.ethernet.xml \
    frameworks/native/data/etc/android.hardware.touchscreen.multitouch.jazzhand.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.touchscreen.multitouch.jazzhand.xml \
    frameworks/native/data/etc/android.hardware.usb.host.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.usb.host.xml \
    frameworks/native/data/etc/android.software.credentials.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.software.credentials.xml \
    frameworks/native/data/etc/android.software.ipsec_tunnels.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.software.ipsec_tunnels.xml \
    frameworks/native/data/etc/android.software.midi.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.software.midi.xml

ifeq ($(PRODUCT_IS_AUTOMOTIVE),true)
PRODUCT_COPY_FILES += \
    frameworks/native/data/etc/car_core_hardware.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/car_core_hardware.xml
else ifneq ($(PRODUCT_IS_ATV),true)
PRODUCT_COPY_FILES += \
    frameworks/native/data/etc/pc_core_hardware.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/pc_core_hardware.xml
endif

# Ramdisk
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/config/fstab.utm:$(TARGET_COPY_OUT_RAMDISK)/fstab.utm \
    $(LOCAL_PATH)/config/fstab.virtio:$(TARGET_COPY_OUT_RAMDISK)/fstab.virtio

# Recovery
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/config/ueventd.rc:$(TARGET_COPY_OUT_RECOVERY)/root/vendor/etc/ueventd.rc \
    device/google/cuttlefish/shared/config/cgroups.json:$(TARGET_COPY_OUT_RECOVERY)/root/vendor/etc/cgroups.json

# Scoped Storage
$(call inherit-product, $(SRC_TARGET_DIR)/product/emulated_storage.mk)

# Shipping API level
# (Stays on 33 due to target-level)
PRODUCT_SHIPPING_API_LEVEL := 33

# Soong namespaces
PRODUCT_SOONG_NAMESPACES += \
    $(LOCAL_PATH)

# Suspend blocker
PRODUCT_PACKAGES += \
    suspend_blocker

# UFFD GC
PRODUCT_ENABLE_UFFD_GC := true
