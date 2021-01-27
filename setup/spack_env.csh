#!/bin/tcsh -f
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

# Print pseudo line numbers for debugging
#set _lineno=19
#alias postcmd '@ _lineno++ && echo -n $_lineno" "'

# (t)csh does not have user defined functions so we use a
# temporary alias instead
alias spack_env_usage eval '\
	echo "Usage:";\
	echo "";\
	echo "source spack_env.csh [os release [compiler]]";\
	echo "";\
	echo "This script should be sourced to set up your shell";\
	echo "environment to use a spack installation from CVMFS.";\
	echo "It should normally be run with no arguments and it";\
	echo "determine the OS/Release automatically by running the";\
	echo "lsb_release program. You may also specify the OS and";\
	echo "Release values by passing them as the first two ";\
	echo "positional arguments of the script.";\
	echo "";\
	echo "e.g.";\
	echo "";\
	echo "  source /cvmfs/oasis.opensciencegrid.org/jlab/epsci/spack_env.csh centos 7.7.1908";\
	echo "";\
	echo "The valid values for os and release can be found by";\
	echo "looking at the subdirectories of the directory";\
	echo "/cvmfs/oasis.opensciencegrid.org/jlab/epsci .";\
	echo "";\
	echo "This will configure your shell environment so that";\
	echo "you can use the lmod module system. Heirarchical";\
	echo "modules are enabled so only modules relevant for the";\
	echo "currently configured compiler will be shown by default.";\
	echo "For example, if you wish to use the gcc 9.3.0 compiler";\
	echo "load it with:";\
	echo "";\
	echo "     module load gcc/9.3.0";\
	echo "";\
	echo "Then check what packages are available with:";\
	echo "";\
	echo "     module avail";\
	echo "";\
	echo "You may also specify the compiler when sourcing this";\
	echo "script by giving it as a 3rd argument. In this case";\
	echo "you will need to also give the os and release arguments.";\
	echo ""; \
	unalias spack_env_usage;\
	exit'

# Print usage statement and exit if -h option is given
#foreach s ( $* ); if ( $s == '-h' ) then ; spack_env_usage ; endif ; end
foreach s ( $* )
	if ( $s == '-h' ) then
		spack_env_usage
	endif
end


# Get os name and release
if ( $# >= 2 ) then
	set os=$1
	set ver=$2
else
	set os=`lsb_release -i -s`
	set ver=`lsb_release -r -s`
endif

# Coherce os name/release to match installed versions
set os=`echo "$os" | tr '[A-Z]' '[a-z]'`  # make lowercase
switch ($os)
	case 'redhatenterpriseserver':  # We don't build separately for RHEL
		set os='centos'
		if $ver == '7.9' set ver='7.7.1908'
		breaksw
	default:
		breaksw
endsw

# Source the appropriate SPACK setup file followed
# by the the modules_setup file
set setupfile="/cvmfs/oasis.opensciencegrid.org/jlab/epsci/${os}/${ver}/share/spack/setup-env.csh"
if ( -f ${setupfile} ) then
	set cmd="source ${setupfile}"
	echo $cmd
	$cmd

	# Setup to use heirarchical lmod modules from spack.
	# Disable the non-heirarchical modules
	spack load lmod
	source `spack location -i lmod`/lmod/lmod/init/cshrc
	set spackarch=`spack arch`
	set spackgenarch=`spack arch -p`-`spack arch -o`-x86_64
	module unuse ${SPACK_ROOT}/share/spack/modules/${spackarch}
	module unuse ${SPACK_ROOT}/share/spack/modules/${spackgenarch}
	module use ${SPACK_ROOT}/share/spack/lmod/${spackgenarch}/Core

	#set cmd="source modules_setup.csh"
	#echo $cmd
	#$cmd

	# Optionally load the specified compiler
	if ( $# >= 3 ) then
		set cmd="module load $3"
		echo $cmd
		$cmd
	endif
else
	echo "No file: $setupfile"
	echo "No spack config for os/release: ${os}/${ver}"
endif

