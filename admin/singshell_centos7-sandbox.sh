#!/bin/bash

spack_os=centos
spack_ver=7.7.1908
spack_compiler=9.3.0

spack_top=/cvmfs/oasis.opensciencegrid.org/jlab/epsci/${spack_os}/${spack_ver}-sandbox
echo "source ${spack_top}/share/spack/setup-env.sh"


source /etc/profile.d/modules.sh
module load singularity
singularity shell \
	-B /scigroup/cvmfs:/cvmfs/oasis.opensciencegrid.org/jlab \
	-B /scigroup:/scigroup \
	/scigroup/spack/mirror/singularity/images/epsci-${spack_os}-${spack_ver}.img 

