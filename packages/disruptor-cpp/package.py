# Copyright 2013-2020 Lawrence Livermore National Security, LLC and other
# Spack Project Developers. See the top-level COPYRIGHT file for details.
#
# SPDX-License-Identifier: (Apache-2.0 OR MIT)

# ----------------------------------------------------------------------------
# If you submit this package back to Spack as a pull request,
# please first remove this boilerplate and all FIXME comments.
#
# This is a template package file for Spack.  We've put "FIXME"
# next to all the things you'll want to change. Once you've handled
# them, you can save this file and test your package like this:
#
#     spack install disruptor-cpp
#
# You can edit this file again by typing:
#
#     spack edit disruptor-cpp
#
# See the Spack documentation for more information on packaging.
# ----------------------------------------------------------------------------

from spack import *
import glob, subprocess


class DisruptorCpp(Package):
    """The disruptor is an ultra-fast ring buffer which was ported from the original Java v3.3.7.
       It allows multiple reader and writers to shared data in a way which minimizes the use of locks,
       is conceptually simple, and extremely flexible. """
    
    homepage = "https://github.com/JeffersonLab/Disruptor-cpp"
    git      = "https://github.com/JeffersonLab/Disruptor-cpp.git"
    
    
    # List of GitHub accounts to notify when the package is updated
    maintainers = ['carltimmer']
    
    # versions and hash/branch here
    version('master', branch='master')
    
    # turn installation into $CODA on and off
    variant('install', default=True, description='Installation into $CODA')

    # Need at least cmake 2.6 (not sure about this)
    depends_on('cmake@2.6:', type=('build', 'link'))
    
    def build(self, spec, prefix):
        print ("Build Disruptor-cpp libraries into " + prefix.lib)

    
    def install(self, spec, prefix):
        print ("Build and install Disruptor-cpp libraries into " + prefix.lib)
        
        mkdirp('./build')
        cd('./build')
        cmake("..", '-DCMAKE_BUILD_TYPE=release')
        if '+install' in spec:
            make('install')
        else:
            make()
        
        # Copy libraries from where make puts them to where spack expects them
        mkdirp(prefix.lib)
        install('Disruptor/libDisruptor*', prefix.lib)
        
        # Copy include files from where make puts them to where spack expects them
        includeDir = join_path(prefix.include, 'Disruptor')
        mkdirp(includeDir)
        for f in glob.glob('../Disruptor/*.h'):
            install(f, includeDir)
    
    
#    def setup_run_environment(self, env):
#        import os
#        env.set('DISRUPTOR_CPP_HOME', self.prefix)
