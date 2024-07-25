#
# Copyright (C) 2024 The LineageOS Project
#
# SPDX-License-Identifier: Apache-2.0
#

COMMON_GRUB_PATH := $(call my-dir)

ifeq ($(TARGET_GRUB_ARCH),)
$(warning TARGET_GRUB_ARCH is not defined, could not build GRUB)
else
GRUB_PREBUILT_DIR := prebuilts/grub/$(HOST_PREBUILT_TAG)/$(TARGET_GRUB_ARCH)
GRUB_TOOLS_LINEAGE_BIN_DIR := prebuilts/tools-lineage/$(HOST_PREBUILT_TAG)/bin
GRUB_PATH_OVERRIDE := PATH=$(GRUB_TOOLS_LINEAGE_BIN_DIR):$$PATH
GRUB_XORRISO_EXEC := $(GRUB_TOOLS_LINEAGE_BIN_DIR)/xorriso

GRUB_WORKDIR_BASE := $(TARGET_OUT_INTERMEDIATES)/GRUB_OBJ
GRUB_WORKDIR_BOOT := $(GRUB_WORKDIR_BASE)/boot
GRUB_WORKDIR_ESP := $(GRUB_WORKDIR_BASE)/esp
GRUB_WORKDIR_INSTALL := $(GRUB_WORKDIR_BASE)/install

ifeq ($(TARGET_GRUB_ARCH),x86_64-efi)
GRUB_EFI_BOOT_FILENAME := BOOTX64.EFI
GRUB_MKSTANDALONE_FORMAT := x86_64-efi
endif

ifneq ($(LINEAGE_BUILD),)
GRUB_ANDROID_DISTRIBUTION_NAME := LineageOS $(PRODUCT_VERSION_MAJOR).$(PRODUCT_VERSION_MINOR)
GRUB_ANDROID_OTA_PACKAGE_NAME := lineage-$(LINEAGE_VERSION).zip
GRUB_ARTIFACT_FILENAME_PREFIX := lineage-$(LINEAGE_VERSION)
GRUB_THEME := lineage
else
LOCAL_BUILD_DATE := $(shell date -u +%Y%m%d)
GRUB_ANDROID_DISTRIBUTION_NAME := Android $(PLATFORM_VERSION_LAST_STABLE) $(BUILD_ID)
GRUB_ANDROID_OTA_PACKAGE_NAME := $(TARGET_PRODUCT)-ota.zip
GRUB_ARTIFACT_FILENAME_PREFIX := Android-$(PLATFORM_VERSION_LAST_STABLE)-$(BUILD_ID)-$(LOCAL_BUILD_DATE)
GRUB_THEME := android
endif

ifeq ($(PRODUCT_IS_AUTOMOTIVE),true)
GRUB_ANDROID_DISTRIBUTION_NAME += Car
else ifeq ($(PRODUCT_IS_ATV),true)
GRUB_ANDROID_DISTRIBUTION_NAME += TV
endif

# $(1): filesystem root directory
# $(2): path to grub.cfg file
define install-grub-theme
	sed -i "s|@GRUB_THEME@|$(GRUB_THEME)|g" $(2)
	mkdir -p $(1)/boot/grub/themes
	rm -rf $(1)/boot/grub/themes/$(GRUB_THEME)
	$(if $(GRUB_THEME), cp -r $(COMMON_GRUB_PATH)/themes/$(GRUB_THEME) $(1)/boot/grub/themes/)
endef

# $(1): path to grub.cfg file
define process-grub-cfg
	sed -i "s|@GRUB_ANDROID_DISTRIBUTION_NAME@|$(GRUB_ANDROID_DISTRIBUTION_NAME)|g" $(1)
	sed -i "s|@STRIPPED_BOARD_KERNEL_CMDLINE_CONSOLE@|$(strip $(BOARD_KERNEL_CMDLINE_CONSOLE))|g" $(1)
	sed -i "s|@STRIPPED_TARGET_GRUB_KERNEL_CMDLINE@|$(strip $(TARGET_GRUB_KERNEL_CMDLINE))|g" $(1)
endef

##### espimage #####

