# <img src="https://cdn.rawgit.com/spack/spack/develop/share/spack/logo/spack-logo.svg" width="64" valign="middle" alt="Spack"/> Spack Tutorial

[![Read the Docs](https://readthedocs.org/projects/spack-tutorial/badge/?version=latest)](https://spack-tutorial.readthedocs.io)

Spack is a multi-platform package manager that builds and installs multiple versions and configurations of software. It works on Linux, macOS, and many supercomputers. Spack is non-destructive: installing a new version of a package does not break existing installations, so many configurations of the same package can coexist.

This repository houses Spack's [**hands-on tutorial**](https://spack-tutorial.readthedocs.io/en/latest/), which is a subset of Spack's [**full documentation**](https://spack.readthedocs.io/) (or you can run `spack help` or `spack help --all`).

This tutorial covers basic to advanced usage, packaging, developer features, and large HPC deployments.  You can do all of the exercises on your own laptop using a Docker container. Feel free to use these materials to teach users at your organization about Spack.

## Updating the tutorial

1. Create a new branch named for the event/milestone that corresponds to the new version you want to create.
2. Upload screen shot of first slide (244px wide, .png) to [images directory](https://github.com/spack/spack-tutorial/tree/master/tutorial/images) following existing file-naming convention.
3. Upload PDF of slide deck to [slides directory](https://github.com/spack/spack-tutorial/tree/master/_static/slides) following existing file-naming convention.
4. Update [index.rst](https://github.com/spack/spack-tutorial/blob/master/index.rst) with event name and date; full citation; and file paths for image and PDF.
5. Update this README (lines 3 and 7) with link to new version's URL.
6. Build docs locally.
7. Push changes to GitHub and active new tag/version on Read the Docs.
8. Build new version on Read the Docs.

## Updating the tutorial container

The spack tutorial container is built from another [repository](https://github.com/spack/spack-tutorial-container) by an automated process.  For instructions on how to create an updated version of the tutorial container, see these [instructions](https://github.com/spack/spack-tutorial-container/blob/master/UPDATING.md).  For a general description of the automated process used to build the tutorial container, read the [description](https://github.com/spack/spack-tutorial-container/blob/master/DESCRIPTION.md).

## License

Spack is distributed under the terms of both the MIT license and the Apache License (Version 2.0). Users may choose either license, at their option.

All new contributions must be made under both the MIT and Apache-2.0 licenses.

See [LICENSE-MIT](https://github.com/spack/spack/blob/develop/LICENSE-MIT),
[LICENSE-APACHE](https://github.com/spack/spack/blob/develop/LICENSE-APACHE),
[COPYRIGHT](https://github.com/spack/spack/blob/develop/COPYRIGHT), and
[NOTICE](https://github.com/spack/spack/blob/develop/NOTICE) for details.

SPDX-License-Identifier: (Apache-2.0 OR MIT)

LLNL-CODE-647188
