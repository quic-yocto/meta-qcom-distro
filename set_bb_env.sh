#!/bin/sh
#
# Copyright (c) 2023 Qualcomm Innovation Center, Inc. All rights reserved.
# SPDX-License-Identifier: BSD-3-Clause-Clear

# set_bb_env.sh
# Define macros for build targets.
# Some convenience macros are defined to save some typing.
# Set the build environment.

if ! $(return >/dev/null 2>&1) ; then
    echo 'error: this script must be sourced'
    echo ''
    exit 2
fi

WS=`pwd`
SCRIPT_NAME="setup-environment"

umask 022

usage () {
    cat <<EOF

Usage: [DISTRO=<DISTRO>] [MACHINE=<MACHINE>] source ${SCRIPT_NAME} [BUILDDIR]

If no MACHINE is set, list all possible machines, and ask user to choose.
If no DISTRO is set, list all possible distros, and ask user to choose.
If no BUILDDIR is set, it will be set to build-DISTRO.
If BUILDDIR is set and is already configured it is used as-is

EOF
}

if [ $# -gt 1 ]; then
    usage
    return 1
fi

OEROOT="$WS/layers/poky"
if [ -e "$WS/layers/openembedded-core" ]; then
    OEROOT="$WS/layers/openembedded-core"
fi

apply_poky_patches () {
    cd ${WS}/layers/poky

    patchfile='0001-fetch2-git-Add-verbose-logging-support.patch'
    wget -nv https://artifacts.codelinaro.org/artifactory/codelinaro-le/$patchfile
    git apply --check $patchfile
    if [ $? != 0 ] ; then
        echo " $patchfile ... patch Failed to apply, ignoring"
    else
        git apply $patchfile
    fi
    rm $patchfile

    cd -
}

# Eventually we need to call oe-init-build-env to finalize the configuration
# of the newly created build folder
init_build_env () {
    # Let bitbake use the following env-vars as if they were pre-set bitbake ones.
    BB_ENV_PASSTHROUGH_ADDITIONS="DEBUG_BUILD PERFORMANCE_BUILD FWZIP_PATH CUST_ID BB_GIT_VERBOSE_FETCH"
    apply_poky_patches &> /dev/null
    # Yocto/OE-core works a bit differently than OE-classic. We're going
    # to source the OE build environment setup script that Yocto provided.
    . ${OEROOT}/oe-init-build-env ${BUILDDIR}

    # Clean up environment.
    unset MACHINE SDKMACHINE DISTRO WS OEROOT usage SCRIPT_NAME
    unset EXTRALAYERS DEBUG_BUILD PERFORMANCE_BUILD FWZIP_PATH CUST_ID BB_GIT_VERBOSE_FETCH
    unset DISTROTABLE DISTROLAYERS MACHINETABLE MACHLAYERS ITEM
}

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
# Restrict to meta-qcom machines
MACHLAYERS=$(find layers -print | grep "meta-qcom-hwe/conf/machine/.*\.conf" | sed -e 's/\.conf//g' -e 's/layers\///' | awk -F'/conf/machine/' '{print $NF "(" $1 ")"}' | LANG=C sort)

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

# create a common list of "<distro>(<layer>)", sorted by <distro>
# Restrict to meta-qti-distro distros
DISTROLAYERS=$(find layers -print | grep "meta-qcom-distro/conf/distro/.*\.conf" | sed -e 's/\.conf//g' -e 's/layers\///' | awk -F'/conf/distro/' '{print $NF "(" $1 ")"}' | LANG=C sort)

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

# If not set, go for 'no debug' build
if [ -z "$DEBUG_BUILD" ]; then
    DEBUG_BUILD=0
fi

# If not set, go for normal build
if [ -z "$PERFORMANCE_BUILD" ]; then
    PERFORMANCE_BUILD=0
fi
# If debug is set, force no performance build
if [ $DEBUG_BUILD -ne 0 ]; then
    PERFORMANCE_BUILD=0
fi

if [ -z "${SDKMACHINE}" ]; then
    SDKMACHINE='x86_64'
fi

BUILDDIR="${WS}/build-$DISTRO"
DISTRO_VERSION='1.0'

if [ $# -eq 1 ]; then
    BUILDDIR="${WS}/$1"
fi

mkdir -p "${BUILDDIR}"/conf

##### bblayers.conf #####
cat >| ${BUILDDIR}/conf/bblayers.conf <<EOF
# This configuration file is dynamically generated every time
# set_bb_env.sh is sourced to set up a workspace.  DO NOT EDIT.
#--------------------------------------------------------------
EOF
if [ -e ${WS}/layers/meta-qcom-distro/conf/bblayers.conf ]; then
    cat ${WS}/layers/meta-qcom-distro/conf/bblayers.conf >> ${BUILDDIR}/conf/bblayers.conf
fi

# If EXTRALAYERS are avilable update them
if [ -n "${EXTRALAYERS}" ]; then
    earr=($EXTRALAYERS)
    for s in "${earr[@]}"; do
        str=\${WORKSPACE}/layers/$(echo "${s}")
        sed -i "/EXTRALAYERS ?= /a\\  ${str} \\ \\" ${BUILDDIR}/conf/bblayers.conf
    done
fi

##### local.conf #####
cat >| ${BUILDDIR}/conf/local.conf <<EOF
# This configuration file is dynamically generated every time
# set_bb_env.sh is sourced to set up a workspace.  DO NOT EDIT.
#--------------------------------------------------------------
EOF
if [ -e $WS/layers/meta-qcom-distro/conf/local.conf ]; then
    cat $WS/layers/meta-qcom-distro/conf/local.conf >> ${BUILDDIR}/conf/local.conf
fi
# If CUST_ID is avilable update
if [ -n "$CUST_ID" ]; then
   echo -e "\n# Cust ID" >> ${BUILDDIR}/conf/local.conf
   echo "CUST_ID = \"$CUST_ID\"" >> ${BUILDDIR}/conf/local.conf
fi
# If FWZIP_PATH is avilable update
if [ -n "$FWZIP_PATH" ]; then
   echo -e "\n# FW zip path" >> ${BUILDDIR}/conf/local.conf
   echo "FWZIP_PATH = \"$FWZIP_PATH\"" >> ${BUILDDIR}/conf/local.conf
fi
# If BB_GIT_VERBOSE_FETCH is avilable update
if [ -n "$BB_GIT_VERBOSE_FETCH" ]; then
   sed -i "s/^BB_GIT_VERBOSE_FETCH = .*$/BB_GIT_VERBOSE_FETCH = \"$BB_GIT_VERBOSE_FETCH\"/g" ${BUILDDIR}/conf/local.conf
fi

##### auto.conf #####
cat >| ${BUILDDIR}/conf/auto.conf <<EOF
# This configuration file is dynamically generated every time
# set_bb_env.sh is sourced to set up a workspace.  DO NOT EDIT.
#--------------------------------------------------------------
DISTRO = "${DISTRO}"
MACHINE = "${MACHINE}"
SDKMACHINE = "${SDKMACHINE}"
DISTRO_VERSION = "${DISTRO_VERSION}"
DEBUG_BUILD = "${DEBUG_BUILD}"
PERFORMANCE_BUILD = "${PERFORMANCE_BUILD}"

# Force error for dangling bbappends
BB_DANGLINGAPPENDS_WARNONLY_forcevariable = "false"

# Extra options that can be changed by the user
INHERIT += "rm_work"

EOF

##### site.conf #####
cat >| ${BUILDDIR}/conf/site.conf <<EOF
# This configuration file is dynamically generated every time
# set_bb_env.sh is sourced to set up a workspace.  DO NOT EDIT.
#--------------------------------------------------------------
SCONF_VERSION = "1"

# Where to store sources
DL_DIR = "${WS}/downloads"

# Where to save shared state
SSTATE_DIR = "${WS}/sstate-cache"

# Add codelinaro sites to MIRRORS
MIRRORS += "\
git://github.com git://git.codelinaro.org/clo/yocto-mirrors/github/ \
git://.*/.*/ git://git.codelinaro.org/clo/yocto-mirrors/ \
https://.*/.*/ https://codelinaro.jfrog.io/artifactory/codelinaro-le/ \
"

EOF
if [ -e $WS/layers/meta-qcom-distro/conf/site.conf ]; then
    cat $WS/layers/meta-qcom-distro/conf/site.conf >> ${BUILDDIR}/conf/site.conf
fi

cat <<EOF

Your build environment has been configured with:

    MACHINE = ${MACHINE}
    SDKMACHINE = ${SDKMACHINE}
    DISTRO = ${DISTRO}
    DEBUG_BUILD = ${DEBUG_BUILD}
    PERFORMANCE_BUILD = ${PERFORMANCE_BUILD}

You can now run 'bitbake <target>'

EOF

# Finalize
init_build_env
