#!/bin/sh
#
# This should be run from inside a singularity container
# which already has spack setup in the environment (e.g.
# use singshell_centos7.sh).
#
# This will attempt to create a buildcache tarball for every
# package in the current spack instance. It will then
# rebuild the index.
#
# WARNING: This may take quite a while to complete!
#
# There is no built in mechanism in spack to do this
# for all packages so it must be done one at a time.
# The method here follows a suggestion on a google forum
# here:
#
#   https://groups.google.com/g/spack/c/_ap6R8j0p4k
#  
#

# Loop over all packages (by hash) and create a buildcache
# tarball for them.
BUILDCACHE_MIRROR=/scigroup/spack/mirror
for s in $(spack find --no-groups -L | cut -f 1 -d ' '); do
	echo "creating buildcache for: $s"
	spack buildcache create -d ${BUILDCACHE_MIRROR} -r -a -u --only package "/$s"
	#break
done

# Update the buildcache index used by the mirror
echo " "
echo "Updating buildcache index"
spack buildcache update-index -k -d /scigroup/spack/mirror
