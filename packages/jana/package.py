# 
# ----------------------------------------------------------------------------
# 

from spack import *
import os


class Jana(SConsPackage):
    """Multi-threaded HENP Event Reconstruction."""

    homepage = "http://www.jlab.org/JANA"
    url      = "http://github.com/JeffersonLab/JANA/archive/v0.8.2.tar.gz"
    git      = "http://github.com/JeffersonLab/JANA.git"

    maintainer = ["faustus123"]

    version('0.8.2',  sha256='d3db7448254f1b700e305b34e7eaf0e1903d34e92668dd1b1735b5c2b49baf89')
    version('0.8.1b', sha256='6cf98a169a43a388a655385e25826da45980e24aaecb7dc3b19614e7fe771700')
    version('0.8.1',  sha256='9c4f6d42971a6fb61e155c190bfc32e38b23319ea44205bdcf8ab2500bfda286')
    version('0.8.0',  sha256='45708f870e5f0b8fa2ee8dc1c525c9758609845ace3992fe3fefd07a4d9d6459')

    variant('root',
            default=True,
            description='Add ROOT support (for janaroot and janarate plugins)')

    variant('ccdb',
            default=True,
            description='Add CCDB support')

    depends_on('root', when='+root')
    depends_on('ccdb', when='+ccdb')
    depends_on('xerces-c')

    # This patches the scons system to work with scons3 and python3,
    # the latter of which is (likely) required by root.
    patch('JANA_scons_python3.patch', level=1, when='@0.8.2')

    def build_args(self, spec, prefix):
        args = ['PREFIX='+prefix]
        return args

    def build(self, spec, prefix):
        os.environ['BMS_OSNAME'] = 'spack_tmp_os'
        super().build(spec, prefix)

#    def install(self, spec, prefix):
#        # Run install phase as normal
