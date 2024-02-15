SUMMARY = "Minimal image"

LICENSE = "BSD-3-Clause-Clear"

IMAGE_FEATURES += "splash tools-debug debug-tweaks enable-adbd read-only-rootfs"

inherit core-image features_check extrausers image-adbd

# let's make sure we have a good image..
REQUIRED_DISTRO_FEATURES = "pam systemd"

CORE_IMAGE_BASE_INSTALL += " \
    kernel-modules \
    packagegroup-filesystem-utils \
"

EXTRA_USERS_PARAMS = "\
    useradd -r -s /bin/false system; \
    "

# Adding kernel-devsrc to provide kernel development support on SDK
TOOLCHAIN_TARGET_TASK += "kernel-devsrc"
