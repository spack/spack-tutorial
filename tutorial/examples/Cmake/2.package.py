# Copyright 2013-2023 Lawrence Livermore National Security, LLC and other
# Spack Project Developers. See the top-level COPYRIGHT file for details.
#
# SPDX-License-Identifier: (Apache-2.0 OR MIT)

from spack import *


class Callpath(CMakePackage):
    """Library for representing callpaths consistently in
       distributed-memory performance tools."""

    homepage = "https://github.com/llnl/callpath"
    url      = "https://github.com/llnl/callpath/archive/v1.0.3.tar.gz"

    version('1.0.3', 'c89089b3f1c1ba47b09b8508a574294a')

    depends_on("elf", type="link")
    depends_on("libdwarf")
    depends_on("dyninst")
    depends_on("adept-utils")
    depends_on("mpi")
    depends_on("cmake@2.8:", type="build")

    def cmake_args(self):
        args = ["-DCALLPATH_WALKER=dyninst"]

        if self.spec.satisfies("^dyninst@9.3.0:"):
            std_flag = self.compiler.cxx_flag
            args.append("-DCMAKE_CXX_FLAGS='{0}' -fpermissive'".format(
                std_flag))

        return args
