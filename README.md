# <img src="https://cdn.rawgit.com/spack/spack/develop/share/spack/logo/spack-logo.svg" width="64" valign="middle" alt="Spack"/> Spack Tutorial

[![Read the Docs](https://readthedocs.org/projects/spack-tutorial/badge/?version=latest)](https://spack-tutorial.readthedocs.io)

Spack is a multi-platform package manager that builds and installs multiple versions and configurations of software. It works on Linux, macOS, and many supercomputers. Spack is non-destructive: installing a new version of a package does not break existing installations, so many configurations of the same package can coexist.

This repository houses Spack's [**hands-on tutorial**](https://spack-tutorial.readthedocs.io/en/latest/), which is a subset of Spack's [**full documentation**](https://spack.readthedocs.io/) (or you can run `spack help` or `spack help --all`).

This tutorial covers basic to advanced usage, packaging, developer features, and large HPC deployments.  You can do all of the exercises on your own laptop using a Docker container. Feel free to use these materials to teach users at your organization about Spack.

Updating the tutorial
---------------------------------
1. `git filter-branch` instructions TBD.
2. Tagging instructions TBD.
3. Upload screen shot of first slide (244px wide, .png) to [images directory](https://github.com/spack/spack-tutorial/tree/master/lib/spack/docs/tutorial/images) following existing file-naming convention.
4. Upload PDF of slide deck to [slides directory](https://github.com/spack/spack-tutorial/tree/master/lib/spack/docs/tutorial/slides) following existing file-naming convention.
5. Update [index.rst](https://github.com/spack/spack-tutorial/blob/master/lib/spack/docs/index.rst) with event name and date; full citation; and file paths for image and PDF.

License
----------------

Spack is distributed under the terms of both the MIT license and the Apache License (Version 2.0). Users may choose either license, at their option.

All new contributions must be made under both the MIT and Apache-2.0 licenses.

See [LICENSE-MIT](https://github.com/spack/spack/blob/develop/LICENSE-MIT),
[LICENSE-APACHE](https://github.com/spack/spack/blob/develop/LICENSE-APACHE),
[COPYRIGHT](https://github.com/spack/spack/blob/develop/COPYRIGHT), and
[NOTICE](https://github.com/spack/spack/blob/develop/NOTICE) for details.

SPDX-License-Identifier: (Apache-2.0 OR MIT)

LLNL-CODE-647188
