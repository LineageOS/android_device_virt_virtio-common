# Do not set interpreter, this script will be executed either on build host or in android recovery

SGDISK_EXEC=$1
TARGET=$2

if [ ! -x "$SGDISK_EXEC" ] || [ ! -w "$TARGET" ]; then
    exit 1
fi

$SGDISK_EXEC --zap-all $TARGET
$SGDISK_EXEC --new=1:0:+128M --typecode=1:ef00 --change-name=1:EFI $TARGET
$SGDISK_EXEC --new=2:0:+4G --change-name=2:super $TARGET
$SGDISK_EXEC --new=3:0:+1M --change-name=3:misc $TARGET
$SGDISK_EXEC --new=4:0:+32M --change-name=4:metadata $TARGET
$SGDISK_EXEC --new=5:0:+50M --change-name=5:cache $TARGET
$SGDISK_EXEC --new=6:0:+64M --change-name=6:boot $TARGET
$SGDISK_EXEC --new=7:0:+64M --change-name=7:recovery $TARGET

exit 0
