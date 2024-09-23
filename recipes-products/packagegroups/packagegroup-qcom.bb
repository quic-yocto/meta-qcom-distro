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
    packagegroup-qcom-initscripts \
    packagegroup-support-utils \
    packagegroup-qcom-vm-host \
    packagegroup-qcom-wifi \
    "

RDEPENDS:${PN}:append:qcom-custom-bsp = "\
    packagegroup-qcom-core \
    packagegroup-qcom-data \
    packagegroup-qcom-perf \
    packagegroup-qcom-ppat \
    packagegroup-qcom-securemsm \
    "

RDEPENDS:packagegroup-support-utils = "\
    can-utils \
    chrony \
    ethtool \
    efivar \
    iproute2 \
    irqbalance \
    libatomic \
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
