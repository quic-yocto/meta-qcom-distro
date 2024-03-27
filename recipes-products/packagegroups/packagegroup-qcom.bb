SUMMARY = "Basic programs and scripts"
DESCRIPTION = "Package group to bring in all basic packages"

LICENSE = "BSD-3-Clause-Clear"

PACKAGE_ARCH = "${TUNE_PKGARCH}"

inherit packagegroup

PROVIDES = "${PACKAGES}"

PACKAGES = ' \
    ${PN} \
    packagegroup-filesystem-utils \
    packagegroup-support-utils \
    '

RDEPENDS:${PN} = "\
    packagegroup-filesystem-utils \
    packagegroup-qcom-core \
    packagegroup-qcom-initscripts \
    packagegroup-qcom-perf \
    packagegroup-qcom-wifi \
    packagegroup-support-utils \
    "

RDEPENDS:packagegroup-support-utils = "\
    chrony \
    libinput \
    libinput-bin \
    libnl \
    libxml2 \
    procps \
    zram \
    "

RDEPENDS:packagegroup-filesystem-utils = "\
    e2fsprogs \
    e2fsprogs-e2fsck \
    e2fsprogs-mke2fs \
    e2fsprogs-resize2fs \
    e2fsprogs-tune2fs \
    "
