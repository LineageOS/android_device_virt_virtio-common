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
- Display color is wrong with Mesa graphics on crosvm
- Display color is wrong with Swiftshader graphics on QEMU
- Video playback is not working properly with Mesa graphics
- Errors in recovery mode
- AAOS: EVS Logspam

# TODOs:
- Disable unsupported things
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
| Sound card model | `AC97` (LineageOS) or `usb` (AOSP) |
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

# crosvm VM configuration

Configuration file:

```
{
    "kernel": "<android out dir>/kernel",
    "initrd": "<android out dir>/ramdisk.img",
    "params": [
        "<Copy from `BOARD_KERNEL_CMDLINE` variable on `BoardConfigCommon.mk` and `BoardConfig.mk`>"
    ],
    "cpus": {
        "num-cores": 2
    },
    "mem": {
        "size": 4096
    },
    "block": [
        {
            "path": "<android out dir>/vendor.img",
        },
        {
            "path": "<android out dir>/system.img",
        },
        {
            "path": "<path to empty disk image for userdata>"
        }
    ],
    "serial": [
        {
            "type": "stdout",
            "hardware": "serial",
            "console": true,
            "stdin": true
        }
    ]
}
```

Extra parameters:

`--gpu backend=virglrenderer --gpu-display mode=windowed\[1920,1080\] --display-window-keyboard --display-window-mouse --disable-sandbox`

# AVF Custom VM configuration

1. Restart ADB in root mode

`adb root`

2. Write the configuration to `/data/local/tmp/vm_config.json`

```
{
    "name": "Android",
    "kernel": "/data/local/tmp/kernel",
    "initrd": "/data/local/tmp/ramdisk.img",
    "params": "<Copy from `BOARD_KERNEL_CMDLINE` variable on `BoardConfigCommon.mk` and `BoardConfig.mk`>",
    "disks": [
        {
            "image": "/data/local/tmp/vendor.img",
            "writable": true
        },
        {
            "image": "/data/local/tmp/system.img",
            "writable": true
        },
        {
            "image": "/data/local/tmp/userdata.img",
            "writable": true
        }
    ],
    "gpu": {
        "backend": "virglrenderer",
        "context_types": ["virgl2"]
    },
    "protected": false,
    "cpu_topology": "match_host",
    "platform_version": "~1.0",
    "memory_mib" : 4096,
    "console_input_device": "hvc0"
}
```

3. Push the files to `/data/local/tmp`

```
adb push <android out dir>/kernel /data/local/tmp/kernel
adb push <android out dir>/ramdisk.img /data/local/tmp/ramdisk.img
adb push <android out dir>/system.img /data/local/tmp/system.img
adb push <android out dir>/vendor.img /data/local/tmp/vendor.img
```

4. Create userdata image (Note that `fallocate` doesn't work!)

`dd if=/dev/zero of=/data/local/tmp/userdata.img bs=1M count=2048`

5. Enable VM Launcher app

Follow https://android.googlesource.com/platform/packages/modules/Virtualization/+/refs/heads/main/docs/custom_vm.md#running-the-vm
