#!/bin/bash
#
#
#---------------------------------------------------------
# Setup environment to use an epsci SPACK installation.
#
# This should usually be sourced with no arguments. It
# will try to automatically determine the os and release. 
# It will setup the correct spack environment for it based
# on the output of running lsb_release.
#
# Run with "-h" for details.
#
#---------------------------------------------------------

# Usage
function spack_env_usage () {
	echo "Usage:"
	echo ""
	echo "source spack_env.sh [os release [compiler]]"
	echo ""
	echo "This script should be sourced to set up your shell"
	echo "environment to use a spack installation from CVMFS."
	echo "It should normally be run with no arguments and it"
	echo "determine the OS/Release automatically by running the"
	echo "lsb_release program. You may also specify the OS and"
	echo "Release values by passing them as the first two "
	echo "positional arguments of the script."
	echo ""
	echo "e.g."
	echo ""
	echo "  source /cvmfs/oasis.opensciencegrid.org/jlab/epsci/spack_env.sh centos 7.7.1908"
	echo ""
	echo "The valid values for os and release can be found by"
	echo "looking at the subdirectories of the directory"
	echo "/cvmfs/oasis.opensciencegrid.org/jlab/epsci ."
	echo ""
	echo "This will configure your shell environment so that"
	echo "you can use the lmod module system. Heirarchical"
	echo "modules are enabled so only modules relevant for the"
	echo "currently configured compiler will be shown by default."
	echo "For example, if you wish to use the gcc 9.3.0 compiler"
	echo "load it with:"
	echo ""
	echo "     module load gcc/9.3.0"
	echo ""
	echo "Then check what packages are available with:"
	echo ""
	echo "     module avail"
	echo ""
	echo "You may also specify the compiler when sourcing this"
	echo "script by giving it as a 3rd argument. In this case"
	echo "you will need to also give the os and release arguments."
	echo ""
}

# Print usage statement and exit if -h option is given
#foreach s ( $* ); if ( $s == '-h' ) then ; spack_env_usage ; endif ; end
for s  in "$@" ; do
	if [ $s == '-h' ] ; then
		spack_env_usage
		return
	fi
done


# Get os name and release
if [ "$#" -ge 2 ] ; then
	os=$1
	ver=$2
else
	os=$(lsb_release -i -s)
	ver=$(lsb_release -r -s)
fi

# Coherce os name/release to match installed versions
os=$(echo "$os" | tr '[A-Z]' '[a-z]')  # make lowercase
case $os in
	'redhatenterpriseserver')  # We don't build separately for RHEL
		os='centos'
		[ "$ver" = '7.9' ] && ver='7.7.1908'
		;;
	*) # default
		;;
esac

# Source the appropriate SPACK setup file followed
# by the the modules_setup file
setupfile="/cvmfs/oasis.opensciencegrid.org/jlab/epsci/${os}/${ver}/share/spack/setup-env.sh"
if [ -f ${setupfile} ] ; then

	# Source the SPACK setup-env.sh file
	cmd="source ${setupfile}"
	echo $cmd
	$cmd

	spack load lmod
	source $(spack location -i lmod)/lmod/lmod/init/bash
	spackarch=$(spack arch)
	spackgenarch=$(spack arch -p)-$(spack arch -o)-x86_64
	module unuse ${SPACK_ROOT}/share/spack/modules/${spackarch}
	module unuse ${SPACK_ROOT}/share/spack/modules/${spackgenarch}
	module use ${SPACK_ROOT}/share/spack/lmod/${spackgenarch}/Core

	#cmd="source modules_setup.sh"
	#echo $cmd
	#$cmd

	# Optionally load the specified compiler
	if [ "$#" -ge 3 ] ; then
		cmd="module load $3"
		echo $cmd
		$cmd
	fi
else
	echo "No file: $setupfile"
	echo "No spack config for os/release: ${os}/${ver}"
fi

