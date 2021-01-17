# 
# ----------------------------------------------------------------------------
# 

from spack import *
import os
import shutil


class Ccdb(SConsPackage):
    """Calibration and Conditions DataBase"""

    homepage = "https://github.com/JeffersonLab/ccdb"
    url      = "https://github.com/JeffersonLab/ccdb/archive/v1.06.07.tar.gz"

    # List of GitHub accounts to notify when the package is updated.
    maintainers = ['faustus123']

    #version('2.00-test', sha256='0e3288278ebeee909b4e04e3f2335dbb6bdf4a93f563746fa2c39b5dbda5633a')
    version('1.06.07',   sha256='0f3a9f071dffbade23a36179c58393143edb6f94426f862234c2dfab951b0840')
    version('1.06.06',   sha256='94dfd5d28b3ea7178414fb58ce10d2a3907a0ff6b263767dd73f3534615db270')
    version('1.06.05',   sha256='d16446d8f5b34b2e5ad4f14be4a96daf4f13ae248680eeeb198b065ebf1daea5')
    version('1.06.04',   sha256='b60bf1e277bdb718f6d6f4c8d077f50c8e9d5db9c6dfe6fb7216ff2086eb20ca')
    version('1.06.03',   sha256='3a54545ccf4ec615cc8214263d89ceda16aca73fa4720a8f632fbd78fd1c4ab0')
    version('1.06.02',   sha256='7b495864258e561769c7243f998f540035bad7b9ba93f79eb95c69684801f426')
    version('1.06.01',   sha256='e72f3f1a3922ecc8bc8653c4929b558adb53deee2267ae41522615419678df65')

    # Dependencies
    depends_on('mysql')

    def build_args(self, spec, prefix):
        args = []
        return args

    # CCDB does not implement an "install" target so we override the
    # install phase here and copy the bin and lib directories manually
    def install(self, spec, prefix):
        print('spec: ' + str(spec))
        print('prefix: ' + str(prefix))
        shutil.copytree('bin', os.path.join(prefix,'bin'))
        shutil.copytree('lib', os.path.join(prefix,'lib'))

