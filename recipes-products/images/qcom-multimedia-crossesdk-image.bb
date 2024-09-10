require qcom-multimedia-image.bb

SUMMARY = "Cross eSDK generation of multimedia image"

LICENSE = "BSD-3-Clause-Clear"

inherit populate_sdk_ext

addtask do_populate_sdk_ext after do_rootfs

# Include kernel sources to build kernel modules in SDK
TOOLCHAIN_TARGET_TASK:append = " kernel-devsrc"
