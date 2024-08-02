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
- Support for USB Bluetooth, Camera, and WiFi
- Support for VFIO PCI GPU Passthrough
- VirtWifi
- [VirtioFS](https://android.googlesource.com/device/google/cuttlefish/+/5c490d406e213b241dd8eb56fe59cb5157bdf06b)
- Enforce SELinux on all targets (Currently did for libvirt-qemu)
- 16K pagesize

# Supported virtual hardware

| Type | Models | Description |
| ---- | ------ | ----------- |
| Chipset (QEMU x86_64) | Q35 | |
| Console | Serial console, VirtIO | By default, Serial console is used for printing kernel messages, VirtIO is used for Android shell console. |
| Disk | USB, VirtIO | Must use VirtIO for boot devices. |
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
| `androidboot.graphics` | `mesa` or `swiftshader` | Graphics stack to use. Default is `mesa`. |
| `androidboot.lcd_density` | `<DPI>` | Screen density. Default is `160`. |
| `androidboot.low_perf` | `1` | Add this to enable low performance optimizations. |
| `androidboot.nobootanim` | `1` | Add this to disable boot animation. |
| `virtio_gpu.force_resolution` | `<Width>x<Height>` | Force display resolution for virtio-gpu display. Exists only in source built kernel. |

# Required patches for AOSP

| Repository | Commit message | Link |
| ---------- | -------------- | ---- |
| external/gptfdisk | gptfdisk: Build lib for recovery | https://review.lineageos.org/c/LineageOS/android_external_gptfdisk/+/368276 |
| external/gptfdisk | sgdisk: Make sgdisk recovery_available | https://review.lineageos.org/c/LineageOS/android_external_gptfdisk/+/368280 |
| prebuilts/tools-lineage | tools-lineage: linux-x86: Import mtools from mtools_4.0.44_amd64.deb | [LineageOS Gerrit](https://review.lineageos.org/c/LineageOS/android_prebuilts_tools-lineage/+/398285) |
| system/core | init: devices: Add option to accept any device as boot device | [LineageOS Gerrit](https://review.lineageos.org/c/LineageOS/android_system_core/+/378562) |

| Topic | Link |
| ----- | ---- |
| 14-embed-super_empty_img | [LineageOS Gerrit](https://review.lineageos.org/q/topic:%2214-embed-super_empty_img%22) |
| 14-recovery-ethernet | [LineageOS Gerrit](https://review.lineageos.org/q/topic:%2214-recovery-ethernet%22) |

# Build

The device tree targets Android 14 QPR3.

1. Initialize build environment

```
source build/envsetup.sh
```

2. Select the build target

For AOSP:
`lunch aosp_virtio_x86_64-ap2a-userdebug`

For LineageOS:
`breakfast virtio_x86_64`

3. Build

To build vda disk image:
`make diskimage-vda`

To build EFI System Partition (Boot) image:
`make espimage-boot`

To build EFI System Partition (Install) image:
`make espimage-install`
