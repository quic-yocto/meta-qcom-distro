DISTRO_VERSION ??= "0.0"

# SDK variables.
SDK_VERSION = "${DISTRO_VERSION}"
SDK_NAME = "${DISTRO}-${SDKMACHINE}-${IMAGE_BASENAME}-${TUNE_PKGARCH}-${MACHINE}"
SDK_VENDOR = "-qcomsdk"

TARGET_VENDOR = "-qcom"

# defaultsetup.inc gets includes after ${DISTRO}.conf, so we need to set it here
# to make the python below work. Local, site and auto.conf will override it.
TCMODE ?= "default"

DISTRO_FEATURES:append = " pam systemd overlayfs acl xattr selinux ptest security virtualization"

VIRTUAL-RUNTIME_init_manager = "systemd"

PACKAGECONFIG:append:pn-systemd = " resolved networkd"

# Avoid to duplicate the rootfs tarball by generating both tar.gz/tar.xz
IMAGE_FSTYPES:remove = "tar.gz"

# Pull in the initrd image by default
INITRAMFS_IMAGE_BUNDLE ?= "1"
INITRAMFS_IMAGE = "initramfs-qcom-image"

INHERIT += "buildhistory"
INHERIT += "image-buildinfo"
INHERIT += "recipe_sanity"

BUILDHISTORY_COMMIT = "1"

# Enable uninative for reuse -native sstate across hosts. This version is aligned to glibc 2.35.
# While modifying, do ensure both uninative and libc version updates go hand in hand.
UNINATIVE_MAXGLIBCVERSION = "2.35"
UNINATIVE_VERSION = "3.5"

UNINATIVE_URL = "http://downloads.yoctoproject.org/releases/uninative/${UNINATIVE_VERSION}/"
UNINATIVE_CHECKSUM[aarch64] ?= "6de0771bd21e0fcb5e80388e5b561a8023b24083bcbf46e056a089982aff75d7"
UNINATIVE_CHECKSUM[i686] ?= "8c8745becbfa1c341bae839c7eab56ddf17ce36c303bcd73d3b2f2f788b631c2"
UNINATIVE_CHECKSUM[x86_64] ?= "e8047a5748e6f266165da141eb6d08b23674f30e477b0e5505b6403d50fbc4b2"

INHERIT += "uninative"

# GCC Version
GCCVERSION = "11.4%"

#Selinux support
DISTRO_FEATURES_FILTER_NATIVE:append = " selinux"
DISTRO_FEATURES_FILTER_NATIVESDK:append = " selinux"
DISTRO_EXTRA_RDEPENDS:append = " ${@bb.utils.contains('DISTRO_FEATURES','selinux', 'packagegroup-selinux-minimal', '', d)}"
PREFERRED_PROVIDER_virtual/refpolicy = "refpolicy-mls"
DEFAULT_ENFORCING = "permissive"
