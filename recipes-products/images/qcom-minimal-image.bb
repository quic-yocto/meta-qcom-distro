SUMMARY = "Minimal image"

LICENSE = "BSD-3-Clause-Clear"

IMAGE_FEATURES += "splash tools-debug debug-tweaks enable-adbd read-only-rootfs"

inherit core-image features_check extrausers image-adbd image-qcom-deploy image-efi

# let's make sure we have a good image..
REQUIRED_DISTRO_FEATURES = "pam systemd"

CORE_IMAGE_BASE_INSTALL += " \
    kernel-modules \
"

EXTRA_IMAGE_FEATURES += " overlayfs-etc"
