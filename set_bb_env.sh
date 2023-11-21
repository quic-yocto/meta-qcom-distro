# Copyright (c) 2023 Qualcomm Innovation Center, Inc. All rights reserved.
# SPDX-License-Identifier: BSD-3-Clause-Clear

# set_bb_env.sh
# Define macros for build targets.
# Some convenience macros are defined to save some typing.
# Set the build environment.

if [[ ! $(readlink -f $(which sh)) =~ bash ]]
then
    echo ""
    echo "### ERROR: Please Change your /bin/sh symlink to point to bash. ### "
    echo ""
    echo "### sudo ln -sf /bin/bash /bin/sh ### "
    echo ""
    return 1
fi

# The SHELL variable also needs to be set to /bin/bash otherwise the build
# will fail, use chsh to change it to bash.
if [[ ! $SHELL =~ bash ]]
then
    echo ""
    echo "### ERROR: Please Change your shell to bash using chsh. ### "
    echo ""
    echo "### Make sure that the SHELL variable points to /bin/bash ### "
    echo ""
    return 1
fi

umask 022

# This script
THIS_SCRIPT=$(readlink -f ${BASH_SOURCE[0]})
# Find where the global conf directory is...
scriptdir="$(dirname "${THIS_SCRIPT}")"
# Find where the workspace is...
WS=$(readlink -f $scriptdir/../..)

usage () {
    cat <<EOF

Usage: [DISTRO=<DISTRO>] [MACHINE=<MACHINE>] source ${THIS_SCRIPT} [BUILDDIR]

If no MACHINE is set, list all possible machines, and ask user to choose.
If no DISTRO is set, list all possible distros, and ask user to choose.
If no BUILDDIR is set, it will be set to build-DISTRO.
If BUILDDIR is set and is already configured it is used as-is

EOF
}

# Eventually we need to call oe-init-build-env to finalize the configuration
# of the newly created build folder
init_build_env () {
    # Let bitbake use the following env-vars as if they were pre-set bitbake ones.
    # (BBLAYERS is explicitly blocked from this within OE-Core itself, though...)
    BB_ENV_PASSTHROUGH_ADDITIONS="DEBUG_BUILD"

    # Yocto/OE-core works a bit differently than OE-classic. We're going
    # to source the OE build environment setup script that Yocto provided.
    . ${WS}/layers/poky/oe-init-build-env ${BUILDDIR}

    # Clean up environment.
    unset MACHINE DISTRO WS usage THIS_SCRIPT
    unset DISTROTABLE DISTROLAYERS MACHINETABLE MACHLAYERS ITEM
}

