#define LOG_TAG "virtgpu_detect"

#include <cutils/log.h>
#include <cutils/properties.h>
#include <fcntl.h>
#include <stdlib.h>
#include <unistd.h>
#include <virtgpu_drm.h>
#include <xf86drm.h>

#define VIRTGPU_PARAM_3D_FEATURES 1

int main() {
    int fd, ret;
    uint32_t value;
    struct drm_virtgpu_getparam get_param = {
            .value = (uint64_t)(uintptr_t)&value,
    };

    fd = drmOpen("virtio_gpu", NULL);
    if (fd < 0) {
        ALOGE("drmOpen() failed");
        return EXIT_FAILURE;
    }

    get_param.param = VIRTGPU_PARAM_3D_FEATURES;
    ret = drmIoctl(fd, DRM_IOCTL_VIRTGPU_GETPARAM, &get_param);
    if (!ret) {
        property_set("ro.vendor.graphics", value ? "mesa" : "swiftshader");
    } else {
        ALOGE("drmIoctl VIRTGPU_PARAM_3D_FEATURES failed");
    }

    close(fd);
    return EXIT_SUCCESS;
}
