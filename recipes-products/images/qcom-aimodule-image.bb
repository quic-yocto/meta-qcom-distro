require qcom-console-image.bb

SUMMARY = "AI Module image with needed feature support"

LICENSE = "BSD-3-Clause-Clear"

# let's make sure we have a good image.
REQUIRED_DISTRO_FEATURES += "wayland"

CORE_IMAGE_BASE_INSTALL += " \
    packagegroup-qcom-aimodule \
"
