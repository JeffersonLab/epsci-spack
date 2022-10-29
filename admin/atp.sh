#!/bin/bash
#
# This script is run inside a singularity container to install
# a number of spack packages listed in the given file. It is
# run by the add_to_platform.sh script. (This should be run via
# that rather than directly.) For example, run this:
#
#    ./add_to_platform_centos7.sh ./jlabce2.4.sh
#
#
# This takes 5 arguments:
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
#   packages_file     file with list of spack packages to install.


spack_os=$1
spack_ver=$2
spack_compiler=$3
spack_build_threads=$4
spack_packages_file=$5

spack_ver_major="${spack_ver%%.*}"
arch="linux-${spack_os}${spack_ver_major}-x86_64"

echo "specifying arch as: ${arch}"

# Setup to use spack repositories.
spack_top=/cvmfs/oasis.opensciencegrid.org/jlab/epsci/${spack_os}/${spack_ver}
source ${spack_top}/share/spack/setup-env.sh

# Additional repositories (eic, epsci) are listed in a users
# personal ~/.spack directory. These are automatically added 
# by mnp.sh, but if a different user is runing this script
# then they may need to be added. Check here if they are and 
# add them if needed.
eic_spack_top=${SPACK_ROOT}/var/spack/repos/eic-spack
epsci_spack_top=${SPACK_ROOT}/var/spack/repos/epsci-spack
if [ -d ${eic_spack_top} ] ; then
	spack repo list | grep ${eic_spack_top} > /dev/null
	[ $? != 0 ] && echo "Adding eic-spack repository to your personal config ..." && spack repo add ${eic_spack_top}
fi
if [ -d ${epsci_spack_top} ] ; then
	spack repo list | grep ${epsci_spack_top} > /dev/null
	[ $? != 0 ] && echo "Adding epsci-spack repository to your personal config ..." && spack repo add ${epsci_spack_top}
fi

# Load the compiler
SYSTEM_GCCVERSION=$(/usr/bin/gcc --version | grep ^gcc | cut -d ')' -f 2 | awk '{print $1}')
echo "specified compiler=${spack_compiler}  SYSTEM_GCCVERSION=${SYSTEM_GCCVERSION}"
[ ${spack_compiler} == 'system' ] && spack_compiler=${SYSTEM_GCCVERSION}
[ ${spack_compiler} != $SYSTEM_GCCVERSION ] && spack load gcc@${spack_compiler}

# Extract the spack environment name from the input packages file name
filename=$(basename -- "$spack_packages_file")  # remove path (if any)
envname="${filename%.*}"                       # remove suffix

# Create and active spack environment
cmd="spack env create $envname"
echo $cmd
$cmd
cmd="spack env activate $envname"
echo $cmd
$cmd

# Install all packages from $spack_packages_file
while read p; do
	[[ $p = "#"* ]] && continue 
	[ -z "$p" ] && continue
	
	# Here we insert the specific compiler in front of all instances of "^".
	# This is to ensure the packages and dependencies are all built with
	# the specified compiler. We also specify the generic target=x86_64.
	p_with_compiler=$(echo $p | sed -e "s/\^/ arch=${arch} \%gcc@${spack_compiler}\^/g")

	# Print full concretization spec
	cmd="spack spec $p_with_compiler %gcc@${spack_compiler} arch=${arch}"
	echo $cmd
	$cmd

	# Create the full spack install command, print it, and run it.
	cmd="spack install -j${spack_build_threads} $p_with_compiler %gcc@${spack_compiler} arch=${arch}"
	echo $cmd
	$cmd

	#spack load ${p_with_compiler}%gcc@${spack_compiler} arch=${arch}
done < "$spack_packages_file"

# Print status
spack arch
spack compilers
spack repo list
spack find



