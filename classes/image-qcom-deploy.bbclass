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

inherit python3native image-efi

DEPENDS:append = " \
    python3-native \
    qdl-native \
    "
# generate partition artifacts in DEPLOYDIR
PARTBINS_DEPLOYDIR = "${WORKDIR}/partition-bins-${PN}"

do_gen_partition_bins[depends] += " \
    partition-confs:do_deploy \
    ptool-native:do_populate_sysroot \
   "
do_gen_partition_bins() {
    # Step1: Cleanup stale partition bins
    rm -f ${DEPLOY_DIR_IMAGE}/gpt_backup?.bin
    rm -f ${DEPLOY_DIR_IMAGE}/gpt_both?.bin
    rm -f ${DEPLOY_DIR_IMAGE}/gpt_empty?.bin
    rm -f ${DEPLOY_DIR_IMAGE}/gpt_main?.bin
    rm -f ${DEPLOY_DIR_IMAGE}/patch?.xml
    rm -f ${DEPLOY_DIR_IMAGE}/rawprogram?*.xml
    rm -f ${DEPLOY_DIR_IMAGE}/zeros_*.bin
    rm -f ${DEPLOY_DIR_IMAGE}/wipe_rawprogram_PHY?.xml

    # Step2: Call ptool to generate partition bins
    cd ${PARTBINS_DEPLOYDIR} && ${STAGING_BINDIR_NATIVE}/ptool.py -x ${DEPLOY_DIR_IMAGE}/partition.xml
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
do_deploy_fixup[depends] += "firmware-${MACHINE}-boot:do_deploy"
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

    # copy kernel modules
    if [ -f ${DEPLOY_DIR_IMAGE}/modules-${MODULE_TARBALL_LINK_NAME}.tgz ]; then
         install -m 0644 ${DEPLOY_DIR_IMAGE}/modules-${MODULE_TARBALL_LINK_NAME}.tgz kernel-modules.tgz
    fi

    # copy efi.bin
    if [ -f ${DEPLOY_DIR_IMAGE}/efi.bin ]; then
        install -m 0644 ${DEPLOY_DIR_IMAGE}/efi.bin efi.bin
    fi

    # copy dtb.bin
    if [ -f ${DEPLOY_DIR_IMAGE}/dtb.bin ]; then
        install -m 0644 ${DEPLOY_DIR_IMAGE}/dtb.bin dtb.bin
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

    #Copy the .elf, .mbn files
    for elffile in ${DEPLOY_DIR_IMAGE}/*.elf; do
        install -m 0644 $elffile .
    done

    for mbnfile in ${DEPLOY_DIR_IMAGE}/*.mbn; do
        install -m 0644 $mbnfile .
    done

    #Copy the .melf, .fv files
    for melffile in ${DEPLOY_DIR_IMAGE}/*.melf; do
        if [ -f "$melffile" ]; then
            install -m 0644 $melffile .
        fi
    done

    for fvfile in ${DEPLOY_DIR_IMAGE}/*.fv; do
        if [ -f "$fvfile" ]; then
            install -m 0644 $fvfile .
        fi
    done

    # copy logfs_ufs_8mb.bin
    if [ -f ${DEPLOY_DIR_IMAGE}/logfs_ufs_8mb.bin ]; then
        install -m 0644 ${DEPLOY_DIR_IMAGE}/logfs_ufs_8mb.bin logfs_ufs_8mb.bin
    fi

    # copy zeros_5sectors.bin
    if [ -f ${DEPLOY_DIR_IMAGE}/zeros_5sectors.bin ]; then
        install -m 0644 ${DEPLOY_DIR_IMAGE}/zeros_5sectors.bin zeros_5sectors.bin
    fi

    for patchfile in ${DEPLOY_DIR_IMAGE}/patch*.xml; do
        install -m 0644 $patchfile .
    done

    #Install qdl
    install -m 0755 ${STAGING_BINDIR_NATIVE}/qdl .
}
addtask do_deploy_fixup after do_image_complete before do_build

python do_combine_dtbos () {
    import os, shutil, subprocess

    dtbdir = os.path.join(d.getVar('DEPLOY_DIR_IMAGE'),"dtb")
    if os.path.exists(dtbdir):
        shutil.rmtree(dtbdir)
    os.mkdir(dtbdir)
    combined_dtb = os.path.join(dtbdir, "combined-dtb.dtb")
    print(combined_dtb)

    for dtbf in d.getVar("KERNEL_DEVICETREE").split():
        dtb = os.path.basename(dtbf)
        with open(combined_dtb, 'ab') as fout:
            with open(os.path.join(d.getVar('DEPLOY_DIR_IMAGE'),dtb), 'rb') as fin:
                shutil.copyfileobj(fin, fout)
    joint_dtb_list = "%s %s" %(d.getVar("KERNEL_DEVICETREE"), "combined-dtb.dtb")

}

addtask do_combine_dtbos after do_image_complete before do_deploy_fixup

build_fat_dtb() {
    CONCATDTB=${DEPLOY_DIR_IMAGE}/dtb
    DTBBIN=${DEPLOY_DIR_IMAGE}/dtb.bin
    rm -rf ${DTBBIN}
    build_fat_img ${CONCATDTB} ${DTBBIN}
}
do_dtb_img[depends] += " \
    dosfstools-native:do_populate_sysroot \
    mtools-native:do_populate_sysroot \
    ${PN}:do_combine_dtbos \
   "

python do_dtb_img() {
    bb.build.exec_func('build_fat_dtb', d)
}

addtask do_dtb_img after do_combine_dtbos before do_deploy_fixup

# Merge tech dtbos before generating boot.img
do_merge_dtbos[nostamp] = "1"
do_merge_dtbos[cleandirs] = "${DEPLOY_DIR_IMAGE}/DTOverlays"
do_merge_dtbos[depends] += "dtc-native:do_populate_sysroot virtual/kernel:do_deploy"

python do_merge_dtbos () {
    import os, shutil, subprocess

    fdtoverlay_bin = d.getVar('STAGING_BINDIR_NATIVE') + "/fdtoverlay"
    dtbotpdir = d.getVar('DEPLOY_DIR_IMAGE') + "/" + "tech_dtbs"
    dtoverlaydir = d.getVar('DEPLOY_DIR_IMAGE') + "/" + "DTOverlays"
    os.makedirs(dtbotpdir, exist_ok=True)

    for kdt in d.getVar("KERNEL_DEVICETREE").split():
        org_kdtb = os.path.join(d.getVar('DEPLOY_DIR_IMAGE'), os.path.basename(kdt))

        # Rename and copy original kernel devicetree files
        kdtb = os.path.basename(org_kdtb) + ".0"
        shutil.copy2(org_kdtb, os.path.join(dtbotpdir, kdtb))

        # Find  and append matching dtbos for each dtb
        dtb = os.path.basename(org_kdtb)
        dtb_name = dtb.rsplit('.', 1)[0]
        dtbo_list =(d.getVarFlag('KERNEL_TECH_DTBOS', dtb_name) or "").split()
        bb.debug(1, "%s dtbo_list: %s" % (dtb_name, dtbo_list))
        dtbos_found = 0
        for dtbo_file in dtbo_list:
            dtbos_found += 1
            dtbo = os.path.join(dtbotpdir, dtbo_file)
            pre_kdtb = os.path.join(dtbotpdir, dtb + "." + str(dtbos_found - 1))
            post_kdtb = os.path.join(dtbotpdir, dtb + "." + str(dtbos_found))
            cmd = fdtoverlay_bin + " -v -i "+ pre_kdtb +" "+ dtbo +" -o "+ post_kdtb
            bb.debug(1, "merge_dtbos cmd: %s" % (cmd))
            try:
                subprocess.check_output(cmd, shell=True)
            except RuntimeError as e:
                bb.error("cmd: %s failed with error %s" % (cmd, str(e)))
        if dtbos_found == 0:
            bb.debug(1, "No tech dtbos to merge into %s" % dtb)

        #Copy latest overlayed file into DTOverlays path
        output = dtb + "." + str(dtbos_found)
        shutil.copy2(os.path.join(dtbotpdir, output), dtoverlaydir)
        os.symlink(os.path.join(dtoverlaydir, output), os.path.join(dtoverlaydir, dtb))
}
addtask merge_dtbos before do_image after do_rootfs
