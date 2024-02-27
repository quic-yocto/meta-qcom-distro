SUMMARY = "Qualcomm AI Module packagegroups"
DESCRIPTION = "Package groups to bring in packages required for AI boards"

LICENSE = "BSD-3-Clause-Clear"

PACKAGE_ARCH = "${TUNE_PKGARCH}"

inherit packagegroup

PROVIDES = "${PACKAGES}"

PACKAGES = ' \
    packagegroup-qcom-aimodule \
    '

RDEPENDS:packagegroup-qcom-aimodule = "\
    gtk4 \
    gtk4-demo \
    packagegroup-qcom-display \
    packagegroup-qcom-graphics \
    packagegroup-qcom-video \
    packagegroup-qcom-opencv \
    "
