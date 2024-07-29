#include <errno.h>
#include <fcntl.h>
#include <linux/input.h>
#include <linux/uinput.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/epoll.h>
#include <unistd.h>

#define LOG_TAG "tablet2multitouch"

#ifdef DEBUG
#define LOG_ERROR(...) fprintf(stderr, LOG_TAG ": " __VA_ARGS__)
#define LOG_INFO(...) fprintf(stdout, LOG_TAG ": " __VA_ARGS__)
#else
#include <cutils/klog.h>
#define LOG_ERROR(...) KLOG_ERROR(LOG_TAG, __VA_ARGS__)
#define LOG_INFO(...) KLOG_INFO(LOG_TAG, __VA_ARGS__)
#endif

// Taken from kernel/include/linux/input/mt.h
#define TRKID_MAX 0xffff

// Function to setup the uinput device
int setup_uinput_device(int *uinput_fd, struct input_absinfo *abs_x_info,
			struct input_absinfo *abs_y_info)
{
	struct uinput_setup usetup;
	struct uinput_abs_setup abs_setup;

	*uinput_fd = open("/dev/uinput", O_WRONLY | O_NONBLOCK);
	if (*uinput_fd < 0) {
		LOG_ERROR("open /dev/uinput\n");
		return -1;
	}

	ioctl(*uinput_fd, UI_SET_EVBIT, EV_KEY);
	ioctl(*uinput_fd, UI_SET_KEYBIT, BTN_TOUCH);
	ioctl(*uinput_fd, UI_SET_KEYBIT, KEY_BACK);
	ioctl(*uinput_fd, UI_SET_KEYBIT, KEY_MENU);
	ioctl(*uinput_fd, UI_SET_KEYBIT, KEY_UP);
	ioctl(*uinput_fd, UI_SET_KEYBIT, KEY_DOWN);

	ioctl(*uinput_fd, UI_SET_EVBIT, EV_ABS);
	ioctl(*uinput_fd, UI_SET_ABSBIT, ABS_X);
	ioctl(*uinput_fd, UI_SET_ABSBIT, ABS_Y);
	ioctl(*uinput_fd, UI_SET_ABSBIT, ABS_MT_SLOT);
	ioctl(*uinput_fd, UI_SET_ABSBIT, ABS_MT_POSITION_X);
	ioctl(*uinput_fd, UI_SET_ABSBIT, ABS_MT_POSITION_Y);
	ioctl(*uinput_fd, UI_SET_ABSBIT, ABS_MT_TRACKING_ID);

	// Set the INPUT_PROP_DIRECT property
	ioctl(*uinput_fd, UI_SET_PROPBIT, INPUT_PROP_DIRECT);

	// Set the ABS_MT_SLOT range
	memset(&abs_setup, 0, sizeof(abs_setup));
	abs_setup.code = ABS_MT_SLOT;
	abs_setup.absinfo.minimum = 0;
	abs_setup.absinfo.maximum = 1; // 2 slots (0 and 1)
	ioctl(*uinput_fd, UI_ABS_SETUP, &abs_setup);

	// Set the ABS_X and ABS_MT_POSITION_X range based on the source
	// device's ABS_X
	memset(&abs_setup, 0, sizeof(abs_setup));
	abs_setup.code = ABS_X;
	abs_setup.absinfo = *abs_x_info;
	abs_setup.absinfo.value = 0;
	ioctl(*uinput_fd, UI_ABS_SETUP, &abs_setup);
	abs_setup.code = ABS_MT_POSITION_X;
	ioctl(*uinput_fd, UI_ABS_SETUP, &abs_setup);

	// Set the ABS_Y and ABS_MT_POSITION_Y range based on the source
	// device's ABS_Y
	memset(&abs_setup, 0, sizeof(abs_setup));
	abs_setup.code = ABS_Y;
	abs_setup.absinfo = *abs_y_info;
	abs_setup.absinfo.value = 0;
	ioctl(*uinput_fd, UI_ABS_SETUP, &abs_setup);
	abs_setup.code = ABS_MT_POSITION_Y;
	ioctl(*uinput_fd, UI_ABS_SETUP, &abs_setup);

