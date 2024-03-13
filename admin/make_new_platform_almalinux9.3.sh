#!/bin/bash

spack_os=almalinux
spack_ver=9.3
spack_compiler=system
spack_build_threads=32

mkdir -p /scratch/${USER}/tmp

#	-B /scigroup/cvmfs:/cvmfs/oasis.opensciencegrid.org/jlab \

apptainer exec \
   -B /work/epsci/davidl/2024.03.12.spack/tmpbuild:/cvmfs/oasis.opensciencegrid.org/jlab \
	-B /scigroup:/scigroup \
	-B /u/scigroup:/u/scigroup \
	-B /work/epsci/davidl/2024.03.12.spack/tmp:/tmp \
	/scigroup/cvmfs/epsci/spack/images/epsci-${spack_os}-${spack_ver}.img \
	${PWD}/mnp.sh $spack_os $spack_ver $spack_compiler $spack_build_threads

