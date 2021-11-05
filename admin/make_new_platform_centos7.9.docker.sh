#!/bin/bash

# This is used to build a local spack sandbox using Docker.
# This is intended for use on a personal laptop/desktop
# so one can build andf maintain their own instance of
# spack that is independent of the one on the JLab CUE.
#
# The top-level MYDIR is a directory on the local disk
# where a "cvmfs" directory will be created and then
# mounted inside the container in the standard /cvmfs
# location. This is to make it writable. The downside is
# that things in the real cvmfs are not accessible.
# A scratch directory will also be created there and
# mounted as /scratch in the container to mimic the
# JLab directory where builds are done.
#
# This should be run from inside the epsci-spack/admin
# directory which will be mounted inside the container
# as /work in order to access some of the other files
# here.
#
# e.g.
#
#  git clone https://github.com/JeffersonLab/epsci-spack
#  cd epsci-spack/admin
#  <edit this file to set MYDIR>
#  ./make_new_platform_centos7.9.docker.sh
#

MYDIR=/Users/davidl/work/2021.11.03.spack

spack_os=centos
spack_ver=7.9.2009
spack_compiler=9.3.0
spack_build_threads=16

echo "mkdir -p ${MYDIR}/cvmfs"
mkdir -p ${MYDIR}/cvmfs
echo "mkdir -p ${MYDIR}/scratch"
mkdir -p ${MYDIR}/scratch

# 	-e SPACK_ROOT=/work/spack \
# 	-v /Users/davidl/JLAB/root/u/scigroup:/scigroup \

docker run -it --platform=linux/amd64 \
	-v ${MYDIR}/cvmfs:/cvmfs \
	-v ${MYDIR}/scratch:/scratch \
	-v ${PWD}:/work \
	-w /work \
	jeffersonlab/epsci-${spack_os}:${spack_ver} \
	/work/mnp.sh $spack_os $spack_ver $spack_compiler $spack_build_threads

