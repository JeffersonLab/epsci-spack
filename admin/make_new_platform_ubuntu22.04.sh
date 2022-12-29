#!/bin/bash

spack_os=ubuntu
spack_ver=22.04
spack_compiler=system
spack_build_threads=32

source /etc/profile.d/modules.sh
module load singularity
singularity exec \
	-B /scigroup/cvmfs:/cvmfs/oasis.opensciencegrid.org/jlab \
	-B /scigroup:/scigroup \
	/scigroup/spack/mirror/singularity/images/epsci-${spack_os}-${spack_ver}.img \
	./mnp.sh $spack_os $spack_ver $spack_compiler $spack_build_threads

