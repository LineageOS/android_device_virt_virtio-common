#
# Copyright (C) 2024 The LineageOS Project
#
# SPDX-License-Identifier: Apache-2.0
#

COMMON_GRUB_PATH := $(call my-dir)

ifeq ($(TARGET_BOOT_MANAGER),grub)
ifeq ($(TARGET_GRUB_ARCH),)
$(warning TARGET_GRUB_ARCH is not defined, could not build GRUB)
else
GRUB_PREBUILT_DIR := prebuilts/grub/$(HOST_PREBUILT_TAG)/$(TARGET_GRUB_ARCH)

GRUB_WORKDIR_BASE := $(TARGET_OUT_INTERMEDIATES)/GRUB_OBJ
GRUB_WORKDIR_ESP := $(GRUB_WORKDIR_BASE)/esp
GRUB_WORKDIR_INSTALL := $(GRUB_WORKDIR_BASE)/install

ifeq ($(TARGET_GRUB_ARCH),x86_64-efi)
GRUB_MKSTANDALONE_FORMAT := x86_64-efi
endif

# $(1): filesystem root directory
# $(2): path to grub.cfg file
define install-grub-theme
	sed -i "s|@BOOTMGR_THEME@|$(BOOTMGR_THEME)|g" $(2)
	mkdir -p $(1)/boot/grub/themes
	rm -rf $(1)/boot/grub/themes/$(BOOTMGR_THEME)
	$(if $(BOOTMGR_THEME), cp -r $(COMMON_GRUB_PATH)/themes/$(BOOTMGR_THEME) $(1)/boot/grub/themes/)
endef

# $(1): output file
# $(2): dependencies
# $(3): workdir
# $(4): purpose (boot or install)
define make-espimage
	mkdir -p $(3)/fsroot/EFI/BOOT $(3)/fsroot/boot/grub/fonts

	cp $(COMMON_GRUB_PATH)/grub-standalone.cfg $(3)/grub-standalone.cfg
	$(call process-bootmgr-cfg-common,$(3)/grub-standalone.cfg)
	sed -i "s|@PURPOSE@|$(4)|g" $(3)/grub-standalone.cfg
	$(BOOTMGR_PATH_OVERRIDE) $(GRUB_PREBUILT_DIR)/bin/grub-mkstandalone -d $(GRUB_PREBUILT_DIR)/lib/grub/$(TARGET_GRUB_ARCH) --locales="" --fonts="" --format=$(GRUB_MKSTANDALONE_FORMAT) --output=$(3)/fsroot/EFI/BOOT/$(BOOTMGR_EFI_BOOT_FILENAME) --modules="configfile disk fat part_gpt search" "boot/grub/grub.cfg=$(3)/grub-standalone.cfg"

	cp -r $(GRUB_PREBUILT_DIR)/lib/grub/$(TARGET_GRUB_ARCH) $(3)/fsroot/boot/grub/$(TARGET_GRUB_ARCH)
	cp $(GRUB_PREBUILT_DIR)/share/grub/unicode.pf2 $(3)/fsroot/boot/grub/fonts/unicode.pf2

	touch $(3)/fsroot/boot/grub/.is_esp_part_on_android_$(4)_device

	cp $(COMMON_GRUB_PATH)/grub-$(4).cfg $(3)/fsroot/boot/grub/grub.cfg
	$(call process-bootmgr-cfg-common,$(3)/fsroot/boot/grub/grub.cfg)
	$(call install-grub-theme,$(3)/fsroot,$(3)/fsroot/boot/grub/grub.cfg)

	$(call create-espimage,$(1),$(3)/fsroot/EFI $(3)/fsroot/boot $(2),$(4))
endef

##### espimage #####

# $(1): output file
# $(2): dependencies
define make-espimage-target
	$(call pretty,"Target EFI System Partition image: $(1)")
	$(call make-espimage,$(1),$(2),$(GRUB_WORKDIR_ESP),boot)
endef

##### espimage-install #####

# $(1): output file
# $(2): dependencies
define make-espimage-install-target
	$(call pretty,"Target installer ESP image: $(1)")
	$(call make-espimage,$(1),$(2),$(GRUB_WORKDIR_INSTALL),install)
endef

endif # TARGET_GRUB_ARCH
endif # TARGET_BOOT_MANAGER
