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


class Et(Package):
    """Evio (event I/O) is a software package at Jefferson Lab which defines a data format and provides libraries for
       handling data in this format. It's used by the CODA (CEBAF Online Data Acquistion) software
       and traditionally the DAQ group. """
    
    homepage = "https://coda.jlab.org"
    git      = "https://github.com/JeffersonLab/et.git"
    
    
    # List of GitHub accounts to notify when the package is updated
    maintainers = ['carltimmer']
        
        
    # Versions and hash here
    version('16.4', branch = 'master')
    
    # Turn installation into $CODA on and off
    variant('install', default=True, description='Installation into $CODA')
    # Turn compilation debug flags on and off
    variant('debug', default=False, description='Turn on debug flag')
    
    
    # Need at least cmake 3.3 (perhaps higher?)
    depends_on('cmake@3.3:', type=('build', 'link'))
    
    
    def install(self, spec, prefix):
        print ("Build and install evio libraries into " + prefix.lib)
         
        mkdirp('./build')
        cd('./build')
        
        if '+debug' in spec:
            cmake("..", '-DCMAKE_BUILD_TYPE=Debug')
        else:
            cmake("..", '-DCMAKE_BUILD_TYPE=Release')
            
            
        if '+install' in spec:
           print ("Also install evio libraries into $CODA")
           make('install')
        else:
            make()
        
        # Copy libraries from where make puts them to where spack expects them
        mkdirp(prefix.lib)
        install('./lib/libet*', prefix.lib)
        
        # Copy include files from where make puts them to where spack expects them
        mkdirp(prefix.include)
        for f in glob.glob('../src/libsrc/*.h'):
            install(f, prefix.include)

