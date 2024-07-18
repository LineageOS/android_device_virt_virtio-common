# Android common device tree for Virtual Machines with VirtIO hardware

The device tree is currently WIP, Not suitable for normal use.

```
#
# Copyright (C) 2024 The LineageOS Project
#
# SPDX-License-Identifier: Apache-2.0
#
```

# Known issues:
- Display color is wrong with Swiftshader graphics
- Video playback is not working properly with Mesa graphics
- Errors in recovery mode
- AAOS: EVS Logspam

# TODOs:
- Inline kernel building for LineageOS
- Bringup Audio
- Disable unsupported things
- Support for crosvm virtual machine
- Support for Intel AC'97, ICH6, and ICH9 soundcard
- Support for PS/2 Keyboard and Mouse
- Support for USB Bluetooth, Camera, and WiFi
- Support for VFIO PCI GPU Passthrough
- Ethernet support in recovery mode
- VirtWifi
- [VirtioFS](https://android.googlesource.com/device/google/cuttlefish/+/5c490d406e213b241dd8eb56fe59cb5157bdf06b)
- Enforce SELinux
- Userdata encryption
- GRUB2 support
- 16K pagesize
- OTA Upgrade (?)

# Required patches for AOSP

| Repository | Commit message | Link |
| ---------- | -------------- | ---- |
| system/core | init: devices: Add option to accept any device as boot device | [LineageOS Gerrit](https://review.lineageos.org/c/LineageOS/android_system_core/+/378562) |

# Build

The device tree was initially made for Android 14 QPR3.

Currently, It doesn't support OTA, uses only images.

```
source build/envsetup.sh
lunch aosp_virtio_x86_64-ap2a-userdebug # AOSP
breakfast virtio_x86_64 # LineageOS
m
```

# libvirt-qemu VM configuration

| Item | Description |
| ---- | ----------- |
| Chipset (x86_64) | Q35 |
| Machine type (arm64) | virt |
| Firmware | UEFI |
| RAM | At least 2048 MB |
| Direct kernel boot | On |
| Kernel path | `<android out dir>/kernel` |
| Initrd path | `<android out dir>/ramdisk.img` for system, or `<android out dir>/ramdisk-recovery.img` for recovery |
| Kernel args | Copy from `BOARD_KERNEL_CMDLINE` variable on `BoardConfigCommon.mk` and `BoardConfig.mk` |
| Graphics | Enable OpenGL |
| Video | Model: `virtio`, 3D Acceleration: On |
| NIC Device model | `virtio` |
| Sound card model | `usb` |
| USB Keyboard | Add the Hardware |
| USB Mouse | Add the Hardware |
| Virtio drive 1 | `<android out dir>/vendor.img` |
| Virtio drive 2 | `<android out dir>/system.img` or path to GSI |
| Virtio drive 3 | Create a empty image that's at least 2 GB |

To change display resolution, Add `resolution` element to video configuration, like this:
```
<video>
  <model type="virtio" heads="1" primary="yes">
    <acceleration accel3d="yes"/>
    <resolution x="1920" y="1080"/> <!-- 1920x1080 -->
  </model>
  <address type="pci" domain="0x0000" bus="0x00" slot="0x01" function="0x0"/>
</video>
```
