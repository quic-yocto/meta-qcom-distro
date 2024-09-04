SUMMARY = "Basic programs and scripts to run in guest VM"

LICENSE = "BSD-3-Clause-Clear"

PACKAGE_ARCH = "${TUNE_PKGARCH}"

inherit packagegroup

# Disable selinux for qcom-guestvm-image
DEFAULT_ENFORCING ?= "disabled"

PROVIDES = "${PACKAGES}"

PACKAGES = ' \
    packagegroup-qcom-vm-guest \
    '

RDEPENDS:packagegroup-qcom-vm-guest = "\
    qemu \
    "