if [ $# -gt 1 ]; then
    usage
    return 1
fi

# If BUILDDIR is provided and is already a valid build folder, let's use it
if [ $# -eq 1 ]; then
    BUILDDIR="${WS}/$1"
    if [ -f "${BUILDDIR}/conf/local.conf" ] &&
           [ -f "${BUILDDIR}/conf/auto.conf" ] &&
           [ -f "${BUILDDIR}/conf/bblayers.conf" ]; then
        init_build_env
        return
    fi
fi

# Choose one among whiptail & dialog to show dialog boxes
read uitool <<< "$(which whiptail dialog 2> /dev/null)"

# create a common list of "<machine>(<layer>)", sorted by <machine>
# Restrict to meta-qcom machines, qemuarm 32 and 64
MACHLAYERS=$(find layers -print | grep "qemuarm.conf\|qemuarm64.conf\|meta-qcom-hwe/conf/machine/.*\.conf" | sed -e 's/\.conf//g' -e 's/layers\///' | awk -F'/conf/machine/' '{print $NF "(" $1 ")"}' | LANG=C sort)

if [ -n "${MACHLAYERS}" ] && [ -z "${MACHINE}" ]; then
    for ITEM in $MACHLAYERS; do
        if [[ $PREFMACH == *$(echo "$ITEM" |cut -d'(' -f1)* ]]; then
            MACHINETABLE="${MACHINETABLE} $(echo "$ITEM" | cut -d'(' -f1) $(echo "$ITEM" | cut -d'(' -f2 | cut -d')' -f1)"
        fi
    done
    if [ -n "${MACHINETABLE}" ]; then
        MACHINE=$($uitool --title "Preferred Machines" --menu \
            "Please choose a machine" 0 0 20 \
            ${MACHINETABLE} 3>&1 1>&2 2>&3)
    fi
    if [ -z "${MACHINE}" ]; then
        for ITEM in $MACHLAYERS; do
            MACHINETABLE="${MACHINETABLE} $(echo "$ITEM" | cut -d'(' -f1) $(echo "$ITEM" | cut -d'(' -f2 | cut -d')' -f1)"
        done
        MACHINE=$($uitool --title "Available Machines" --menu \
            "Please choose a machine" 0 0 20 \
            ${MACHINETABLE} 3>&1 1>&2 2>&3)
    fi
fi

# create a common list of "<distro>(<layer>)", sorted by <distro>
DISTROLAYERS=$(find layers -print | grep "conf/distro/.*\.conf" | grep -v scripts | grep -v openembedded-core | sed -e 's/\.conf//g' -e 's/layers\///' | awk -F'/conf/distro/' '{print $NF "(" $1 ")"}' | LANG=C sort)

if [ -n "${DISTROLAYERS}" ] && [ -z "${DISTRO}" ]; then
    for ITEM in $DISTROLAYERS; do
        if [[ $PREFDIST == *$(echo "$ITEM" |cut -d'(' -f1)* ]]; then
            DISTROTABLE="${DISTROTABLE} $(echo "$ITEM" | cut -d'(' -f1) $(echo "$ITEM" | cut -d'(' -f2 | cut -d')' -f1)"
        fi
    done
    if [ -n "${DISTROTABLE}" ]; then
        DISTRO=$($uitool --title "Preferred Distributions" --menu \
            "Please choose a distribution" 0 0 20 \
            ${DISTROTABLE} 3>&1 1>&2 2>&3)
    fi
    if [ -z "${DISTRO}" ]; then
        for ITEM in $DISTROLAYERS; do
            DISTROTABLE="${DISTROTABLE} $(echo "$ITEM" | cut -d'(' -f1) $(echo "$ITEM" | cut -d'(' -f2 | cut -d')' -f1)"
        done
        DISTRO=$($uitool --title "Available Distributions" --menu \
            "Please choose a distribution" 0 0 20 \
            ${DISTROTABLE} 3>&1 1>&2 2>&3)
    fi
fi

# If nothing has been set, go for 'nodistro'
if [ -z "$DISTRO" ]; then
    DISTRO="nodistro"
fi

# guard against Ctrl-D or cancel
if [ -z "$MACHINE" ]; then
    echo "To choose a machine interactively please install whiptail or dialog."
    echo "To choose a machine non-interactively please use the following syntax:"
    echo "    MACHINE=<your-machine> source ./setup-environment"
    echo ""
    echo "Press <ENTER> to see a list of your choices"
    read -r
    echo "$MACHLAYERS" | sed -e 's/(/ (/g' | sed -e 's/)/)\n/g' | sed -e 's/^ */\t/g'
    return
fi

if [ -z "${SDKMACHINE}" ]; then
    SDKMACHINE='x86_64'
fi

BUILDDIR="${WS}/build-$DISTRO"
DISTRO_VERSION='0.0'

if [ $# -eq 1 ]; then
    BUILDDIR="${WS}/$1"
fi

mkdir -p "${BUILDDIR}"/conf

# bblayers.conf
cat >| ${BUILDDIR}/conf/bblayers.conf <<EOF
# This configuration file is dynamically generated every time
# set_bb_env.sh is sourced to set up a workspace.  DO NOT EDIT.
#--------------------------------------------------------------
EOF
if [ -e $scriptdir/conf/bblayers.conf ]; then
    cat $scriptdir/conf/bblayers.conf >> ${BUILDDIR}/conf/bblayers.conf
fi

# local.conf
cat >| ${BUILDDIR}/conf/local.conf <<EOF
# This configuration file is dynamically generated every time
# set_bb_env.sh is sourced to set up a workspace.  DO NOT EDIT.
#--------------------------------------------------------------
EOF
if [ -e $scriptdir/conf/local.conf ]; then
    cat $scriptdir/conf/local.conf >> ${BUILDDIR}/conf/local.conf
fi

# auto.conf
cat >| ${BUILDDIR}/conf/auto.conf <<EOF
# This configuration file is dynamically generated every time
# set_bb_env.sh is sourced to set up a workspace.  DO NOT EDIT.
#--------------------------------------------------------------
DISTRO ?= "${DISTRO}"
MACHINE ?= "${MACHINE}"
SDKMACHINE ?= "${SDKMACHINE}"
DISTRO_VERSION ?= "${DISTRO_VERSION}"

# Extra options that can be changed by the user
INHERIT += "rm_work"

# Force error for dangling bbappends
BB_DANGLINGAPPENDS_WARNONLY_forcevariable = "false"
EOF

# site.conf
cat >| ${BUILDDIR}/conf/site.conf <<EOF
# This configuration file is dynamically generated every time
# set_bb_env.sh is sourced to set up a workspace.  DO NOT EDIT.
#--------------------------------------------------------------
SCONF_VERSION = "1"

# Where to store sources
DL_DIR = "${WS}/downloads"

# Where to save shared state
SSTATE_DIR = "${WS}/sstate-cache"

EOF
if [ -e $scriptdir/conf/site.conf ]; then
    cat $scriptdir/conf/site.conf >> ${BUILDDIR}/conf/site.conf
fi

cat <<EOF

Your build environment has been configured with:

    MACHINE = ${MACHINE}
    SDKMACHINE = ${SDKMACHINE}
    DISTRO = ${DISTRO}

You can now run 'bitbake <target>'

EOF

# Finalize
init_build_env
