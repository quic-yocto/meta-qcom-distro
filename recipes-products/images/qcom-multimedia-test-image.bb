require qcom-multimedia-image.bb

SUMMARY = "Test multimedia image with ptest"

LICENSE = "BSD-3-Clause-Clear"

CORE_IMAGE_BASE_INSTALL += " \
    packagegroup-qcom-test-pkgs \
"

IMAGE_ROOTFS_EXTRA_SPACE = "1048576"

EXTRA_IMAGE_FEATURES:append = " tools-testapps ptest-pkgs"
