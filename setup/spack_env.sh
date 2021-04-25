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
	echo ""
	echo "Usage:"
	echo ""
	echo "source spack_env.csh [os=OS/RELEASE] [lmod [modules]]"
	echo ""
	echo "This script should be sourced to set up your shell"
	echo "environment to use a spack installation from /cvmfs."
	echo "It should normally be run with no arguments or just"
	echo "lmod. One may optionally specify addtional modules"
	echo "to load."
	echo ""
	echo "modules"
	echo "==========================="
	echo "Additional modules may be specified at the end of the"
	echo "arguments list. These will be loaded using the"
	echo "module load command. If one specifies the special"
	echo "lmod module then that will be loaded via spack load"
	echo "and the environment modified to use the more user friendly"
	echo "heirachical module system available in the spack system."
	echo ""
	echo "NOTE: while specifying lmod is recommended, it will"
	echo "cause this script about 2 seconds longer to execute!"
	echo ""
	echo "Module names will be different depending on whether you"
	echo "use the default JLab lmod or the one loaded from spack."
	echo "The lmod module should be specified first if you specify"
	echo "additional module names using the more user-friendly"
	echo "naming scheme (i.e. package/version)"
	echo ""
	echo "compiler"
	echo "==========================="
	echo "You can specify a compiler to load by doing something like"
	echo "this:"
	echo ""
	echo "   source /cvmfs/oasis.opensciencegrid.org/jlab/epsci/spack_env.sh lmod gcc/9.3.0"
	echo ""
	echo "This will configure your shell environment so that"
	echo "you can use the lmod heirarchical module system. Heirarchical"
	echo "modules are enabled so only modules relevant for the"
	echo "currently configured compiler will be shown by default."
	echo "For example, if you wish to use the gcc 8.3.1 compiler"
	echo "load it with:"
	echo ""
	echo "     module load gcc/8.3.1"
	echo ""
	echo "Then check what packages are available with:"
	echo ""
	echo "     module avail"
	echo ""
	echo "os/release"
	echo "==========================="
	echo "This script will determine the OS/RELEASE value"
	echo "automatically by running the lsb_release program. You"
	echo "may also specify this using the os=XXX/YYY option."
	echo ""
	echo "e.g."
	echo ""
	echo "  source /cvmfs/oasis.opensciencegrid.org/jlab/epsci/spack_env.sh os=centos/7.7.1908"
	echo ""
	echo "The valid values for os and release can be found by"
	echo "looking at the subdirectories of the directory"
	echo "/cvmfs/oasis.opensciencegrid.org/jlab/epsci ."
	echo ""
	echo "Please direct any questions to:"
	echo "   davidl@jlab.org"
	echo ""
}

# Loop over command line arguments
os=""
ver=""
modules=""
for s  in "$@" ; do
	if [ $s == '-h' ] ; then
		# Help
		spack_env_usage
		return
	elif [[ "$s" == os=* ]] ; then
		# OS/Release
		os=`echo $s | cut -d '=' -f2 | cut -d '/' -f1`
		ver=`echo $s | cut -d '=' -f2 | cut -d '/' -f2`
		[ "$ver" == "$os" ] && ver=''
	else
		# Module
		modules="$modules $s"
	fi
done

# If user did not specify os name and release then find it
[ "$os"  == "" ] && os=`lsb_release -i -s`
[ "$ver" == "" ] && ver=`lsb_release -r -s`


# Print usage statement and exit if -h option is given
#foreach s ( $* ); if ( $s == '-h' ) then ; spack_env_usage ; endif ; end
#for s  in "$@" ; do
#	if [ $s == '-h' ] ; then
#		spack_env_usage
#		return
#	fi
#done


# Get os name and release
#if [ "$#" -ge 2 ] ; then
#	os=$1
#	ver=$2
#else
#	os=$(lsb_release -i -s)
#	ver=$(lsb_release -r -s)
#fi

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


	# This is left here for symmetry with the csh version of this
	# script. It does not look like the bash version of the 
	# spack setup-env.sh script does the same contortions to 
	# get at the SPACK_ROOT value.
	#
	export SPACK_ROOT="/cvmfs/oasis.opensciencegrid.org/jlab/epsci/${os}/${ver}"

	# Source the SPACK setup-env.csh file
	cmd="source ${setupfile}"
	[[ $- == *i* ]] && echo $cmd
	$cmd
	
	# Loop over modules user wants automatically loaded
	for  mod in $modules ; do

		# lmod is special. For this we need to "spack load" this
		# and then do additional environment manipulations to enable
		# the heirachical modules.
		# This looks for any module starting with "lmod" in case
		# user wants to specify a specific version.  
		if [[ $mod == lmod* ]] ; then
			# Disable the non-heirarchical modules so we can enable
			# heirarchical modules below.
			spackarch=$(spack arch)	
			spackgenarch=$(echo $spackarch | cut -d '-' -f1,2)-x86_64 # this is faster than: set spackgenarch=`spack arch -p`-`spack arch -o`-x86_64

			# Setup to use heirarchical lmod modules from spack.
			# n.b. At one point it seemed running "spack location"
			# in a subprocess was adding more than a second to this
			# script compared to the following:
			#  set _lmod_loc = `echo $CMAKE_PREFIX_PATH | sed -e 's/:/\n/g' | grep lmod | head -n 1`
			# Subsequent testing did not support that. I'm leaving this
			# comment here in case we need to revisit using the above alternative
			cmd="spack load --first $mod"
			[[ $- == *i* ]] && echo $cmd
			$cmd
			#spack load $mod
			#_lmod_loc=$(spack location -i $mod)  # this fails if more than one lmod is present
			_lmod_loc=$(spack find -p $mod | grep lmod | head -n 1 | awk '{print $2}')
			source ${_lmod_loc}/lmod/lmod/init/bash
			module unuse ${SPACK_ROOT}/share/spack/modules/${spackarch} ${SPACK_ROOT}/share/spack/modules/${spackgenarch}
			module use ${SPACK_ROOT}/share/spack/lmod/${spackgenarch}/Core
		else
			
			# Any modules other than lmod should be loaded with "module load"
			cmd="module load $mod"
			[[ $- == *i* ]] && echo $cmd
			$cmd

		fi

	done

else
	echo "No file: $setupfile"
	echo "No spack config for os/release: ${os}/${ver}"
fi

