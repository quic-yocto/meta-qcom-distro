SUMMARY = "A minimal kvm image with boot to shell support"

LICENSE = "BSD-3-Clause-Clear"

inherit core-image

CORE_IMAGE_BASE_INSTALL += " \
    packagegroup-qcom-vm-guest \
"

IMAGE_FEATURES += "ssh-server-openssh"

# Permit root login without a password
IMAGE_FEATURES += " debug-tweaks"

IMAGE_LINGUAS = " "
