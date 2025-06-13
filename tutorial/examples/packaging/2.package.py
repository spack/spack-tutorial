# Copyright 2013-2024 Lawrence Livermore National Security, LLC and other
# Spack Project Developers. See the top-level COPYRIGHT file for details.
#
# SPDX-License-Identifier: (Apache-2.0 OR MIT)

from spack.package import *


class TutorialMpileaks(AutotoolsPackage):
    """Tool to detect and report MPI objects like MPI_Requests and MPI_Datatypes."""

    homepage = "https://github.com/LLNL/mpileaks"
    url = "https://github.com/LLNL/mpileaks/archive/refs/tags/v1.0.tar.gz"

    maintainers("adamjstewart")

    license("BSD", checked_by="adamjstewart")

    version("1.0", sha256="24c706591bdcd84541e19389a9314813ce848035ee877e213d528b184f4b43f9")

    depends_on("c", type="build")
    depends_on("cxx", type="build")
    depends_on("fortran", type="build")

    depends_on("autoconf", type="build")
    depends_on("automake", type="build")
    depends_on("libtool", type="build")
    depends_on("m4", type="build")

    depends_on("mpi")
    depends_on("adept-utils")
    depends_on("callpath")

    def autoreconf(self, spec, prefix):
        # FIXME: Modify the autoreconf method as necessary
        autoreconf("--install", "--verbose", "--force")

    def configure_args(self):
        # FIXME: Add arguments other than --prefix
        # FIXME: If not needed delete this function
        args = []
        return args
