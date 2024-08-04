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
- Enforce SELinux on all targets (Currently did for libvirt-qemu)
- 16K pagesize

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
| Chipset (QEMU x86_64) | Q35 | |
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
| `androidboot.graphics` | `mesa` or `swiftshader` | Graphics stack to use. Default is `mesa`. |
| `androidboot.lcd_density` | `<DPI>` | Screen density. Default is `160`. |
| `androidboot.low_perf` | `1` | Add this to enable low performance optimizations. |
| `androidboot.nobootanim` | `1` | Add this to disable boot animation. |
| `virtio_gpu.force_resolution` | `<Width>x<Height>` | Force display resolution for virtio-gpu display. Exists only in source built kernel. |

# Required patches for AOSP

| Repository | Commit message | Link |
| ---------- | -------------- | ---- |
| external/gptfdisk | gptfdisk: Build lib for recovery | [LineageOS Gerrit](https://review.lineageos.org/c/LineageOS/android_external_gptfdisk/+/368276) |
| external/gptfdisk | sgdisk: Make sgdisk recovery_available | [LineageOS Gerrit](https://review.lineageos.org/c/LineageOS/android_external_gptfdisk/+/368280) |
| prebuilts/tools-lineage | tools-lineage: linux-x86: Import mtools from mtools_4.0.44_amd64.deb | [LineageOS Gerrit](https://review.lineageos.org/c/LineageOS/android_prebuilts_tools-lineage/+/398285) |
| system/core | init: devices: Add option to accept any device as boot device | [LineageOS Gerrit](https://review.lineageos.org/c/LineageOS/android_system_core/+/378562) |

| Topic | Link |
| ----- | ---- |
| 14-embed-super_empty_img | [LineageOS Gerrit](https://review.lineageos.org/q/topic:%2214-embed-super_empty_img%22) |
| 14-recovery-ethernet | [LineageOS Gerrit](https://review.lineageos.org/q/topic:%2214-recovery-ethernet%22) |

# Build

The device tree targets Android 13 QPR3.

1. Initialize build environment

```
source build/envsetup.sh
```

2. Select the build target (Using `virtio_x86_64` as example)

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

# Guide to boot inside crosvm VM

1. Build crosvm

Follow https://crosvm.dev/book/building_crosvm/index.html

2. Create empty image for userdata disk

`dd if=/dev/zero of=disk-vdb.img bs=1M count=2048`

3. Write VM configuration file

```
{
    "kernel": "$(PRODUCT_OUT)/kernel",
    "initrd": "$(PRODUCT_OUT)/combined-ramdisk.img",
    "params": [
        "<Copy from `BOARD_KERNEL_CMDLINE` variable on `BoardConfigCommon.mk` in this repository>"
    ],
    "cpus": {
        "num-cores": 2
    },
    "mem": {
        "size": 2048
    },
    "block": [
        {
            "path": "$(PRODUCT_OUT)/disk-vda.img",
        },
        {
            "path": "<Path to the newly created userdata disk image>",
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

4. Run the VM

`./target/debug/crosvm run --cfg <Path to the VM configuration file> --gpu backend=virglrenderer --gpu-display mode=windowed\[1920,1080\] --display-window-keyboard --display-window-mouse --disable-sandbox`

# Guide to boot inside AVF Custom VM

1. Boot the device into latest AOSP main GSI

AOSP main GSI can be obtained from [Android CI Website](https://ci.android.com).

2. Connect the device to PC

3. Restart ADB in root mode

`adb root`

4. Push required files to `/data/local/tmp`

```
adb push $ANDROID_PRODUCT_OUT/kernel /data/local/tmp/kernel
adb push $ANDROID_PRODUCT_OUT/combined-ramdisk.img /data/local/tmp/ramdisk.img
adb push $ANDROID_PRODUCT_OUT/disk-vda.img /data/local/tmp/disk-vda.img
```

5. Create empty image for userdata disk (Note that `fallocate` command would not work for this!)

`dd if=/dev/zero of=/data/local/tmp/disk-vdb.img bs=1M count=2048`

6. Write VM configuration to `/data/local/tmp/vm_config.json`

```
{
    "name": "Android",
    "kernel": "/data/local/tmp/kernel",
    "initrd": "/data/local/tmp/ramdisk.img",
    "params": "<Copy from `BOARD_KERNEL_CMDLINE` variable on `BoardConfigCommon.mk` in this repository>",
    "disks": [
        {
            "image": "/data/local/tmp/disk-vda.img",
            "writable": true
        },
        {
            "image": "/data/local/tmp/disk-vdb.img",
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
    "memory_mib" : 2048,
    "console_input_device": "hvc0"
}
```

7. Enable VmLauncherApp

Follow https://android.googlesource.com/platform/packages/modules/Virtualization/+/refs/heads/main/docs/custom_vm.md#running-the-vm

8. Launch VmLauncherApp
