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

#
# To visually check which lines are taking a while to run,
# do this:
#
#    tcsh -x /scigroup/spack/setup/spack_env.csh
#

# Print pseudo line numbers for debugging
#set _lineno=19
#alias postcmd '@ _lineno++ && echo -n $_lineno" "'

# (t)csh does not have user defined functions so we use a
# temporary alias instead
alias spack_env_usage eval '\
	echo "";\
	echo "Usage:";\
	echo "";\
	echo "source spack_env.csh [os=OS/RELEASE] [lmod [modules]]";\
	echo "";\
	echo "This script should be sourced to set up your shell";\
	echo "environment to use a spack installation from /cvmfs.";\
	echo "It should normally be run with no arguments or just";\
	echo "lmod. One may optionally specify addtional modules";\
	echo "to load.";\
	echo "";\
	echo "modules";\
	echo "===========================";\
	echo "Additional modules may be specified at the end of the";\
	echo "arguments list. These will be loaded using the";\
	echo "module load command. If one specifies the special";\
	echo "lmod module then that will be loaded via spack load";\
	echo "and the environment modified to use the more user friendly";\
	echo "heirachical module system available in the spack system.";\
	echo "";\
	echo "NOTE: while specifying lmod is recommended, it will";\
	echo "cause this script about 2 seconds longer to execute!";\
	echo "";\
	echo "Module names will be different depending on whether you";\
	echo "use the default JLab lmod or the one loaded from spack.";\
	echo "The lmod module should be specified first if you specify";\
	echo "additional module names using the more user-friendly";\
	echo "naming scheme (i.e. package/version)";\
	echo "";\
	echo "compiler";\
	echo "===========================";\
	echo "You can specify a compiler to load by doing something like";\
	echo "this:";\
	echo "";\
	echo "   source /cvmfs/oasis.opensciencegrid.org/jlab/epsci/spack_env.csh lmod gcc/9.3.0";\
	echo "";\
	echo "This will configure your shell environment so that";\
	echo "you can use the lmod heirarchical module system. Heirarchical";\
	echo "modules are enabled so only modules relevant for the";\
	echo "currently configured compiler will be shown by default.";\
	echo "For example, if you wish to use the gcc 8.3.1 compiler";\
	echo "load it with:";\
	echo "";\
	echo "     module load gcc/8.3.1";\
	echo "";\
	echo "Then check what packages are available with:";\
	echo "";\
	echo "     module avail";\
	echo "";\
	echo "os/release";\
	echo "===========================";\
	echo "This script will determine the OS/RELEASE value";\
	echo "automatically by running the lsb_release program. You";\
	echo "may also specify this using the os=XXX/YYY option.";\
	echo "";\
	echo "e.g.";\
	echo "";\
	echo "  source /cvmfs/oasis.opensciencegrid.org/jlab/epsci/spack_env.csh os=centos/7.7.1908";\
	echo "";\
	echo "The valid values for os and release can be found by";\
	echo "looking at the subdirectories of the directory";\
	echo "/cvmfs/oasis.opensciencegrid.org/jlab/epsci .";\
	echo "";\
	echo "Please direct any questions to:";\
	echo "   davidl@jlab.org";\
	echo "";\
	unalias spack_env_usage;\
	exit;\
	'

# Loop over command line arguments
set os=""
set ver=""
set modules=""
foreach s ( $* )
	if ( $s == '-h' ) then
		# Help
		spack_env_usage  # This will exit the script after printing the usage statements
	else if ( "$s" =~ 'os=*' ) then
		# OS/Release
		set os=`echo $s | cut -d '=' -f2 | cut -d '/' -f1`
		set ver=`echo $s | cut -d '=' -f2 | cut -d '/' -f2`
		if ( "$ver" == "$os" ) set ver=''
	else
		# Module
		set modules="$modules $s"
	endif
end

# If user did not specify os name and release then find it
if ( "$os"  == "" ) set os=`lsb_release -i -s`
if ( "$ver" == "" ) set ver=`lsb_release -r -s`

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

	# The first thing the spack setup-env.csh file does is try and set
	# SPACK_ROOT if it is not already set. It does this by running
	# subprocesses to get a list of open file descriptors for this
	# process which can take a while. Avoid that by just setting
	# SPACK_ROOT here.
	setenv SPACK_ROOT "/cvmfs/oasis.opensciencegrid.org/jlab/epsci/${os}/${ver}"

	# Source the SPACK setup-env.csh file
	set cmd="source ${setupfile}"
	if ( $?loginsh ) echo $cmd
	$cmd
	
	# Loop over modules user wants automatically loaded
	foreach mod ($modules)

		# lmod is special. For this we need to "spack load" this
		# and then do additional environment manipulations to enable
		# the heirachical modules.
		# This looks for any module starting with "lmod" in case
		# user wants to specify a specific version.  
		if ( $mod =~ 'lmod*' ) then
			# Disable the non-heirarchical modules so we can enable
			# heirarchical modules below
			set spackarch=`spack arch`	
			set spackgenarch=`echo $spackarch | cut -d '-' -f1,2`-x86_64 # this is faster than: set spackgenarch=`spack arch -p`-`spack arch -o`-x86_64

			# Setup to use heirarchical lmod modules from spack.
			# n.b. At one point it seemed running "spack location"
			# in a subprocess was adding more than a second to this
			# script compared to the following:
			#  set _lmod_loc = `echo $CMAKE_PREFIX_PATH | sed -e 's/:/\n/g' | grep lmod | head -n 1`
			# Subsequent testing did not support that. I'm leaving this
			# comment here in case we need to revisit using the above alternative
			set cmd="spack load --first $mod"
			if ( $?loginsh ) echo $cmd
			eval $cmd
			#spack load $mod
			set _lmod_loc=`spack location -i $mod`
			source ${_lmod_loc}/lmod/lmod/init/cshrc
			module unuse ${SPACK_ROOT}/share/spack/modules/${spackarch} ${SPACK_ROOT}/share/spack/modules/${spackgenarch}
			module use ${SPACK_ROOT}/share/spack/lmod/${spackgenarch}/Core
		else
			
			# Any modules other than lmod should be loaded with "module load"
			set cmd="module load $mod"
			if ( $?loginsh ) echo $cmd
			eval $cmd

		endif

	end

	#set cmd="source modules_setup.csh"
	#echo $cmd
	#$cmd

	# Optionally load the specified compiler
	#if ( $# >= 3 ) then
	#	set cmd="module load $3"
	#	echo $cmd
	#	$cmd
	#endif
else
	echo "No file: $setupfile"
	echo "No spack config for os/release: ${os}/${ver}"
endif

