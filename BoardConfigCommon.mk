#
# SPDX-FileCopyrightText: The LineageOS Project
# SPDX-License-Identifier: Apache-2.0
#

USES_DEVICE_VIRT_VIRTIO_COMMON := true

# Inherit from common
include device/virt/virt-common/BoardConfigVirtCommon.mk

# Boot manager
TARGET_GRUB_BOOT_CONFIGS += $(COMMON_PATH)/bootmgr/grub/grub-boot.cfg
TARGET_GRUB_INSTALL_CONFIGS += $(COMMON_PATH)/bootmgr/grub/grub-install.cfg

# Bootconfig
BOARD_BOOTCONFIG += \
    androidboot.hardware=virtio \
    androidboot.partition_map=\"vdb,userdata\"

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

TARGET_KERNEL_CONFIG_EXT += \
    $(COMMON_PATH)/configs/kernel/virtio-common.config

ifneq ($(wildcard $(TARGET_KERNEL_SOURCE)/Makefile),)
# nothing
else ifneq ($(wildcard $(TARGET_PREBUILT_KERNEL_DIR)/kernel),)
BOARD_VENDOR_KERNEL_MODULES := \
    $(wildcard $(TARGET_PREBUILT_KERNEL_DIR)/*.ko)
endif

# Pre-install checks
$(call soong_config_set,VIRT_PREINSTALL_CHECK,BOOT_DISK_NAME,vda)
$(call soong_config_set,VIRT_PREINSTALL_CHECK,USERDATA_DISK_NAME,vdb)
$(call soong_config_set,VIRT_PREINSTALL_CHECK,DRM_CARD_NAME,virtio_gpu)

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
ifeq ($(TARGET_AUDIO_HAL),ranchu)
DEVICE_MANIFEST_FILE += \
    $(COMMON_PATH)/configs/vintf/manifest_target-level-latest.xml
else
DEVICE_MANIFEST_FILE += \
    $(COMMON_PATH)/configs/vintf/manifest_target-level-202404.xml
endif