	// Set the ABS_MT_TRACKING_ID range
	memset(&abs_setup, 0, sizeof(abs_setup));
	abs_setup.code = ABS_MT_TRACKING_ID;
	abs_setup.absinfo.minimum = 0;
	abs_setup.absinfo.maximum = TRKID_MAX;
	ioctl(*uinput_fd, UI_ABS_SETUP, &abs_setup);

	memset(&usetup, 0, sizeof(usetup));
	usetup.id.bustype = BUS_USB;
	usetup.id.vendor = 0x1234;
	usetup.id.product = 0x7890;
	strcpy(usetup.name, "uinput-multitouch-device");

	if (ioctl(*uinput_fd, UI_DEV_SETUP, &usetup) < 0) {
		LOG_ERROR("ioctl UI_DEV_SETUP\n");
		close(*uinput_fd);
		return -1;
	}

	if (ioctl(*uinput_fd, UI_DEV_CREATE) < 0) {
		LOG_ERROR("ioctl UI_DEV_CREATE\n");
		close(*uinput_fd);
		return -1;
	}

	return 0;
}

// Function to send input events
void send_input_event(int uinput_fd, __u16 type, __u16 code, __s32 value)
{
	struct input_event ev;
	memset(&ev, 0, sizeof(ev));
	ev.type = type;
	ev.code = code;
	ev.value = value;
	if (write(uinput_fd, &ev, sizeof(ev)) < 0)
		LOG_ERROR("write\n");
}

// Function to send multitouch events
void send_multitouch_event(int uinput_fd, bool pressed, int tracking_id,
			   __s32 x, __s32 y)
{
	// input_mt_slot
	send_input_event(uinput_fd, EV_ABS, ABS_MT_SLOT, 0);
	if (pressed) {
		// input_mt_report_slot_state
		send_input_event(uinput_fd, EV_ABS, ABS_MT_TRACKING_ID,
				 tracking_id);
		// input_report_abs ABS_MT_POSITION_X
		send_input_event(uinput_fd, EV_ABS, ABS_MT_POSITION_X, x);
		// input_report_abs ABS_MT_POSITION_Y
		send_input_event(uinput_fd, EV_ABS, ABS_MT_POSITION_Y, y);
		// input_mt_sync_frame -> input_mt_report_pointer_emulation
		send_input_event(uinput_fd, EV_KEY, BTN_TOUCH, 1);
		send_input_event(uinput_fd, EV_ABS, ABS_X, x);
		send_input_event(uinput_fd, EV_ABS, ABS_Y, y);
	} else {
		// input_mt_report_slot_state
		send_input_event(uinput_fd, EV_ABS, ABS_MT_TRACKING_ID, -1);
		// input_mt_sync_frame -> input_mt_report_pointer_emulation
		send_input_event(uinput_fd, EV_KEY, BTN_TOUCH, 0);
	}
	// input_sync
	send_input_event(uinput_fd, EV_SYN, SYN_REPORT, 0);
}

// Function to send key events
void send_key_event(int uinput_fd, __u16 code, __s32 value)
{
	send_input_event(uinput_fd, EV_KEY, code, value);
	send_input_event(uinput_fd, EV_SYN, SYN_REPORT, 0);
}