# $(1): output file
# $(2): dependencies
define make-espimage-target
	$(call pretty,"Target EFI System Partition image: $(1)")
	mkdir -p $(GRUB_WORKDIR_ESP)/fsroot/EFI/BOOT $(GRUB_WORKDIR_ESP)/fsroot/boot/grub/fonts

	cp $(COMMON_GRUB_PATH)/grub-standalone.cfg $(GRUB_WORKDIR_ESP)/grub-standalone.cfg
	$(call process-grub-cfg,$(GRUB_WORKDIR_ESP)/grub-standalone.cfg)
	$(GRUB_PATH_OVERRIDE) $(GRUB_PREBUILT_DIR)/bin/grub-mkstandalone -d $(GRUB_PREBUILT_DIR)/lib/grub/$(TARGET_GRUB_ARCH) --locales="" --fonts="" --format=$(GRUB_MKSTANDALONE_FORMAT) --output=$(GRUB_WORKDIR_ESP)/fsroot/EFI/BOOT/$(GRUB_EFI_BOOT_FILENAME) --modules="configfile disk fat part_gpt search" "boot/grub/grub.cfg=$(COMMON_GRUB_PATH)/grub-standalone.cfg"

	cp -r $(GRUB_PREBUILT_DIR)/lib/grub/$(TARGET_GRUB_ARCH) $(GRUB_WORKDIR_ESP)/fsroot/boot/grub/$(TARGET_GRUB_ARCH)
	cp $(GRUB_PREBUILT_DIR)/share/grub/unicode.pf2 $(GRUB_WORKDIR_ESP)/fsroot/boot/grub/fonts/unicode.pf2

	touch $(GRUB_WORKDIR_ESP)/fsroot/boot/grub/.is_esp_part_on_android_boot_device

	cp $(COMMON_GRUB_PATH)/grub-boot.cfg $(GRUB_WORKDIR_ESP)/fsroot/boot/grub/grub.cfg
	$(call process-grub-cfg,$(GRUB_WORKDIR_ESP)/fsroot/boot/grub/grub.cfg)
	$(call install-grub-theme,$(GRUB_WORKDIR_ESP)/fsroot,$(GRUB_WORKDIR_ESP)/fsroot/boot/grub/grub.cfg)

	/usr/bin/dd if=/dev/zero of=$(1) bs=1M count=128
	/sbin/mkfs.vfat -F 32 $(1)
	$(GRUB_TOOLS_LINEAGE_BIN_DIR)/mcopy -i $(1) -s $(GRUB_WORKDIR_ESP)/fsroot/EFI ::
	$(GRUB_TOOLS_LINEAGE_BIN_DIR)/mcopy -i $(1) -s $(GRUB_WORKDIR_ESP)/fsroot/boot ::
	$(GRUB_TOOLS_LINEAGE_BIN_DIR)/mcopy -i $(1) $(2) ::
endef

INSTALLED_ESPIMAGE_TARGET := $(GRUB_WORKDIR_ESP)/EFI.img
INSTALLED_ESPIMAGE_TARGET_DEPS := $(PRODUCT_OUT)/kernel $(INSTALLED_COMBINED_RAMDISK_TARGET) $(INSTALLED_COMBINED_RAMDISK_RECOVERY_TARGET)
$(INSTALLED_ESPIMAGE_TARGET): $(INSTALLED_ESPIMAGE_TARGET_DEPS)
	$(call make-espimage-target,$(INSTALLED_ESPIMAGE_TARGET),$(INSTALLED_ESPIMAGE_TARGET_DEPS))

.PHONY: espimage
espimage: $(INSTALLED_ESPIMAGE_TARGET)

.PHONY: espimage-nodeps
espimage-nodeps:
	@echo "make $(INSTALLED_ESPIMAGE_TARGET): ignoring dependencies"
	$(call make-espimage-target,$(INSTALLED_ESPIMAGE_TARGET),$(INSTALLED_ESPIMAGE_TARGET_DEPS))

##### isoimage-boot #####

# $(1): output file
# $(2): dependencies
define make-isoimage-boot-target
	$(call pretty,"Target boot ISO image: $(1)")
	mkdir -p $(GRUB_WORKDIR_BOOT)/boot/grub
	cp $(COMMON_GRUB_PATH)/grub-boot.cfg $(GRUB_WORKDIR_BOOT)/boot/grub/grub.cfg
	$(call process-grub-cfg,$(GRUB_WORKDIR_BOOT)/boot/grub/grub.cfg)
	$(call install-grub-theme,$(GRUB_WORKDIR_BOOT),$(GRUB_WORKDIR_BOOT)/boot/grub/grub.cfg)
	$(GRUB_PATH_OVERRIDE) $(GRUB_PREBUILT_DIR)/bin/grub-mkrescue -d $(GRUB_PREBUILT_DIR)/lib/grub/$(TARGET_GRUB_ARCH) --xorriso=$(GRUB_XORRISO_EXEC) -o $(1) $(2) $(GRUB_WORKDIR_BOOT)
