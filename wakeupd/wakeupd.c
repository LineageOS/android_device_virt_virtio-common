#define LOG_TAG "wakeupd"
#include <log/log.h>

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <fcntl.h>
#include <linux/input.h>
#include <linux/uinput.h>
#include <string.h>
#include <errno.h>
#include <sys/stat.h>

#define DPMS_STATUS_PATH "/sys/class/drm/card0-Virtual-1/dpms"
#define DPMS_OFF "Off"
#define WAKEUP_KEY_CODE KEY_WAKEUP

void setup_uinput_device(int *uinput_fd) {
    struct uinput_setup usetup;

    *uinput_fd = open("/dev/uinput", O_WRONLY | O_NONBLOCK);
    if (*uinput_fd < 0) {
        ALOGE("Failed to open /dev/uinput");
        exit(EXIT_FAILURE);
    }

    if (ioctl(*uinput_fd, UI_SET_EVBIT, EV_KEY) < 0) {
        ALOGE("Failed to set EV_KEY");
        exit(EXIT_FAILURE);
    }

    if (ioctl(*uinput_fd, UI_SET_KEYBIT, WAKEUP_KEY_CODE) < 0) {
        ALOGE("Failed to set keybit");
        exit(EXIT_FAILURE);
    }

    memset(&usetup, 0, sizeof(usetup));
    usetup.id.bustype = BUS_USB;
    usetup.id.vendor = 0x1234;
    usetup.id.product = 0x5678;
    strcpy(usetup.name, "Virtual Wakeup Device");

    if (ioctl(*uinput_fd, UI_DEV_SETUP, &usetup) < 0) {
        ALOGE("Failed to setup uinput device");
        exit(EXIT_FAILURE);
    }

    if (ioctl(*uinput_fd, UI_DEV_CREATE) < 0) {
        ALOGE("Failed to create uinput device");
        exit(EXIT_FAILURE);
    }
}

void send_wakeup_event(int uinput_fd) {
    struct input_event ev;

    memset(&ev, 0, sizeof(struct input_event));
    ev.type = EV_KEY;
    ev.code = WAKEUP_KEY_CODE;
    ev.value = 1;
    if (write(uinput_fd, &ev, sizeof(struct input_event)) < 0) {
        ALOGE("Failed to send key press event");
    }

    ev.value = 0;
    if (write(uinput_fd, &ev, sizeof(struct input_event)) < 0) {
        ALOGE("Failed to send key release event");
    }

    ev.type = EV_SYN;
    ev.code = SYN_REPORT;
    ev.value = 0;
    if (write(uinput_fd, &ev, sizeof(struct input_event)) < 0) {
        ALOGE("Failed to send syn event");
    }
}

int main() {
    char dpms_status[16];
    int uinput_fd, dpms_fd;
    ssize_t nread;

    setup_uinput_device(&uinput_fd);

    dpms_fd = open(DPMS_STATUS_PATH, O_RDONLY);
    if (dpms_fd < 0) {
        ALOGE("Failed to open DPMS status file");
        exit(EXIT_FAILURE);
    }

    while (1) {
        lseek(dpms_fd, 0, SEEK_SET); // Reset file pointer to the beginning
        nread = read(dpms_fd, dpms_status, sizeof(dpms_status) - 1);
        if (nread < 0) {
            ALOGE("Failed to read DPMS status");
            sleep(5);
            continue;
        }
        dpms_status[nread] = '\0'; // Null-terminate the string

        if (strncmp(dpms_status, DPMS_OFF, strlen(DPMS_OFF)) == 0) {
            send_wakeup_event(uinput_fd);
        }

        sleep(5); // Check every 5 seconds
    }

    // Clean up uinput device
    if (ioctl(uinput_fd, UI_DEV_DESTROY) < 0) {
        ALOGE("Failed to destroy uinput device");
    }
    close(uinput_fd);
    close(dpms_fd);

    return 0;
}
