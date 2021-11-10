#!/bin/bash
#
# This is used to create a docker container that uses a sandbox
# installation of spack specified by the directory MYDIR below.
# The container starts up an interactive bash shell within the
# container as "root". It should automatically set up the SPACK
# environment.
#
# This should work with any architecture (aarch64 or x86_64).
#

MYDIR=/Volumes/MySPACK
#MYDIR=/Users/davidl/work/2021.11.03.spack/arm64

spack_os=centos
spack_ver=7.9.2009
spack_compiler=9.3.0

spack_top=/cvmfs/oasis.opensciencegrid.org/jlab/epsci/${spack_os}/${spack_ver}
echo "source ${spack_top}/share/spack/setup-env.sh"

# If no .bashrc file exists in the directory being mounted as
# /root then go ahead and create one that sets up the spack
# environment so the user doesn't have to do it manually.
if [ ! -f ${MYDIR}/root_home/.bashrc ] ; then
	echo "Adding .${MYDIR}/root_home/.bashrc ... "
	echo "export SPACK_ROOT=${spack_top}" > ${MYDIR}/root_home/.bashrc
	echo "source ${spack_top}/share/spack/setup-env.sh" >> ${MYDIR}/root_home/.bashrc
fi

docker run -it --rm --platform=linux/arm64 \
	-v ${MYDIR}/cvmfs:/cvmfs \
	-v ${MYDIR}/scratch:/scratch \
	-v ${MYDIR}/root_home:/root \
	-v ${PWD}:/work \
	-w /work \
	jeffersonlab/epsci-${spack_os}:${spack_ver} \
	/bin/bash

