DISTRO_VERSION ??= "1.0"

# SDK variables.
SDK_VERSION = "${DISTRO_VERSION}"
SDK_NAME = "${DISTRO}-${SDKMACHINE}-${IMAGE_BASENAME}-${TUNE_PKGARCH}-${MACHINE}"
SDK_VENDOR = "-qcomsdk"

TARGET_VENDOR = "-qcom"

# defaultsetup.inc gets includes after ${DISTRO}.conf, so we need to set it here
# to make the python below work. Local, site and auto.conf will override it.
TCMODE ?= "default"

DISTRO_FEATURES:append = " pam overlayfs acl xattr selinux ptest security virtualization"

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
INITRAMFS_IMAGE = "initramfs-qcom-image"

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

# Enable uninative for reuse -native sstate across hosts. This version is aligned to glibc 2.38.
# While modifying, do ensure both uninative and libc version updates go hand in hand.
UNINATIVE_MAXGLIBCVERSION = "2.38"
UNINATIVE_VERSION = "4.3"

UNINATIVE_URL = "http://downloads.yoctoproject.org/releases/uninative/${UNINATIVE_VERSION}/"
UNINATIVE_CHECKSUM[aarch64] ?= "8df05f4a41455018b4303b2e0ea4eac5c960b5a13713f6dbb33dfdb3e32753ec"
UNINATIVE_CHECKSUM[i686] ?= "bea76b4a97c9ba0077c0dd1295f519cd599dbf71f0ca1c964471c4cdb043addd"
UNINATIVE_CHECKSUM[x86_64] ?= "1c35f09a75c4096749bbe1e009df4e3968cde151424062cf4aa3ed89db22b030"

INHERIT += "uninative"

# GCC Version
GCCVERSION = "11.4%"

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
#DEFAULT_ENFORCING = "permissive"
SELINUX_FILE_CONTEXTS_EXT4 = " -f ${IMAGE_ROOTFS}/etc/selinux/mls/contexts/files/file_contexts"
EXTRA_IMAGECMD:ext4 += " ${@bb.utils.contains('DISTRO_FEATURES','selinux', '${SELINUX_FILE_CONTEXTS_EXT4}', '', d)}"

# Enable security compiler and linker flags.
require qcom-security_flags.inc
