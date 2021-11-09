#!/bin/bash

# This is used to build a local spack sandbox using Docker.
# This is intended for use on a personal laptop/desktop
# so one can build and maintain their own instance of
# spack that is independent of the official one on the JLab CUE.
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
#
# NOTE on Architecture:
# It is best to build this using the native architecture of
# your system. The Apple silicon M1 chip uses an aarch64(=arm64)
# architecture while traditional Intel/AMD chips x86_64(=amd64).
# The naming scheme used for the different architectures differs
# depending on the software package. Docker uses arm64/amd64 while
# Spack uses aarch64/x86_64. A Multi-architecture build of the
# epsci-centos:7.9.2009 image has been placed on dockerhub so if
# you don't specify anything, it should just pull the right one.
# Similarly, Spack should auto-detect and do the right thing.
# Here, we force the specification by running "uname -m" and
# cohersing the results.
#
# NOTE on Apple Filesystems
# The default filesystem on macos is case-insensitive. This is
# not obvious until you try dealing with two files of the same
# name differing only by case. If using this to build on a Mac,
# do yourself a favor and create a disk image using Disk Utility
# and format it with a case-sensitive filesystem. Them mount it
# and point MYDIR there.

MYDIR=/Volumes/MySPACK
#MYDIR=/Users/davidl/work/2021.11.03.spack

spack_os=centos
spack_ver=7.9.2009
spack_compiler=9.3.0
spack_build_threads=8

spack_top=/cvmfs/oasis.opensciencegrid.org/jlab/epsci/${spack_os}/${spack_ver}

spack_arch=`uname -m`
docker_arch='unknown'
if [ $spack_arch == 'arm64' ] ; then
	spack_arch='aarch64'
	docker_arch='arm64'
fi
if [ $spack_arch == 'amd64' ] || [ $spack_arch == 'x86_64' ] ; then
	spack_arch='x86_64'
	docker_arch='amd64'
fi

echo "mkdir -p ${MYDIR}/cvmfs"
mkdir -p ${MYDIR}/cvmfs
echo "mkdir -p ${MYDIR}/scratch"
mkdir -p ${MYDIR}/scratch
echo "mkdir -p ${MYDIR}/root_home"
mkdir -p ${MYDIR}/root_home


docker run -it --platform=linux/${docker_arch} \
	-v ${MYDIR}/cvmfs:/cvmfs \
	-v ${MYDIR}/scratch:/scratch \
	-v ${MYDIR}/root_home:/root \
	-v ${PWD}:/work \
	-w /work \
	jeffersonlab/epsci-${spack_os}:${spack_ver} \
	/work/mnp.sh $spack_os $spack_ver $spack_compiler $spack_build_threads $spack_arch

