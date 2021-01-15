#!/bin/bash
#
# This script is used to setup a singularity container and then run
# the mnp.sh script in it. The heavy lifing is done in mnp.sh.
#
# Here you can specify a compiler version that will be needed. The
# compiler should be specified here so it can be built by the
# mnp.sh script if necessary.
#
# If you wish to use the default system compiler that already exists
# in the container then set spack_compiler to "system".
#
# NOTE: It is safe to run this for a spack platform that already exists.
# It is non-destructive and will not rebuild anything that is already
# built.
#

spack_os=centos
spack_ver=8.3.2011
#spack_compiler=9.3.0
spack_compiler=system
spack_build_threads=16

source /etc/profile.d/modules.sh
module load singularity
singularity exec \
	-B /scigroup/cvmfs:/cvmfs/oasis.opensciencegrid.org/jlab \
	-B /scigroup:/scigroup \
	/scigroup/spack/mirror/singularity/images/epsci-${spack_os}-${spack_ver}.img \
	./mnp.sh $spack_os $spack_ver $spack_compiler $spack_build_threads

