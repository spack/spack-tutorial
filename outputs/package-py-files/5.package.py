# Copyright 2013-2024 Lawrence Livermore National Security, LLC and other
# Spack Project Developers. See the top-level COPYRIGHT file for details.
#
# SPDX-License-Identifier: (Apache-2.0 OR MIT)

from spack.package import *


class TutorialMpileaks(AutotoolsPackage):
    """Tool to detect and report MPI objects like MPI_Requests and MPI_Datatypes."""

    homepage = "https://github.com/LLNL/mpileaks"
    url = "https://github.com/LLNL/mpileaks/archive/refs/tags/v1.0.tar.gz"

    maintainers("alecbcs")

    sanity_check_is_dir = ["bin", "lib", "shar"]

    license("BSD", checked_by="alecbcs")

    version("1.0", sha256="24c706591bdcd84541e19389a9314813ce848035ee877e213d528b184f4b43f9")

    variant(
        "stackstart",
        values=int,
        default=0,
        description="Specify the number of stack frames to truncate",
    )

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
        autoreconf("--install", "--verbose", "--force")

    def configure_args(self):
        args = [
            f"--with-adept-utils={self.spec['adept-utils'].prefix}",
            f"--with-callpath={self.spec['callpath'].prefix}",
        ]

        stackstart = int(self.spec.variants["stackstart"].value)
        if stackstart:
            args.extend(
                [
                    f"--with-stack-start-c={stackstart}",
                    f"--with-stack-start-fortran={stackstart}",
                ]
            )

        return args