endef

INSTALLED_ISOIMAGE_BOOT_TARGET := $(PRODUCT_OUT)/$(GRUB_ARTIFACT_FILENAME_PREFIX)-boot.iso
INSTALLED_ISOIMAGE_BOOT_TARGET_DEPS := $(PRODUCT_OUT)/kernel $(INSTALLED_COMBINED_RAMDISK_TARGET) $(INSTALLED_COMBINED_RAMDISK_RECOVERY_TARGET)
$(INSTALLED_ISOIMAGE_BOOT_TARGET): $(INSTALLED_ISOIMAGE_BOOT_TARGET_DEPS)
	$(call make-isoimage-boot-target,$(INSTALLED_ISOIMAGE_BOOT_TARGET),$(INSTALLED_ISOIMAGE_BOOT_TARGET_DEPS))

.PHONY: isoimage-boot
isoimage-boot: $(INSTALLED_ISOIMAGE_BOOT_TARGET)

.PHONY: isoimage-boot-nodeps
isoimage-boot-nodeps:
	@echo "make $(INSTALLED_ISOIMAGE_BOOT_TARGET): ignoring dependencies"
	$(call make-isoimage-boot-target,$(INSTALLED_ISOIMAGE_BOOT_TARGET),$(INSTALLED_ISOIMAGE_BOOT_TARGET_DEPS))

##### isoimage-install #####

# $(1): output file
# $(2): dependencies
define make-isoimage-install-target
	$(call pretty,"Target installer ISO image: $(1)")
	mkdir -p $(GRUB_WORKDIR_INSTALL)/boot/grub
	cp $(COMMON_GRUB_PATH)/grub-install.cfg $(GRUB_WORKDIR_INSTALL)/boot/grub/grub.cfg
	$(call process-grub-cfg,$(GRUB_WORKDIR_INSTALL)/boot/grub/grub.cfg)
	$(call install-grub-theme,$(GRUB_WORKDIR_INSTALL),$(GRUB_WORKDIR_INSTALL)/boot/grub/grub.cfg)
	$(GRUB_PATH_OVERRIDE) $(GRUB_PREBUILT_DIR)/bin/grub-mkrescue -d $(GRUB_PREBUILT_DIR)/lib/grub/$(TARGET_GRUB_ARCH) --xorriso=$(GRUB_XORRISO_EXEC) -o $(1) $(2) $(GRUB_WORKDIR_INSTALL)
endef

INSTALLED_ISOIMAGE_INSTALL_TARGET := $(PRODUCT_OUT)/$(GRUB_ARTIFACT_FILENAME_PREFIX).iso
INSTALLED_ISOIMAGE_INSTALL_TARGET_DEPS := $(PRODUCT_OUT)/kernel $(INSTALLED_COMBINED_RAMDISK_RECOVERY_TARGET) $(PRODUCT_OUT)/$(GRUB_ANDROID_OTA_PACKAGE_NAME)
$(INSTALLED_ISOIMAGE_INSTALL_TARGET): $(INSTALLED_ISOIMAGE_INSTALL_TARGET_DEPS)
	$(call make-isoimage-install-target,$(INSTALLED_ISOIMAGE_INSTALL_TARGET),$(INSTALLED_ISOIMAGE_INSTALL_TARGET_DEPS))

.PHONY: isoimage-install
isoimage-install: $(INSTALLED_ISOIMAGE_INSTALL_TARGET)

.PHONY: isoimage-install-nodeps
isoimage-install-nodeps:
	@echo "make $(INSTALLED_ISOIMAGE_INSTALL_TARGET): ignoring dependencies"
	$(call make-isoimage-install-target,$(INSTALLED_ISOIMAGE_INSTALL_TARGET),$(INSTALLED_ISOIMAGE_INSTALL_TARGET_DEPS))

endif
