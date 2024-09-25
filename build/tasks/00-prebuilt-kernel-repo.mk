#
# Copyright (C) 2024 The LineageOS Project
#
# SPDX-License-Identifier: Apache-2.0
#

ifeq ($(USES_DEVICE_VIRT_VIRTIO_COMMON),true)

# Create prebuilt kernel repo

ifneq ($(LINEAGE_BUILD),)
ifneq ($(wildcard $(TARGET_KERNEL_SOURCE)/Makefile),)

endif
