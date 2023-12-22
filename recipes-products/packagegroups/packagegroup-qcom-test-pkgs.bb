SUMMARY = "Qualcomm test packagegroups"

DESCRIPTION = "Package groups to bring in packages required to test images"

LICENSE = "BSD-3-Clause-Clear"

PACKAGE_ARCH = "${TUNE_PKGARCH}"

inherit packagegroup

PROVIDES = "${PACKAGES}"

PACKAGES = ' \
    packagegroup-qcom-test-pkgs \
    '

RDEPENDS:packagegroup-qcom-test-pkgs = "\
    rng-tools \
    fscryptctl \
    libkcapi \
    "
