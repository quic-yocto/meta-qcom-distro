require qcom-multimedia-image.bb

SUMMARY = "Test multimedia image with ptest"

LICENSE = "BSD-3-Clause-Clear"

CORE_IMAGE_BASE_INSTALL += " \
    packagegroup-qcom-test-pkgs \
"

# This image is sufficiently large, need to be careful that it fits in the partition.
# Nullify the overhead factor added in minimal image and explicitly add just 1GB.
IMAGE_OVERHEAD_FACTOR = "1.5"
IMAGE_ROOTFS_EXTRA_SPACE = "1048576"

EXTRA_IMAGE_FEATURES:append = " tools-testapps ptest-pkgs"
