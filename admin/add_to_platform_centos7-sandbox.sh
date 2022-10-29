#!/bin/bash
#
# This script will run the atp.sh script in a singularity container
# corresponding to the specified os/ver/compiler. It takes a single
# argument, the name of the file containing spack specifications to
# install. It should be run like this.
#
# e.g.
#
#   ./add_to_platform_centos7-sandbox.sh ./jlabce2.4.sh
#
# The heavy lifing is all done in the atp.sh script. See that for
# details.
#

spack_os=centos
spack_ver=7.7.1908
spack_compiler=9.3.0
#spack_compiler=system
spack_build_threads=16
spack_packages_file=$1

source /etc/profile.d/modules.sh
module load singularity
singularity exec \
	-B /scigroup/cvmfs:/cvmfs/oasis.opensciencegrid.org/jlab \
	-B /scigroup:/scigroup \
	/scigroup/spack/mirror/singularity/images/epsci-${spack_os}-${spack_ver}.img \
	./atp.sh $spack_os ${spack_ver}-sandbox $spack_compiler $spack_build_threads $spack_packages_file

