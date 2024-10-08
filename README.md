# Android common device tree for Virtual Machines with VirtIO hardware

The device tree is currently WIP, Not suitable for normal use.

```
#
# Copyright (C) 2024 The LineageOS Project
#
# SPDX-License-Identifier: Apache-2.0
#
```

# Known issues
- Display color is wrong with Mesa graphics on crosvm
- Display color is wrong with Swiftshader graphics on QEMU
- Video playback is not working properly with Mesa graphics

# TODO
- ARM 32-bit only and 64-bit only targets
- Support for VFIO PCI GPU Passthrough
- Enforce SELinux on all targets (Currently did for libvirt-qemu)

# Mandatory virtual machine configuration

| Item | Value | Description |
| ---- | ----- | ----------- |
| Firmware (If available) | UEFI (Without secure boot) | Would not add support for BIOS. |
| Kernel (If using direct kernel boot) | `$(PRODUCT_OUT)/kernel` | |
| Kernel cmdline (If using direct kernel boot) | Copy from `BOARD_KERNEL_CMDLINE_BASE` variable on `BoardConfigCommon.mk` in this repository. | |
| RAM | At least 1024 MB | At least 2048 MB is preferred. Strongly recommended to add `androidboot.low_perf=1` to kernel cmdline if it's below than 2048 MB. |
| Ramdisk (If using direct kernel boot) | `$(PRODUCT_OUT)/combined-ramdisk.img` for normal boot, or `$(PRODUCT_OUT)/combined-ramdisk-recovery.img` for recovery mode. | |
| VirtIO disk 1 | Sized at least `BOARD_SUPER_PARTITION_SIZE` + 1 GB | You can use `$(PRODUCT_OUT)/disk-vda.img` as the disk image. |
| VirtIO disk 2 | Sized at least 2 GB | There is no need of formatting it manually, It would get formatted when Android boots up. |

# Supported virtual hardware

| Type | Models | Description |
| ---- | ------ | ----------- |
| Console | Serial console, VirtIO | By default, Serial console is used for printing kernel messages, VirtIO is used for Android shell console. |
| Disk | USB, VirtIO | Must use VirtIO for boot devices. |
| Filesystem | virtiofs | virtiofs filesystem with tag "shared" will be automatically mounted at `/mnt/vendor/shared`. |
| Graphics | VirtIO (with or without 3D Acceleration) | Enable 3D Acceleration for Mesa graphics, Disable 3D Acceleration for Swiftshader graphics. |
| Keyboard | PS/2, USB, VirtIO | PS/2 isn't supported when using emulator prebuilt kernel. |
| Machine type (QEMU arm64) | virt | |
| Mouse | PS/2, USB, VirtIO | PS/2 isn't supported when using emulator prebuilt kernel. |
| Network Interface Card | VirtIO | |
| Sound card | Intel AC97, Intel ICH6, Intel ICH9, USB, VirtIO | Prefer VirtIO sound card, then Intel AC97. Intel sound cards aren't supported when using emulator prebuilt kernel. |
| Tablet input | USB, VirtIO | Does not show mouse cursor, Should be used only if the VM viewer has touchscreen. |

# List of optional extra boot parameters

| Parameter | Possible values | Description |
| --------- | --------------- | ----------- |
| `virtio_gpu.force_resolution` | `<Width>x<Height>` | Force display resolution for virtio-gpu display. Exists only in source built kernel. |
