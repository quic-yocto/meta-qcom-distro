require qcom-minimal-image.bb

SUMMARY = "Basic console image"

LICENSE = "BSD-3-Clause-Clear"

IMAGE_FEATURES += "package-management ssh-server-openssh"

CORE_IMAGE_BASE_INSTALL += " \
    packagegroup-qcom \
"

# docker pulls runc/containerd, which in turn recommend lxc unecessarily

BAD_RECOMMENDATIONS:append = " lxc"
