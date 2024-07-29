/*
 * Copyright (C) 2021 The LineageOS Project
 *
 * SPDX-License-Identifier: Apache-2.0
 */

#include <android-base/file.h>
#include <android-base/properties.h>
#include <sys/sysinfo.h>

#include <libinit_dalvik_heap.h>
#include <libinit_utils.h>

#include "vendor_init.h"

#include <unordered_map>

#define GB(b) (b * 1024ull * 1024 * 1024)

using android::base::GetProperty;
using android::base::ReadFileToString;

static const std::string kDmiIdPath = "/sys/devices/virtual/dmi/id/";

static const std::unordered_map<std::string, std::string> kDmiIdToPropertyMap = {
    {"bios_version", "ro.boot.bootloader"},
    {"product_serial", "ro.serialno"},
};

static const std::unordered_map<std::string, std::string> kDmiIdToRoBuildPropMap = {
    {"chassis_vendor", "brand"},
    {"product_name", "model"},
    {"sys_vendor", "manufacturer"},
};

static void set_misc_properties() {
    struct sysinfo sys;
    sysinfo(&sys);

    if (sys.totalram > GB(4)) {
        // Consider as high-performance
        if (GetProperty("ro.boot.graphics", "") != "swiftshader" &&
            GetProperty("ro.boot.low_perf", "") != "1") {
            property_override("ro.surface_flinger.supports_background_blur", "1");
        }
    }
}

static void set_properties_from_dmi_id() {
    std::string value;

    for (const auto& [file, prop] : kDmiIdToPropertyMap) {
        ReadFileToString(kDmiIdPath + file, &value);
        if (value.empty())
            continue;
        value.pop_back();
        property_override(prop, value);
    }

    for (const auto& [file, ro_build_prop] : kDmiIdToRoBuildPropMap) {
        ReadFileToString(kDmiIdPath + file, &value);
        if (value.empty())
            continue;
        value.pop_back();
        set_ro_build_prop(ro_build_prop, value, true);
    }
}

void vendor_load_properties() {
    set_dalvik_heap();
    set_misc_properties();
    set_properties_from_dmi_id();
}
