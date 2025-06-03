# Copyright Spack Project Developers. See COPYRIGHT file for details.
#
# SPDX-License-Identifier: (Apache-2.0 OR MIT)

from spack_repo.builtin.build_systems.python import PythonPackage
from spack.package import *


class PyPythonDateutil(PythonPackage):
    """Extensions to the standard Python datetime module."""

    homepage = "https://dateutil.readthedocs.io/"
    pypi = "python-dateutil/python-dateutil-2.9.0.post0.tar.gz"

    version("2.9.0.post0", sha256="37dd54208da7e1cd875388217d5e00ebd4179249f90fb72437e91a35459a0ad3")

    depends_on("py-setuptools", type="build")
    depends_on("py-setuptools-scm@:7", type="build")
    depends_on("py-wheel", type="build")
    depends_on("py-six", type=("build", "run"))

