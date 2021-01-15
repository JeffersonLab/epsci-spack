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

# Checkout primary spack repository (if needed)
spack_top=/cvmfs/oasis.opensciencegrid.org/jlab/epsci/${spack_os}/${spack_ver}
if [ ! -d ${spack_top} ] ; then
	echo "Checking out primary spack repository ..."
	git clone https://github.com/spack/spack.git ${spack_top}
fi
source ${spack_top}/share/spack/setup-env.sh

# Checkout eic-spack repository (if needed)
eic_spack_top=${SPACK_ROOT}/var/spack/repos/eic-spack
if [ ! -d ${eic_spack_top} ] ; then
	echo "Checking out eic-spack repository ..."
	git clone https://github.com/eic/eic-spack.git ${eic_spack_top}
fi
# Add eic-spack repo to our list if it is not already there
spack repo list | grep ${eic_spack_top} > /dev/null
[ $? != 0 ] && spack repo add ${eic_spack_top}
#[ ! $(spack repo list | grep -q ${eic_spack_top}) ] && spack repo add ${eic_spack_top}

# Checkout epsci-spack repository (if needed)
epsci_spack_top=${SPACK_ROOT}/var/spack/repos/epsci-spack
if [ ! -d ${epsci_spack_top} ] ; then
	echo "Checking out epsci-spack repository ..."
	git clone https://github.com/JeffersonLab/epsci-spack.git ${epsci_spack_top}
else
	git --git-dir=${epsci_spack_top}/.git pull --ff-only  # Update to latest epsci-spack
fi
# Add eic-spack repo to our list if it is not already there
spack repo list | grep ${epsci_spack_top} > /dev/null
[ $? != 0 ] && spack repo add ${epsci_spack_top}


# If the specified compiler does not match the system compiler, then
# build the specified compiler using the system compiler.
spack compiler find
SYSTEM_GCCVERSION=$(/usr/bin/gcc --version | grep ^gcc | cut -d ')' -f 2 | awk '{print $1}')
echo "specified compiler=${spack_compiler}  SYSTEM_GCCVERSION=${SYSTEM_GCCVERSION}"
[ ${spack_compiler} == 'system' ] && spack_compiler=${SYSTEM_GCCVERSION}
if [ ${spack_compiler} != $SYSTEM_GCCVERSION ] ; then
	spack install gcc@${spack_compiler} arch=x86_64 %gcc@${SYSTEM_GCCVERSION}
	spack load gcc@${spack_compiler}
	spack compiler find
fi

# Install minimal set of packages
packages="unzip lmod"

for p in ${packages} ; do
	spack install -j${spack_build_threads} $p %gcc@${spack_compiler} arch=x86_64
	spack load $p %gcc@${spack_compiler} arch=x86_64
done

spack arch
spack compilers
spack repo list
spack find



