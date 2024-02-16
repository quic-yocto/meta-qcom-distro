#This is a temp fix to add kernel_cmdline.

FILESEXTRAPATHS:prepend := "${THISDIR}/linux-yocto:"

SRC_URI:append:qcom = " \
	file://kernel_cmdline_extra.cfg \
"
