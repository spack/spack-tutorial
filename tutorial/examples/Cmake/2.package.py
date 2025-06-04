# Copyright Spack Project Developers. See COPYRIGHT file for details.
#
# SPDX-License-Identifier: (Apache-2.0 OR MIT)

from spack.package import *
from spack_repo.builtin.build_systems.cmake import CMakePackage


class Callpath(CMakePackage):
    """Library for representing callpaths consistently in
    distributed-memory performance tools."""

    homepage = "https://github.com/llnl/callpath"
    url = "https://github.com/llnl/callpath/archive/v1.0.3.tar.gz"

    version(
        "1.0.3",
        sha256="a7ddba34de8387a8cb2af9c46bf24e5d307fb196e6dd433707641219c8b4af3e",
    )

    depends_on("cxx", type="build")
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
            args.append(f"-DCMAKE_CXX_FLAGS='{std_flag}' -fpermissive'")

        return args
