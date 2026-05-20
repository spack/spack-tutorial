.. Copyright Spack Project Developers. See COPYRIGHT file for details.

   SPDX-License-Identifier: (Apache-2.0 OR MIT)

.. include:: common/setup.rst

.. _binary-cache-tutorial:

==================================
Binary Caches Tutorial
==================================

This section covers how to share Spack-built binaries across machines and users using **build caches**.

Spack supports a range of storage backends for build caches: an ordinary filesystem, Amazon S3, Google Cloud Storage, and any OCI-compatible container registry (Docker Hub, GitHub Packages, a local ``docker registry``, and so on).
We begin with a filesystem mirror that has been pre-populated for the workshop, and then move on to OCI registries, which carry the additional property that the same artifacts can be used as runnable container images.

-------------------------
Cloning Spack
-------------------------

Because the workshop image is minimal, we start by cloning Spack into the container:

.. code-block:: console

   $ git clone --depth=1 https://github.com/spack/spack ~/spack
   $ . ~/spack/share/spack/setup-env.sh
   $ spack --version
   1.2.0.dev0 (...)

-------------------------------------------
A filesystem build cache: ``/buildcache``
-------------------------------------------

We use ``quantum-espresso`` together with ``py-numpy`` as the running example.
Between them they pull in a representative slice of an HPC stack (``openmpi``, ``openblas``, ``netlib-scalapack``, ``fftw``, ``python``) together with a Python package.

Create an environment directory and write a ``spack.yaml`` into it:

.. code-block:: console

   $ mkdir ~/myenv && cd ~/myenv
   $ cat > spack.yaml <<'EOF'
   spack:
     specs:
     - quantum-espresso
     - py-numpy
     view: view
     concretizer:
       unify: true
     packages:
       c:
         prefer: [gcc@15]
       cxx:
         prefer: [gcc@15]
       fortran:
         prefer: [gcc@15]
   EOF

Two things in this manifest are worth noting.

The ``mirrors`` section adds ``/buildcache`` as an *unsigned* mirror.
This is acceptable for a workshop cache; production caches should normally use GPG-signed binaries.

The ``packages:{c,cxx,fortran}:prefer`` keys steer the concretizer toward specs that already exist in the cache, so that the concretization is fully reusable rather than a partial source build.

.. note::

   The terms *mirror* and *build cache* are used almost interchangeably, since every build cache is a binary mirror.
   Source mirrors also exist but are not covered in this tutorial.

Install the environment:

.. code-block:: console

   $ spack -e . install
   ...
   [+] 6t26kli py-numpy@2.4.4 ... (1s)
   [+] zia4bn3 quantum-espresso@7.5 ... (7s)

Both packages, and every transitive dependency, are fetched and relocated from ``/buildcache``; nothing is built from source.
Given a build cache, the concretizer prefers concrete specs for which binaries already exist.

Confirm that the executables work through the environment's view:

.. code-block:: console

   $ ./view/bin/pw.x
        Program PWSCF v.7.5 starts on 15May2026 at 11:04:10
        ...
   $ ./view/bin/python3 -c 'import numpy; print(numpy.__version__)'
   2.4.4

.. note::

   Since Spack 0.22, build caches can be used across different Linux distributions.
   The concretizer reuses specs that have a host-compatible ``libc`` (e.g. ``glibc`` or ``musl``), and binaries built with ``gcc`` carry their compiler runtime libraries as a separate dependency, so users do not need to install a compiler first.

-------------------------------------------------
Setting up a local OCI build cache
-------------------------------------------------

The previous section consumed binaries from a build cache.
This section covers publishing binaries to one, using an **OCI container registry** as the backend.

OCI registries are useful in this role because the same artifacts can serve both as a Spack build cache and as runnable container images.
OCI registries in common use include Docker Hub, GitHub Container Registry (GHCR), and Amazon ECR.
For this tutorial we run a registry locally in a separate Docker container, which avoids authentication.

In another terminal *on the host*, start the registry:

.. code-block:: console

   $ docker run -d --rm -p 5000:5000 --name registry registry

This is the official `registry image <https://hub.docker.com/_/registry>`_ from Docker Hub.
It serves an empty OCI registry on ``http://localhost:5000``.

Inside the tutorial container, which was started with ``--network host``, the registry is reachable on the same port.
Add it as a second mirror:

.. code-block:: console

   $ spack -e . mirror add --unsigned my-registry oci+http://localhost:5000/buildcache

The URL has three parts:

