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

The Spack tutorial container is automatically built from [repository](docker/Dockerfile) by [this GitHub action](.github/workflows/containers.yaml). The latest version is available at

```
ghcr.io/spack/tutorial:latest
```

and is rebuilt on a schedule. It can also be [triggered manually](https://github.com/spack/spack-tutorial/actions).

The tutorial image builds on top of the container image that runs in Spack CI, which is built in a different repository at [spack/gitlab-runners](https://github.com/spack/gitlab-runners/)

## Automatically generating command ouputs

The tutorial `rst` files include output from Spack commands. This process is automated, and it is
recommended not to run commands manually.

**Note:** as a preliminary step, check your terminal width. All current outputs
are generated on a fixed terminal width **94**; deviating from that can cause
unnecessarily large diffs:

```console
$ tput cols
94
```

To regenerate the outputs, run:

```shell
make -C outputs -j <N>
```

This runs each `outputs/<section>.sh` script in parallel in a container, and collects outputs in
`outputs/raw/*`. When all complete succesfully, the outputs are post-processed and put in
`outputs/`.

In case you want to restrict to particular sections, or if you need to modify the container
executable and flags, specify those as variables in `outputs/Make.user`:

```makefile
sections := basics scripting
DOCKER := sudo docker
```

- `make` will regenerate the relevant outputs when `outputs/<section>.sh` files are modified.

- To start from scratch, run `make clean`

- `make run-<tab>` can also be used to regenerate a particular section, but notice it will only
  create raw outputs.

## License

Spack is distributed under the terms of both the MIT license and the Apache License (Version 2.0). Users may choose either license, at their option.

All new contributions must be made under both the MIT and Apache-2.0 licenses.

See [LICENSE-MIT](https://github.com/spack/spack/blob/develop/LICENSE-MIT),
[LICENSE-APACHE](https://github.com/spack/spack/blob/develop/LICENSE-APACHE),
[COPYRIGHT](https://github.com/spack/spack/blob/develop/COPYRIGHT), and
[NOTICE](https://github.com/spack/spack/blob/develop/NOTICE) for details.

SPDX-License-Identifier: (Apache-2.0 OR MIT)

LLNL-CODE-811652
