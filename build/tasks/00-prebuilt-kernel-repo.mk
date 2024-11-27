#
# Copyright (C) 2024 The LineageOS Project
#
# SPDX-License-Identifier: Apache-2.0
#

ifeq ($(USES_DEVICE_VIRT_VIRTIO_COMMON),true)

# Create prebuilt kernel repo

ifneq ($(LINEAGE_BUILD),)
ifneq ($(wildcard $(TARGET_KERNEL_SOURCE)/Makefile),)

INSTALLED_PREBUILT_KERNEL_REPO_DIR := out/kernel-virtio/$(TARGET_PREBUILT_KERNEL_USE)/$(TARGET_PREBUILT_KERNEL_ARCH)

INSTALLED_PREBUILT_KERNEL_REPO_KERNEL_TARGET := $(INSTALLED_PREBUILT_KERNEL_REPO_DIR)/kernel
$(INSTALLED_PREBUILT_KERNEL_REPO_KERNEL_TARGET): $(PRODUCT_OUT)/.kernel_version.txt $(PRODUCT_OUT)/kernel
	$(call pretty,"Target prebuilt kernel repo: $@")
	mkdir -p $(INSTALLED_PREBUILT_KERNEL_REPO_DIR)
	rm -f $(INSTALLED_PREBUILT_KERNEL_REPO_DIR)/*.ko
	if grep -q '=m' $(PRODUCT_OUT)/obj/KERNEL_OBJ/.config; then\
		cp `find $(PRODUCT_OUT)/obj/KERNEL_OBJ/ -type f -name "*.ko"` $(INSTALLED_PREBUILT_KERNEL_REPO_DIR)/;\
	fi
	cp $(PRODUCT_OUT)/.kernel_version.txt $(INSTALLED_PREBUILT_KERNEL_REPO_DIR)/
	cp $(PRODUCT_OUT)/kernel $@

.PHONY: prebuilt-kernel-repo
prebuilt-kernel-repo: $(INSTALLED_PREBUILT_KERNEL_REPO_KERNEL_TARGET)

endif # $(TARGET_KERNEL_SOURCE)/Makefile
endif # LINEAGE_BUILD

endif
