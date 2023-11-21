# This class installs adbd into the target image.
# The adbd daemon is disabled unless IMAGE_FEATURES contains the 'enable-adbd'
# Also one can disable adbd by removing /var/usb-debugging-enabled from rootfs manually.

IMAGE_FEATURES[validitems] += "enable-adbd"

PACKAGE_INSTALL:append = " ${@bb.utils.contains('IMAGE_FEATURES', [ 'enable-adbd' ], 'android-tools-adbd', '',d)} "

enable_adbd_at_boot () {
	touch ${IMAGE_ROOTFS}/var/usb-debugging-enabled
}

ROOTFS_POSTPROCESS_COMMAND += "${@bb.utils.contains('IMAGE_FEATURES', [ 'enable-adbd' ], 'enable_adbd_at_boot; ', '',d)}"
