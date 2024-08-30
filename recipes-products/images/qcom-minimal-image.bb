SUMMARY = "Minimal image"

LICENSE = "BSD-3-Clause-Clear"

IMAGE_FEATURES += "splash tools-debug allow-root-login post-install-logging enable-adbd read-only-rootfs"

inherit core-image features_check extrausers image-adbd image-qcom-deploy

# selinux-image is inherited to utilize the selinux_set_labels API, to perform build-time context labeling.
inherit  ${@bb.utils.contains('DISTRO_FEATURES', 'selinux', 'selinux-image', '', d)}

# let's make sure we have a good image..
REQUIRED_DISTRO_FEATURES = "pam systemd"

CORE_IMAGE_BASE_INSTALL += " \
    qcom-resize-partitions \
    packagegroup-filesystem-utils \
"

CORE_IMAGE_EXTRA_INSTALL += "overlayfs-qcom-paths"

EXTRA_USERS_PARAMS = "\
    useradd -r -s /bin/false system; \
    usermod -p '\$6\$UDMimfYF\$akpHo9mLD4z0vQyKzYxYbsdYxnpUD7B7rHskq1E3zXK8ygxzq719wMxI78i0TIIE0NB1jUToeeFzWXVpBBjR8.' root; \
    "

# Adding kernel-devsrc to provide kernel development support on SDK
TOOLCHAIN_TARGET_TASK += "kernel-devsrc"
