#!/vendor/bin/sh -e

EFI_MOUNT=/mnt/vendor/EFI
REFIND_CONF_PATH=$EFI_MOUNT/EFI/BOOT/refind.conf

klog() {
    echo "$0: $@" > /dev/kmsg
}

if [ ! -f $REFIND_CONF_PATH ]; then
    klog "Could not find $REFIND_CONF_PATH"
    exit 1
elif [ ! -w $REFIND_CONF_PATH ]; then
    klog "Unable to write to $REFIND_CONF_PATH"
    exit 1
fi

REASON=$(echo -n $1|cut -c 2-)

case "$REASON" in
    "recovery"|"recovery-update")
        DEFAULT_SELECTION=2
        ;;
    *)
        DEFAULT_SELECTION=1
        ;;
esac

klog "Set default selection to $DEFAULT_SELECTION for reason $REASON"

sed -i '/default_selection /d;/timeout /d' $REFIND_CONF_PATH

echo "default_selection $DEFAULT_SELECTION" >> $REFIND_CONF_PATH
if [ "$1" ]; then
    echo "timeout 10" >> $REFIND_CONF_PATH
else
    echo "timeout 0" >> $REFIND_CONF_PATH
fi

exit 0
