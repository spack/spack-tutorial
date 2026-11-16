# Copyright Spack Project Developers. See COPYRIGHT file for details.
#
# SPDX-License-Identifier: (Apache-2.0 OR MIT)

from spack_repo.builtin.build_systems.autotools import AutotoolsPackage

from spack.package import *


class TutorialMpileaks(AutotoolsPackage):
    """Tool to detect and report leaked MPI objects like MPI_Requests and MPI_Datatypes."""

    homepage = "https://github.com/llnl/mpileaks"
    url = "https://github.com/llnl/mpileaks/archive/refs/tags/v1.0.tar.gz"

    supplier = "Organization: LLNL"

    maintainers("cmelone")

    license("BSD", checked_by="cmelone")

    version("1.0", sha256="24c706591bdcd84541e19389a9314813ce848035ee877e213d528b184f4b43f9")

    depends_on("c", type="build")
    depends_on("cxx", type="build")
    depends_on("fortran", type="build")

    with default_args(type="build"):
        depends_on("autoconf")
        depends_on("automake")
        depends_on("libtool")
        depends_on("m4")

    depends_on("mpi")
    depends_on("adept-utils")
    depends_on("callpath")

    def autoreconf(self, spec, prefix):
        autoreconf("--install", "--verbose", "--force")

    def configure_args(self):
        args = [
            f"--with-adept-utils={self.spec['adept-utils'].prefix}",
            f"--with-callpath={self.spec['callpath'].prefix}",
        ]

        return args