* ``oci+http://``: an OCI registry over plain HTTP, without TLS.
  A remote registry would normally use ``oci://`` (HTTPS).
* ``localhost:5000``: the registry's host and port.
* ``/buildcache``: the image name under which Spack publishes all artifacts.

The manifest now contains two mirrors:

.. code-block:: yaml

   mirrors:
     tutorial:
       url: /buildcache
       signed: false
     my-registry:
       url: oci+http://localhost:5000/buildcache
       signed: false

-------------------------------------
Pushing to the OCI build cache
-------------------------------------

Push the environment to the local registry:

.. code-block:: console

   $ spack -e . buildcache push --without-build-dependencies my-registry
   ==> Selected 38 specs to push to oci+http://localhost:5000/buildcache
   ==> Checking for existing specs in the buildcache
   ...
   ==> [37/38] Tagged py-numpy@2.4.4/6t26kli as localhost:5000/buildcache:py-numpy-2.4.4-6t26kli6wzzkm6jjfll6pjhtdfimsb7e.spack
   ==> [38/38] Tagged quantum-espresso@7.5/zia4bn3 as localhost:5000/buildcache:quantum-espresso-7.5-zia4bn3lvraagxfnu77ysgewykavwnsc.spack

Two things about this invocation are worth noting.

The ``--without-build-dependencies`` flag is passed because Quantum ESPRESSO was installed from a binary cache, so build-only dependencies like ``cmake`` or ``bison`` are not present on this machine.
Without the flag, Spack would report that those packages are not installed.

Each spec receives its own image tag of the form ``<image>:<name>-<version>-<hash>.spack``.
The package hash makes the tag unique, which is the property required for content-addressed binary distribution.

Re-running the push detects that nothing needs to be uploaded:

.. code-block:: console

   $ spack -e . buildcache push --without-build-dependencies my-registry
   ==> Selected 38 specs to push to oci+http://localhost:5000/buildcache
   ==> Checking for existing specs in the buildcache
   ==> All specs are already in the buildcache. Use --force to overwrite them.

-------------------------------------------
Reinstalling from the OCI build cache
-------------------------------------------

To confirm that the OCI mirror functions as a build cache, reinstall ``quantum-espresso`` with ``--overwrite``:

.. code-block:: console

   $ spack -e . install --overwrite -y quantum-espresso
   ==> Fetching https://... blobs/sha256:...
   [ ] zia4bn3 quantum-espresso@7.5 fetching from build cache (0s)
   [ ] zia4bn3 quantum-espresso@7.5 relocating (1s)
   [+] zia4bn3 quantum-espresso@7.5 ... (7s)

Two blobs are fetched per spec: a JSON manifest and the binary tarball.
OCI registries are content-addressed, hence the ``sha256:...`` identifiers rather than human-readable filenames.

----------------------------------
Creating runnable container images
----------------------------------

So far the OCI registry has been used only as a Spack build cache.
Since the artifacts are also valid OCI images, they can be pulled directly with ``docker``.

Consider what happens when running an image without a base image:

.. code-block:: console

   $ docker run --rm localhost:5000/buildcache:quantum-espresso-7.5-zia4bn3lvraagxfnu77ysgewykavwnsc.spack pw.x
   exec /root/spack/opt/spack/linux-x86_64_v3/quantum-espresso-7.5-.../bin/pw.x: no such file or directory

The run fails because the layers we pushed contain the Spack-built artifacts but not the host's ``glibc``, which Spack always treats as an external package.
Without a base image the container has no ``/lib`` directory at all, which produces the error above.

The resolution is to push again with ``--base-image`` pointing at a minimal distribution that provides a compatible ``glibc``:

.. code-block:: console

   $ spack -e . buildcache push --force --without-build-dependencies \
         --base-image ubuntu:26.04 my-registry

The base image's ``libc`` must be at least as new as the one used at build time, otherwise the binaries fail at runtime with errors of the form ``version `GLIBC_2.43' not found``.
The distribution itself need not match.
``archlinux:latest``, for example, ships a sufficiently recent ``glibc`` while providing a different userland (``pacman`` instead of ``apt``, and so on).

The image now runs:

.. code-block:: console

   $ docker run --rm localhost:5000/buildcache:quantum-espresso-7.5-zia4bn3lvraagxfnu77ysgewykavwnsc.spack pw.x

        Program PWSCF v.7.5 starts on 15May2026 at 11:09:19

        This program is part of the open-source Quantum ESPRESSO suite
        ...

