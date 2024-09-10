SUMMARY = "Basic programs and scripts required on host to launch VM"

LICENSE = "BSD-3-Clause-Clear"

PACKAGE_ARCH = "${TUNE_PKGARCH}"

inherit packagegroup

PROVIDES = "${PACKAGES}"

PACKAGES = ' \
    packagegroup-qcom-vm-host \
    '

RDEPENDS:packagegroup-qcom-vm-host = "\
    kvmtool \
    qemu \
    libvirt \
    libvirt-virsh \
    libvirt-libvirtd \
    virt-manager \
    virt-manager-common \
    virt-manager-install \
    python3-pygobject \
    python3-requests \
    libxml2-python \
    "
