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
- Disable sleep on VMs that are hard to wakeup (for example, crosvm)
- Support for USB Bluetooth, Camera, and WiFi
- Support for VFIO PCI GPU Passthrough
- VirtWifi
- [VirtioFS](https://android.googlesource.com/device/google/cuttlefish/+/5c490d406e213b241dd8eb56fe59cb5157bdf06b)
- Enforce SELinux on all targets (Currently did for libvirt-qemu)
- 16K pagesize

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
| prebuilts/tools-lineage | tools-lineage: linux-x86: Import mtools from mtools_4.0.44_amd64.deb | [LineageOS Gerrit](https://review.lineageos.org/c/LineageOS/android_prebuilts_tools-lineage/+/398285) |
| system/core | init: devices: Add option to accept any device as boot device | [LineageOS Gerrit](https://review.lineageos.org/c/LineageOS/android_system_core/+/378562) |

| Topic | Link |
| ----- | ---- |
| 14-embed-super_empty_img | [LineageOS Gerrit](https://review.lineageos.org/q/topic:%2214-embed-super_empty_img%22) |
| 14-recovery-ethernet | [LineageOS Gerrit](https://review.lineageos.org/q/topic:%2214-recovery-ethernet%22) |

# Build

The device tree was initially made for Android 14 QPR3.

```
source build/envsetup.sh
lunch aosp_virtio_x86_64-ap2a-userdebug # AOSP
breakfast virtio_x86_64 # LineageOS
m
```
