SUMMARY = "Qualcomm multimedia packagegroups"
DESCRIPTION = "Package groups to bring in packages required to enable multimedia support"

LICENSE = "BSD-3-Clause-Clear"

PACKAGE_ARCH = "${TUNE_PKGARCH}"

inherit packagegroup

PROVIDES = "${PACKAGES}"

PACKAGES = "${PN}"

RDEPENDS:${PN} = "\
    packagegroup-container \
    packagegroup-qcom-audio \
    packagegroup-qcom-bluetooth \
    packagegroup-qcom-camera \
    packagegroup-qcom-display \
    packagegroup-qcom-fastcv \
    packagegroup-qcom-graphics \
    packagegroup-qcom-opencv \
    packagegroup-qcom-sensors \
    packagegroup-qcom-synx \
    packagegroup-qcom-video \
    python3-docker-compose \
    camera-server \
    "
