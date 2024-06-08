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
    packagegroup-qcom-vm \
    '

RDEPENDS:${PN} = "\
    packagegroup-filesystem-utils \
    packagegroup-qcom-core \
    packagegroup-qcom-initscripts \
    packagegroup-qcom-perf \
    packagegroup-qcom-ppat \
    packagegroup-qcom-vm \
    packagegroup-qcom-wifi \
    packagegroup-support-utils \
    packagegroup-qcom-data \
    "

RDEPENDS:packagegroup-qcom-vm = "\
    linux-svm-kernel-qcom-package \
    kvmtool \
    qemu \
"

RDEPENDS:packagegroup-support-utils = "\
    can-utils \
    chrony \
    ethtool \
    iproute2 \
    libinput \
    libinput-bin \
    libnl \
    libxml2 \
    pciutils \
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
