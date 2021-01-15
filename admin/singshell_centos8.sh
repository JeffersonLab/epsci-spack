#!/bin/bash
#
# This is used to launch a shell in a singularity container 
# corresponding to the specified os/ver. It will mount the
# appropriate directories so manual maintenance can be done.

spack_os=centos
spack_ver=8.3.2011


spack_top=/cvmfs/oasis.opensciencegrid.org/jlab/epsci/${spack_os}/${spack_ver}
echo "source ${spack_top}/share/spack/setup-env.sh"


source /etc/profile.d/modules.sh
module load singularity
singularity shell \
	-B /scigroup/cvmfs:/cvmfs/oasis.opensciencegrid.org/jlab \
	-B /scigroup:/scigroup \
	/scigroup/spack/mirror/singularity/images/epsci-${spack_os}-${spack_ver}.img 

