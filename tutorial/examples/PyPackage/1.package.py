# Copyright Spack Project Developers. See COPYRIGHT file for details.
#
# SPDX-License-Identifier: (Apache-2.0 OR MIT)

from spack.package import *
from spack_repo.builtin.build_systems.python import PythonPackage


class PyRequests(PythonPackage):
    """Python HTTP for Humans."""

    homepage = "https://requests.readthedocs.io"
    pypi = "requests/requests-2.32.3.tar.gz"

    version("2.32.3", sha256="55365417734eb18255590a9ff9eb97e9e1da868d4ccd6402399eaf68af20a760")

    depends_on("py-setuptools", type="build")

    depends_on("py-charset-normalizer", type=("build", "run"))
    depends_on("py-idna", type=("build", "run"))
    depends_on("py-urllib3", type=("build", "run"))
    depends_on("py-certifi", type=("build", "run"))

