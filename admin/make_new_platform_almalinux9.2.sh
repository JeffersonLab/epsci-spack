#!/bin/bash

spack_os=almalinux
spack_ver=9.2-20230718
spack_compiler=system
spack_build_threads=32

apptainer exec \
	-B /scigroup/cvmfs:/cvmfs/oasis.opensciencegrid.org/jlab \
	-B /scigroup:/scigroup \
	-B /u/scigroup:/u/scigroup \
	/scigroup/spack/mirror/singularity/images/epsci-${spack_os}-${spack_ver}.img \
	${PWD}/mnp.sh $spack_os $spack_ver $spack_compiler $spack_build_threads

