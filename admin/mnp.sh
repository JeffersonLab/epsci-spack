#!/bin/bash
#
# This script is run from inside a singularity container to create
# new spack instance or update an existing one for a specific OS
# and compiler. It is run by the make_new_platform.sh script.
# (This should be run via that rather than directly.)
#
# This takes 4 arguments:
#
#   OS                'centos' or 'ubuntu'
#
#   OS_version        e.g. 7.7.1908
#
#   compiler_version  gcc version number like '9.3.0' or 'system'
#                     to use default system compiler
#
#   num_threads       number of build threads to tell packages to use
#
# 
# This will check if the repositories for the given platform
# exist and will clone them as needed. These include the main
# spack repository, and both the eic-spack and epsci-spack
# repositories. It will make sure the latter two are added to
# the current list of repos. It will also pull any updates from
# the epsci-spack repo. (Updates for the other two must be done
# manually.)
#
# NOTES:
#
#  1. The operations here may depend on settings in your ~/.spack
#     directory. This mainly consists of compilers and repos. This
#     script will make sure the required configurations are present.
#     However, it will not remove anything from the configuration.
#     This could potentially cause issues. I try to be explicit when
#     running things here wherever possible to try and avoid such issues.
#
#  2. Only a couple of packages are installed here. They do have a 
#     number of dependencies though so quite a few packages get 
#     installed as part of the "base" installation. Most of the
#     packages users will want to use will be installed later using
#     the "add_to_platform.sh" script.
#
#  3. It is safe to run this even if the spack instance for the
#     specified platform already exists. This will not delete any
#     packages that are already installed there. 
#

spack_os=$1
spack_ver=$2
spack_compiler=$3
spack_build_threads=$4
spack_arch=x86_64

# 5th argument is optional to specify the architecture (e.g. arm64 instead of x86_64)
[ ! -z "$5" ] && spack_arch="$5"

#------------------------------------------------------------------------------
# The following tries to match what spack will automatically determine the
# operating_system to be. This is important since it will add this to the
# compilers.yaml file and then filter on it when we specify an arch later.
# It is done here so we can make the proper directory name to clone the
# spack repository into.
#
# This should be used when spack_ver has 3 values. e.g. 7.7.1908
#spack_full_arch=linux-`echo ${spack_os}${spack_ver} | cut -f 1 -d .`-${spack_arch}
# This should be used when spack_ver has 3 values with a "-". e.g. 9.2-20230718
#spack_full_arch=linux-`echo ${spack_os}${spack_ver} | cut -f 1 -d -`-${spack_arch}
# This should be used when spack_ver has 2 values. e.g. 9.3 (spack will just use "9")
spack_full_arch=linux-`echo ${spack_os}${spack_ver} | cut -f 1 -d .`-${spack_arch}
echo "Building for arch=${spack_full_arch}"
#------------------------------------------------------------------------------

# Checkout primary spack repository (if needed)
spack_top=/cvmfs/oasis.opensciencegrid.org/jlab/epsci/spack/${spack_os}/${spack_ver}
if [ ! -d ${spack_top} ] ; then
	echo "Checking out primary spack repository ..."
	git clone https://github.com/spack/spack.git ${spack_top}
fi

if [ ! -d ${spack_top}/etc/spack ] ; then
	echo "Making config file directory "${spack_top}/etc/spack
	mkdir -p ${spack_top}/etc/spack
fi

# Install a config.yaml file to override defaults. This is needed
# to force builds to use /scratch instead of /tmp for builds.
if [ ! -f ${spack_top}/etc/spack/config.yaml ] ; then
	echo "Copying config.yaml to ${spack_top}/etc/spack/config.yaml ..."
	cp config.yaml ${spack_top}/etc/spack/config.yaml
fi

# Source main spack environment setup script. Note that when doing this
# in docker with qemu-x we must set SPACK_ROOT first.
export SPACK_ROOT=${spack_top}
echo "Sourcing ${spack_top}/share/spack/setup-env.sh"
source ${spack_top}/share/spack/setup-env.sh

# ---- Disable use of eic-spack repository since it replaces things
# ---- like root , geant4, and jana2  2022-12-29 DL
# Checkout eic-spack repository (if needed)
#eic_spack_top=${SPACK_ROOT}/var/spack/repos/eic-spack
#if [ ! -d ${eic_spack_top} ] ; then
#	echo "Checking out eic-spack repository ..."
#	git clone https://github.com/eic/eic-spack.git ${eic_spack_top}
#fi
# Add eic-spack repo to our list if it is not already there
#spack repo list | grep ${eic_spack_top} > /dev/null
#[ $? != 0 ] && spack repo add ${eic_spack_top}

# Checkout epsci-spack repository (if needed)
epsci_spack_top=${SPACK_ROOT}/var/spack/repos/epsci-spack
if [ ! -d ${epsci_spack_top} ] ; then
	echo "Checking out epsci-spack repository ..."
	git clone https://github.com/JeffersonLab/epsci-spack.git ${epsci_spack_top}
else
	git --git-dir=${epsci_spack_top}/.git pull --ff-only  # Update to latest epsci-spack
fi
# Add epsci-spack repo to our list if it is not already there
spack repo list | grep ${epsci_spack_top} > /dev/null
[ $? != 0 ] && spack repo add ${epsci_spack_top}


# If the specified compiler does not match the system compiler, then
# build the specified compiler using the system compiler.
spack compiler find
SYSTEM_GCCVERSION=$(/usr/bin/gcc --version | grep ^gcc | cut -d ')' -f 2 | awk '{print $1}')
echo "specified compiler=${spack_compiler}  SYSTEM_GCCVERSION=${SYSTEM_GCCVERSION}"
[ ${spack_compiler} == 'system' ] && spack_compiler=${SYSTEM_GCCVERSION}
if [ ${spack_compiler} != $SYSTEM_GCCVERSION ] ; then
	echo "spack install gcc@${spack_compiler} arch=${spack_full_arch} %gcc@${SYSTEM_GCCVERSION}"
	spack install gcc@${spack_compiler} arch=${spack_full_arch} %gcc@${SYSTEM_GCCVERSION}
	echo "spack load gcc@${spack_compiler}"
	spack load gcc@${spack_compiler}
	spack compiler find
fi

# Install the modules.yaml file if not already installed. Replace
# the "XXX" string in the file here with the system compiler
# version.
if [ ! -f ${spack_top}/etc/spack/modules.yaml ] ; then
	echo "Copying modules.yaml to ${spack_top}/etc/spack/modules.yaml ..."
#	cat modules.yaml | sed -e "s/XXX/${SYSTEM_GCCVERSION}/g" | sed -e "s/YYY/${spack_full_arch}/g" > ${spack_top}/etc/spack/modules.yaml
fi

# Make sure the directory exists for packages built with this compiler
# Oddly, spack does not seem to create this automatically and the 
# throws errors when it starts trying to install packages with our
# newly built compiler.
mkdir -p ${spack_top}/opt/spack/linux-*-x86_64/gcc-${spack_compiler}


# Install minimal set of packages
packages="unzip lmod"

for p in ${packages} ; do
	echo "spack install -j${spack_build_threads} $p %gcc@${spack_compiler} arch=${spack_full_arch}"
	spack install -j${spack_build_threads} $p %gcc@${spack_compiler} arch=${spack_full_arch}
	echo "spack load $p %gcc@${spack_compiler} arch=${spack_full_arch}"
	spack load $p %gcc@${spack_compiler} arch=${spack_full_arch}
done

spack arch
spack compilers
spack repo list
spack find



