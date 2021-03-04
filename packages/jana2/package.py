# Copyright 2013-2020 Lawrence Livermore National Security, LLC and other
# Spack Project Developers. See the top-level COPYRIGHT file for details.
#
# SPDX-License-Identifier: (Apache-2.0 OR MIT)

from spack import *


class Jana2(CMakePackage):
    """Multi-threaded HENP Event Reconstruction."""

    homepage = "http://jeffersonlab.github.io/JANA2/"
    url      = "http://github.com/JeffersonLab/JANA2/archive/v2.0.3.tar.gz"
    git      = "http://github.com/JeffersonLab/JANA2.git"

    maintainer = ["davidl"]

    version('2.0.4',       sha256='1352304f49862a54b5089bd823cef1c63fca2e00')
    version('2.0.3',       sha256='fd34c40e2d6660ec08aca9208999dd9c8fe17de21c144ac68b6211070463e415')
    version('2.0.2',       sha256='161d29c2b1efbfb36ec783734b45dff178b0c6bd77a2044d5a8829ba5b389b14')
    version('2.0.1',       sha256='1471cc9c3f396dc242f8bd5b9c8828b68c3c0b72dbd7f0cfb52a95e7e9a8cf31')
    version('2.0.0-alpha', sha256='4a093caad5722e9ccdab3d3f9e2234e0e34ef2f29da4e032873c8e08e51e0680')

    variant('python',
            default=False,
            description='Use python for janapy, etc')

    variant('root',
            default=False,
            description='Use ROOT for janarate.')
    variant('zmq',
            default=False,
            description='Use zeroMQ for janacontrol.')

    depends_on('cmake@3.9:', type='build')
    depends_on('cppzmq', when='+zmq')
    depends_on('root', when='+root')
    depends_on('xerces-c')
    
    # This patches a bug in the cmake/MakeConfig.cmake file
    # for v2.0.3 related to testing the XERCESCROOT envar
    patch('MakeConfig.cmake_xerces.patch', level=1, when='@2.0.3')

    def cmake_args(self):
        args = []

        # Python
        if '+python' in self.spec:
            args.append('-DUSE_PYTHON=ON')

        # ZeroMQ directory
        if '+zmq' in self.spec:
            args.append('-DZEROMQ_DIR=%s'
                        % self.spec['cppzmq'].prefix)
        # C++ Standard
        if '+root' in self.spec:
            args.append('-DCMAKE_CXX_STANDARD=%s'
                        % self.spec['root'].variants['cxxstd'].value)
        else:
            args.append('-DCMAKE_CXX_STANDARD=11')

        return args

    def setup_run_environment(self, env):
        import os
        env.append_path('JANA_PLUGIN_PATH', os.path.join(self.prefix, 'plugins'))
        env.set('JANA_HOME', self.prefix)
