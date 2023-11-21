# Copyright (c) 2023 Qualcomm Innovation Center, Inc. All rights reserved.
# SPDX-License-Identifier: BSD-3-Clause-Clear

## Repurpose deploy directory to meet some general needs like retaining 'rootfs',
## generating a tar with debug symbols of all pkgs, create a directory with all
## images at one place etc.

# The work directory for image recipes is retained as the 'rootfs' directory
# can be used as sysroot during remote gdb debgging
RM_WORK_EXCLUDE += "${PN}"

# generate a companion debug archive containing symbols from the -dbg packages
IMAGE_GEN_DEBUGFS = "1"
IMAGE_FSTYPES_DEBUGFS = "tar.bz2"

# Don't append timestamp to image name
IMAGE_VERSION_SUFFIX = ""

# Don't install locales into rootfs
IMAGE_LINGUAS = ""

inherit python3native

DEPENDS:append = " \
    python3-native \
    qdl-native \
    "
# generate partition artifacts in DEPLOYDIR
PARTBINS_DEPLOYDIR = "${WORKDIR}/partition-bins-${PN}"

do_gen_partition_bins[depends] += " \
    gen-partitions-tool-native:do_populate_sysroot \
    partition-confs-native:do_populate_sysroot \
    ptool-native:do_populate_sysroot \
   "
do_gen_partition_bins() {
    # Step1: Generate partition.xml using gen_partition utility
    ${STAGING_BINDIR_NATIVE}/gen_partition.py \
        -i ${STAGING_ETCDIR_NATIVE}/partitions.conf \
        -o ${PARTBINS_DEPLOYDIR}/partition.xml

    # Step2: Call ptool to generate partition bins
    cd ${PARTBINS_DEPLOYDIR} && ${STAGING_BINDIR_NATIVE}/ptool.py -x partition.xml
}
addtask do_gen_partition_bins after do_rootfs before do_image

# Setup sstate
SSTATETASKS += "do_gen_partition_bins"
do_gen_partition_bins[sstate-inputdirs] = "${PARTBINS_DEPLOYDIR}"
do_gen_partition_bins[sstate-outputdirs] = "${DEPLOY_DIR_IMAGE}"

python do_gen_partition_bins_setscene () {
    sstate_setscene(d)
}
addtask do_gen_partition_bins
do_gen_partition_bins[dirs] = "${PARTBINS_DEPLOYDIR} ${B}"
do_gen_partition_bins[cleandirs] = "${PARTBINS_DEPLOYDIR}"
do_gen_partition_bins[stamp-extra-info] = "${MACHINE_ARCH}"

# Default Image names
BOOTIMAGE_TARGET   ?= "boot.img"
SYSTEMIMAGE_TARGET ?= "system.img"

# Place all files needed to flash the device in DEPLOY_DIR_NAME/IMAGE_BASENAME.
# As they can't be directly installed into this path from actual recipes,
# use do_deploy_fixup task and copy them here.
do_deploy_fixup[dirs] = "${DEPLOY_DIR_IMAGE}/${IMAGE_BASENAME}"
do_deploy_fixup[cleandirs] = "${DEPLOY_DIR_IMAGE}/${IMAGE_BASENAME}"
do_deploy_fixup[depends] += "firmware-qcm6490-boot:do_deploy"
do_deploy_fixup[deptask] = "do_image_complete"
do_deploy_fixup[nostamp] = "1"
do_deploy_fixup () {
    # copy vmlinux, Image.gz/Image/zImage
    if [ -f ${DEPLOY_DIR_IMAGE}/vmlinux ]; then
        install -m 0644 ${DEPLOY_DIR_IMAGE}/vmlinux .
    fi
    if [ -f ${DEPLOY_DIR_IMAGE}/${KERNEL_IMAGETYPE} ]; then
        install -m 0644 ${DEPLOY_DIR_IMAGE}/${KERNEL_IMAGETYPE} .
    fi

    # copy boot.img
    if [ -f ${DEPLOY_DIR_IMAGE}/boot-initramfs-combined-dtb-${KERNEL_IMAGE_LINK_NAME}.img ]; then
        install -m 0644 ${DEPLOY_DIR_IMAGE}/boot-initramfs-combined-dtb-${KERNEL_IMAGE_LINK_NAME}.img ${BOOTIMAGE_TARGET}
    else
        dtbf="${KERNEL_DEVICETREE}"
        dtbf=${dtbf##*/}
        dtb_name="${dtbf%.*}"
        if [ -f ${DEPLOY_DIR_IMAGE}/boot-initramfs-$dtb_name-${KERNEL_IMAGE_LINK_NAME}.img ]; then
            install -m 0644 ${DEPLOY_DIR_IMAGE}/boot-initramfs-$dtb_name-${KERNEL_IMAGE_LINK_NAME}.img ${BOOTIMAGE_TARGET}
        fi
    fi

    # copy efi.bin
    if [ -f ${DEPLOY_DIR_IMAGE}/efi.bin ]; then
        install -m 0644 ${DEPLOY_DIR_IMAGE}/efi.bin efi.bin
    fi

    # copy system.img
    if [ -f ${DEPLOY_DIR_IMAGE}/${IMAGE_NAME}${IMAGE_NAME_SUFFIX}.ext4 ]; then
        install -m 0644 ${DEPLOY_DIR_IMAGE}/${IMAGE_NAME}${IMAGE_NAME_SUFFIX}.ext4 ${SYSTEMIMAGE_TARGET}
    fi

    #Copy gpt_main.bin
    for gmbf in ${DEPLOY_DIR_IMAGE}/gpt_main[0-9].bin; do
        install -m 0644 $gmbf .
    done

    #Copy gpt_backup.bin
    for gpback in ${DEPLOY_DIR_IMAGE}/gpt_backup[0-9].bin; do
        install -m 0644 $gpback .
    done
    #Copy rawprogram.xml
    for rawpg in ${DEPLOY_DIR_IMAGE}/rawprogram[0-9].xml; do
        install -m 0644 $rawpg .
    done

    #Copy the .elf, .mbn, .fv files
    for elffile in ${DEPLOY_DIR_IMAGE}/*.elf; do
        install -m 0644 $elffile .
    done

    for mbnfile in ${DEPLOY_DIR_IMAGE}/*.mbn; do
        install -m 0644 $mbnfile .
    done

    # copy sec.dat
    if [ -f ${DEPLOY_DIR_IMAGE}/sec.dat ]; then
        install -m 0644 ${DEPLOY_DIR_IMAGE}/sec.dat sec.dat
    fi

    # copy logfs_ufs_8mb.bin
    if [ -f ${DEPLOY_DIR_IMAGE}/logfs_ufs_8mb.bin ]; then
        install -m 0644 ${DEPLOY_DIR_IMAGE}/logfs_ufs_8mb.bin logfs_ufs_8mb.bin
    fi

    for fvfile in ${DEPLOY_DIR_IMAGE}/*.fv; do
        if [ -f "$fvfile" ]; then
            install -m 0644 $fvfile .
        fi
    done

    for patchfile in ${DEPLOY_DIR_IMAGE}/patch*.xml; do
        install -m 0644 $patchfile .
    done

    #Install qdl
    install -m 0644 ${STAGING_BINDIR_NATIVE}/qdl .
}
addtask do_deploy_fixup after do_image_complete before do_build
