#!/bin/bash

spack_os=centos
spack_ver=7.9.2009
spack_compiler=9.3.0
spack_build_threads=32

source /etc/profile.d/modules.sh
module load singularity
singularity exec \
	-B /scigroup/cvmfs:/cvmfs/oasis.opensciencegrid.org/jlab \
	-B /scigroup:/scigroup \
	/scigroup/spack/mirror/singularity/images/epsci-${spack_os}-${spack_ver}.img \
	./mnp.sh $spack_os $spack_ver $spack_compiler $spack_build_threads