// Function to handle tablet to multitouch and key translation
void handle_event(int uinput_fd, struct input_event *ev)
{
	static bool pressed = false;
	static int tracking_id = 0;
	static __s32 x = 0, y = 0;

	bool key_report_up = false;
	__u16 trans_keycode;

	__u16 *type = &ev->type;
	__u16 *code = &ev->code;
	__s32 *value = &ev->value;

	switch (*type) {
	case EV_KEY:
		if (*code == BTN_LEFT) {
			pressed = !!*value;
			send_multitouch_event(uinput_fd, pressed, tracking_id,
					      x, y);
			if (!pressed) {
				tracking_id++;
				if (tracking_id > TRKID_MAX) {
					tracking_id = 0;
				}
			}
			return;
		}
		switch (*code) {
		case BTN_MIDDLE:
			trans_keycode = KEY_BACK;
			break;
		case BTN_RIGHT:
			trans_keycode = KEY_MENU;
			break;
		case BTN_GEAR_DOWN:
			key_report_up = true;
			trans_keycode = KEY_DOWN;
			break;
		case BTN_GEAR_UP:
			key_report_up = true;
			trans_keycode = KEY_UP;
			break;
		default:
			return;
		}
		if (key_report_up) {
			send_key_event(uinput_fd, trans_keycode, 1);
			send_key_event(uinput_fd, trans_keycode, 0);
		} else {
			send_key_event(uinput_fd, trans_keycode, *value);
		}
		return;
	case EV_ABS:
		switch (*code) {
		case ABS_X:
			x = *value;
			break;
		case ABS_Y:
			y = *value;
			break;
		default:
			return;
		}
		if (pressed) {
			send_multitouch_event(uinput_fd, pressed, tracking_id,
					      x, y);
		}
		return;
	default:
		return;
	}
}

int main()
{
	int fd, uinput_fd;
	struct input_event ev;
	struct input_absinfo abs_x_info, abs_y_info;
	const char *device_names[] = {"QEMU QEMU USB Tablet",
				      "QEMU Virtio Tablet"};
	char device_path[64];
	int epoll_fd;
	struct epoll_event event, events[10];

	// Find the evdev device path
	for (int i = 0; i < 64; ++i) {
		snprintf(device_path, sizeof(device_path), "/dev/input/event%d",
			 i);
		fd = open(device_path, O_RDONLY | O_NONBLOCK);
		if (fd < 0)
			continue;

		ioctl(fd, EVIOCGNAME(sizeof(device_path)), device_path);

		for (int j = 0;
		     j < sizeof(device_names) / sizeof(device_names[0]); ++j) {
			if (strcmp(device_path, device_names[j]) == 0) {
				goto device_found;
			}
		}

		close(fd);
		fd = -1;
	}

	if (fd < 0) {
		LOG_ERROR("Device not found\n");
		return 0;
	}

device_found:
	LOG_INFO("Using device: %s\n", device_path);

	// Read ABS_X and ABS_Y info from the source device
	if (ioctl(fd, EVIOCGABS(ABS_X), &abs_x_info) < 0) {
		LOG_ERROR("ioctl EVIOCGABS(ABS_X)\n");
		return 1;
	}

	if (ioctl(fd, EVIOCGABS(ABS_Y), &abs_y_info) < 0) {
		LOG_ERROR("ioctl EVIOCGABS(ABS_Y)\n");
		return 1;
	}

	// Setup uinput device
	if (setup_uinput_device(&uinput_fd, &abs_x_info, &abs_y_info) < 0) {
		LOG_ERROR("Failed to setup uinput device\n");
		return 1;
	}

	// Setup epoll
	epoll_fd = epoll_create1(0);
	if (epoll_fd < 0) {
		LOG_ERROR("epoll_create1\n");
		return 1;
	}

	event.events = EPOLLIN;
	event.data.fd = fd;
	if (epoll_ctl(epoll_fd, EPOLL_CTL_ADD, fd, &event) < 0) {
		LOG_ERROR("epoll_ctl\n");
		return 1;
	}

	while (1) {
		int ret = epoll_wait(epoll_fd, events, 10, -1);

		if (ret > 0) {
			for (int i = 0; i < ret; ++i) {
				if (events[i].events & EPOLLIN) {
					int rc = read(fd, &ev, sizeof(ev));
					if (rc == sizeof(ev)) {
						handle_event(uinput_fd, &ev);
					} else if (rc < 0 && errno != EAGAIN) {
						LOG_ERROR("read\n");
						break;
					}
				}
			}
		} else if (ret < 0) {
			LOG_ERROR("epoll_wait\n");
			break;
		}
	}

	ioctl(uinput_fd, UI_DEV_DESTROY);
	close(uinput_fd);
	close(fd);
	close(epoll_fd);

	return 0;
}
