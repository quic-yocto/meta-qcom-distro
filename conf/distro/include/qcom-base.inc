DISTRO_VERSION ??= "1.0"

# Supported selections are: base, custom
# We intend to use same selection as that of BSP by default.
# Specific DISTROs might change this as needed.
DISTROOVERRIDES =. "qcom-${QCOM_SELECTED_BSP}-distro:"

# SDK variables.
SDK_VERSION = "${DISTRO_VERSION}"
SDK_NAME = "${DISTRO}-${SDKMACHINE}-${IMAGE_BASENAME}-${TUNE_PKGARCH}-${MACHINE}"
SDK_VENDOR = "-qcomsdk"

TARGET_VENDOR = "-qcom"

# defaultsetup.inc gets includes after ${DISTRO}.conf, so we need to set it here
# to make the python below work. Local, site and auto.conf will override it.
TCMODE ?= "default"

DISTRO_FEATURES:append = " pam overlayfs acl xattr selinux ptest security virtualization tpm usrmerge"

# Use systemd init manager for system initialization.
INIT_MANAGER = "systemd"
VIRTUAL-RUNTIME_init_manager = "systemd"
VIRTUAL-RUNTIME_dev_manager  = "udev"

PACKAGECONFIG:append:pn-systemd = " resolved networkd"

# Use rsyslog as default syslog utility
VIRTUAL-RUNTIME_base-utils-syslog = "rsyslog"

# Avoid to duplicate the rootfs tarball by generating both tar.gz/tar.xz
IMAGE_FSTYPES:remove = "tar.gz"

# Pull in the initrd image by default
INITRAMFS_IMAGE_BUNDLE ?= "1"
INITRAMFS_IMAGE = "${@bb.utils.contains('DISTRO_FEATURES', 'sota', 'initramfs-ostree-image', 'initramfs-qcom-image', d)}"

INHERIT += "buildhistory"
INHERIT += "image-buildinfo"
INHERIT += "recipe_sanity"

## Performance build customizations.
# In PERFORMANCE_BUILD let /var/log be volatile (i.e. not on persistent storage)
# by symlinking /var/log to /var/volatile/log
VOLATILE_LOG_DIR = "${@bb.utils.contains('PERFORMANCE_BUILD', '1', 'yes', 'no', d)}"

# Drop console from Kernel cmdline.
CONSOLE_CMDLINE = "${@oe.utils.conditional('PERFORMANCE_BUILD','1','console=','console=ttyMSM0,115200n8 earlycon',d)}"
# Disable serial console
SERIAL_CONSOLES = "${@oe.utils.conditional('PERFORMANCE_BUILD','1','','115200;ttyMSM0',d)}"

BUILDHISTORY_COMMIT = "1"

# docker-ce has been deprecated, so switch to docker-moby as the preferred provider.
PREFERRED_PROVIDER_virtual/docker = "docker-moby"

# Enable uninative for reuse -native sstate across hosts.
require conf/distro/include/yocto-uninative.inc
INHERIT += "uninative"

# GCC Version
GCCVERSION = "11.5%"

# Easily switch between rust versions just by changing RUST_VERSION variable
RUST_VERSION ?= "1.73.0"

PREFERRED_VERSION_cargo ?= "${RUST_VERSION}"
PREFERRED_VERSION_cargo-native ?= "${RUST_VERSION}"
PREFERRED_VERSION_libstd-rs ?= "${RUST_VERSION}"
PREFERRED_VERSION_rust ?= "${RUST_VERSION}"
PREFERRED_VERSION_rust-cross-${TARGET_ARCH} ?= "${RUST_VERSION}"
PREFERRED_VERSION_rust-llvm ?= "${RUST_VERSION}"
PREFERRED_VERSION_rust-llvm-native ?= "${RUST_VERSION}"
PREFERRED_VERSION_rust-native ?= "${RUST_VERSION}"

# Selinux support
DISTRO_FEATURES_FILTER_NATIVE:append = " selinux"
DISTRO_FEATURES_FILTER_NATIVESDK:append = " selinux"
DISTRO_EXTRA_RDEPENDS:append = " ${@bb.utils.contains('DISTRO_FEATURES','selinux', 'packagegroup-selinux-minimal', '', d)}"
PREFERRED_PROVIDER_virtual/refpolicy = "refpolicy-mls"

# Disable selinux in default
DEFAULT_ENFORCING ?= "disabled"

SELINUX_FILE_CONTEXTS_EXT4 = " -f ${IMAGE_ROOTFS}/etc/selinux/mls/contexts/files/file_contexts"
EXTRA_IMAGECMD:ext4 += " ${@bb.utils.contains('DISTRO_FEATURES','selinux', '${SELINUX_FILE_CONTEXTS_EXT4}', '', d)}"

# Enable security compiler and linker flags.
require qcom-security_flags.inc

# Ostree variables
OSTREE_BOOTLOADER ?= "none"
OSTREE_SPLIT_BOOT = "1"
OSTREE_LOADER_LINK = "0"
BUILD_OTA_TARBALL = "1"
OSTREE_KERNEL = "${EFI_LINUX_IMG}"
OSTREE_KERNEL_ARGS_COMMON ?= "root=LABEL=otaroot rootfstype=ext4"
OSTREE_KERNEL_ARGS ?= "console=ttyMSM0,115200n8 earlycon pcie_pme=nomsi kernel.sched_pelt_multiplier=4 rcupdate.rcu_expedited=1 rcu_nocbs=0-7 kpti=off kasan=off kasan.stacktrace=off no-steal-acc page_owner=on swiotlb=128 ${OSTREE_KERNEL_ARGS_COMMON}"
SOTA_CLIENT_PROV ?= ""
OSTREE_DEPLOY_DEVICETREE = "0"
OSTREE_DEVICETREE = "${KERNEL_DEVICETREE}"
OSTREE_MULTI_DEVICETREE_SUPPORT = "0"

# Set OPKGLIBDIR to /etc to support OSTree for OTA
OPKGLIBDIR ?= "${@bb.utils.contains('DISTRO_FEATURES', 'sota', '/etc', '/var/lib', d)}"
