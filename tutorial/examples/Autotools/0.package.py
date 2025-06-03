# Copyright Spack Project Developers. See COPYRIGHT file for details.
#
# SPDX-License-Identifier: (Apache-2.0 OR MIT)

from spack_repo.builtin.build_systems.autotools import AutotoolsPackage
from spack.package import *


class Mpileaks(AutotoolsPackage):
    """Tool to detect and report MPI objects like MPI_Requests and
    MPI_Datatypes."""

    homepage = "https://github.com/LLNL/mpileaks"
    url = "https://github.com/LLNL/mpileaks/releases/download/v1.0/mpileaks-1.0.tar.gz"

    version("1.0", sha256="2e34cc4505556d1c1f085758e26f2f8eea0972db9382f051b2dcfb1d7d9e1825")

    depends_on("mpi")
    depends_on("adept-utils")
    depends_on("callpath")

    def install(self, spec, prefix):
        configure("--prefix=" + prefix,
                  "--with-adept-utils=" + spec['adept-utils'].prefix,
                  "--with-callpath=" + spec['callpath'].prefix)
        make()
        make("install")