In addition to ``glibc``, the base image provides a shell and the standard utilities.

--------------------------------------
Spack environments as container images
--------------------------------------

The preceding section produced one image per package.
For most uses a single image containing the full environment is more convenient.

Pass ``--tag`` to assign the environment image a human-readable name:

.. code-block:: console

   $ spack -e . buildcache push --without-build-dependencies \
         --base-image ubuntu:26.04 \
         --tag qe-and-numpy \
         my-registry
   ...
   ==> Tagged localhost:5000/buildcache:qe-and-numpy

Spack publishes each package as its own image layer.
Layers are shared between image tags, so the combined image takes almost no extra storage.
Unlike Docker, where each ``RUN`` line creates a layer that depends on the previous one, Spack package layers are independent and can be combined in any order.

Pulling and running the combined image:

.. code-block:: console

   $ docker run --rm localhost:5000/buildcache:qe-and-numpy bash -c \
       'pw.x 2>&1 | head -3; python3 -c "import numpy; print(\"numpy\", numpy.__version__)"'

        Program PWSCF v.7.5 starts on 15May2026 at 11:19:11

        This program is part of the open-source Quantum ESPRESSO suite
   numpy 2.4.4

Both Quantum ESPRESSO and NumPy are immediately usable because Spack writes ``PATH`` and ``PYTHONPATH`` into the image's environment, pointing at each package's install prefix.
Spack does not materialize the environment's view inside the image; the packages live at their original Spack prefixes, identical to those on the host.

----------------------------------------
Relation to ``docker build`` workflows
----------------------------------------

In earlier versions of Spack the common practice was to generate a ``Dockerfile`` from a Spack environment using ``spack containerize`` and then build the image with ``docker build``:

.. code-block:: Dockerfile

   FROM <base image> AS build
   COPY spack.yaml /root/env/spack.yaml
   RUN spack -e /root/env install

   FROM <base image>
   COPY --from=build /opt/spack/opt /opt/spack/opt

This approach still works and ``spack containerize`` is still available, but it has several drawbacks:

* If ``RUN spack -e /root/env install`` fails, Docker discards the whole layer, including any successfully built dependencies.
  Troubleshooting typically requires starting from scratch in a ``docker run`` session.
* Some CI environments cannot run ``docker build`` safely — for example, when the CI script itself runs inside a container ("Docker-in-Docker").

The OCI build cache approach decouples the three responsibilities that ``docker build`` combines: build isolation, running the build, and producing an image.
``spack install`` can be run in any environment (host, sandbox, container), and ``spack buildcache push`` then turns the result into images.

----------
Relocation
----------

Spack installs packages under an arbitrary prefix, typically ``~/spack/opt/spack/...``.
This is more flexible than most package managers, but it also means that binaries contain absolute paths to machine-specific locations, which must be rewritten when the binary is reinstalled elsewhere.

Spack does this rewriting automatically when installing from a binary cache.
When producing binaries that are meant to be redistributed, one constraint applies: Spack can only relocate paths in a binary if the target prefix is no longer than the prefix used at build time.

The reason is that absolute paths typically reside in the binary's string table — a list of null-terminated strings referenced by offset.
Strings can be edited in place, but they cannot grow without overwriting their neighbors.

To maximize the likelihood of successful relocation, build in a relatively long path.
Spack can pad install prefixes automatically:

.. code-block:: console

   $ spack -e . config add config:install_tree:padded_length:256

------------------------
Using build caches in CI
------------------------

Build caches also speed up CI pipelines.
Both GitHub Actions and GitLab CI support container registries, so the workflow described above applies directly in CI.

Spack provides a GitHub Action that configures a shared build cache:

.. code-block:: yaml

   jobs:
     build:
       runs-on: ubuntu-latest
       steps:
       - name: Set up Spack
         uses: spack/setup-spack@v2
       - run: spack install python  # uses a shared build cache

See the `setup-spack readme <https://github.com/spack/setup-spack>`_ for instructions on caching additional binaries that are not in the shared build cache.

-------
Summary
-------

This tutorial covered:

* consuming a pre-populated filesystem build cache at ``/buildcache`` to install Quantum ESPRESSO and NumPy without any source builds;
* setting up a local OCI registry as a second build cache and pushing the environment to it;
* reinstalling from the OCI cache to confirm that it functions as a regular Spack mirror;
* using the same OCI artifacts as runnable container images, both per-package and as a combined environment with ``--tag``.
