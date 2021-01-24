#!/bin/tcsh -f

spack load lmod
source `spack location -i lmod`/lmod/lmod/init/cshrc
set spackarch=`spack arch`
set spackgenarch=`spack arch -p`-`spack arch -o`-x86_64
module unuse ${SPACK_ROOT}/share/spack/modules/${spackarch}
module unuse ${SPACK_ROOT}/share/spack/modules/${spackgenarch}
module use ${SPACK_ROOT}/share/spack/lmod/${spackgenarch}/Core

