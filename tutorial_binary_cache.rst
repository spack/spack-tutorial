.. Copyright Spack Project Developers. See COPYRIGHT file for details.

   SPDX-License-Identifier: (Apache-2.0 OR MIT)

.. include:: common/setup.rst

.. _binary-cache-tutorial:

==================================
Binary Caches Tutorial
==================================

In this section of the tutorial you will learn how to share Spack-built binaries across machines and users using **build caches**.

Spack supports a range of storage backends for build caches: an ordinary filesystem, Amazon S3, Google Cloud Storage, and any OCI-compatible container registry (Docker Hub, GitHub Packages, a local ``docker registry``, ...).
We will start with a filesystem mirror that has been pre-populated for the workshop, and then move on to OCI registries, which have the additional benefit that the same artifacts can also be used as runnable container images.

.. note::

   For this tutorial we assume you have started the workshop container in interactive mode, e.g.

   .. code-block:: console

      $ docker run -it --network host ghcr.io/haampie/cineca-2026-base

   The image is intentionally minimal: it does *not* contain Spack itself.
   The directory ``/buildcache`` inside the container is a filesystem build cache that has been populated and indexed ahead of time with binaries for the packages used in this tutorial.

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

We will use ``quantum-espresso`` together with ``py-numpy`` as the running example: between them they pull in a representative slice of an HPC stack (``openmpi``, ``openblas``, ``netlib-scalapack``, ``fftw``, ``python``) plus a Python package.

Create an environment directory and drop a ``spack.yaml`` into it:

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
     mirrors:
       local:
         url: /buildcache
         signed: false
     packages:
       c:
         prefer: [gcc@15]
       cxx:
         prefer: [gcc@15]
       fortran:
         prefer: [gcc@15]
   EOF

A few things worth pointing out in this manifest:

* The ``mirrors`` section adds ``/buildcache`` as an *unsigned* mirror.
  For a workshop cache this is fine; for production caches you typically do want GPG-signed binaries.
* The ``packages:{c,cxx,fortran}:prefer`` keys steer the concretizer toward specs that already exist in the cache, so we get a fully reusable solution rather than a partial source build.

.. note::

   We talk about *mirrors* and *build caches* almost interchangeably, because every build cache is a binary mirror.
   Source mirrors exist too, which we will not cover in this tutorial.

Now install:

.. code-block:: console

   $ spack -e . install
   ...
   [+] 6t26kli py-numpy@2.4.4 ... (1s)
   [+] zia4bn3 quantum-espresso@7.5 ... (7s)

Both packages — and every transitive dependency — are fetched and relocated from ``/buildcache``; nothing is built from source.
That is Spack's concretizer doing its job: given a buildcache, it prefers concrete specs for which binaries already exist.

Let's confirm the executables work via the environment's view:

.. code-block:: console

   $ ./view/bin/pw.x
        Program PWSCF v.7.5 starts on 15May2026 at 11:04:10
        ...
   $ ./view/bin/python3 -c 'import numpy; print(numpy.__version__)'
   2.4.4

.. note::

   Since Spack 0.22, build caches can be used across different Linux distributions.
   The concretizer reuses specs that have a host-compatible ``libc`` (e.g. ``glibc`` or ``musl``), and binaries built with ``gcc`` carry their compiler runtime libraries as a separate dependency — so users do not need to install a compiler first.

-------------------------------------------------
Setting up a local OCI build cache
-------------------------------------------------

So far we have *consumed* binaries from a build cache.
Next we will *publish* binaries to one — and we'll use an **OCI container registry** as the backend.

OCI registries are interesting because the *same* artifacts can be used both as a Spack build cache and as runnable container images.
Most people associate OCI with Docker Hub, GitHub Container Registry (GHCR), Amazon ECR, etc., but for this tutorial we will run a registry **locally** in a separate Docker container, so we don't need to deal with authentication.

In another terminal *on the host*, start the registry:

.. code-block:: console

   $ docker run -d --rm -p 5000:5000 --name registry registry

This is the official `registry image <https://hub.docker.com/_/registry>`_ from Docker Hub.
It serves an empty OCI registry on ``http://localhost:5000``.

Inside the tutorial container (which we started with ``--network host``), the registry is reachable on the same port.
Add it as a second mirror:

.. code-block:: console

   $ spack -e . mirror add --unsigned my-registry oci+http://localhost:5000/buildcache

The URL has three parts:

* ``oci+http://`` — an OCI registry over plain HTTP (no TLS).
  For a real remote registry you would use ``oci://`` (HTTPS).
* ``localhost:5000`` — the registry's host and port.
* ``/buildcache`` — the *image name* under which Spack will publish all artifacts.

Your ``spack.yaml`` now has two mirrors:

.. code-block:: yaml

   mirrors:
     local:
       url: /buildcache
       signed: false
     my-registry:
       url: oci+http://localhost:5000/buildcache
       signed: false

-------------------------------------
Pushing to the OCI build cache
-------------------------------------

Let's push the environment to the local registry:

.. code-block:: console

   $ spack -e . buildcache push --without-build-dependencies my-registry
   ==> Selected 38 specs to push to oci+http://localhost:5000/buildcache
   ==> Checking for existing specs in the buildcache
   ...
   ==> [37/38] Tagged py-numpy@2.4.4/6t26kli as localhost:5000/buildcache:py-numpy-2.4.4-6t26kli6wzzkm6jjfll6pjhtdfimsb7e.spack
   ==> [38/38] Tagged quantum-espresso@7.5/zia4bn3 as localhost:5000/buildcache:quantum-espresso-7.5-zia4bn3lvraagxfnu77ysgewykavwnsc.spack

A few things to note:

* We pass ``--without-build-dependencies`` because we installed Quantum ESPRESSO *from a binary cache*, so build-only dependencies like ``cmake`` or ``bison`` are not present on this machine.
  Without the flag, Spack would complain that those packages are not installed.
* Each spec gets its own image tag of the form ``<image>:<name>-<version>-<hash>.spack``.
  The package hash makes the tag unique, which is exactly the property we need for content-addressed binary distribution.

We can re-run the push and Spack will detect that nothing needs to be uploaded:

.. code-block:: console

   $ spack -e . buildcache push --without-build-dependencies my-registry
   ==> Selected 38 specs to push to oci+http://localhost:5000/buildcache
   ==> Checking for existing specs in the buildcache
   ==> All specs are already in the buildcache. Use --force to overwrite them.

-------------------------------------------
Reinstalling from the OCI build cache
-------------------------------------------

To prove that the OCI mirror actually works as a build cache, we can reinstall ``quantum-espresso`` with ``--overwrite``:

.. code-block:: console

   $ spack -e . install --overwrite -y quantum-espresso
   ==> Fetching https://... blobs/sha256:...
   [ ] zia4bn3 quantum-espresso@7.5 fetching from build cache (0s)
   [ ] zia4bn3 quantum-espresso@7.5 relocating (1s)
   [+] zia4bn3 quantum-espresso@7.5 ... (7s)

Two blobs are fetched per spec: a JSON manifest and the actual binary tarball.
OCI registries are content-addressed, which is why we see ``sha256:...`` hashes rather than human-readable filenames.

----------------------------------
Creating runnable container images
----------------------------------

So far the OCI registry has only been used as a Spack build cache.
But because the artifacts are valid OCI images, we can also pull them with ``docker``.

Let's try the obvious thing first — *without* a base image:

.. code-block:: console

   $ docker run --rm localhost:5000/buildcache:quantum-espresso-7.5-zia4bn3lvraagxfnu77ysgewykavwnsc.spack pw.x
   exec /root/spack/opt/spack/linux-x86_64_v3/quantum-espresso-7.5-.../bin/pw.x: no such file or directory

It fails: the layers we pushed contain the Spack-built artifacts, but not the host's ``glibc``, which Spack always treats as an external package.
Without a base image there is no ``/lib`` at all in the container, hence the cryptic error.

The fix is to push again with ``--base-image`` pointing at a minimal distribution that provides a compatible ``glibc``:

.. code-block:: console

   $ spack -e . buildcache push --force --without-build-dependencies \
         --base-image ubuntu:26.04 my-registry

The base image's ``libc`` must be at least as new as the one used at build time, or the binaries will fail at runtime with errors like ``version `GLIBC_2.43' not found``.
The distribution itself does not have to match — try ``archlinux:latest`` for instance, which ships a recent enough ``glibc`` while giving you a very different userland (``pacman`` instead of ``apt``, etc.).

Now the image runs:

.. code-block:: console

   $ docker run --rm localhost:5000/buildcache:quantum-espresso-7.5-zia4bn3lvraagxfnu77ysgewykavwnsc.spack pw.x

        Program PWSCF v.7.5 starts on 15May2026 at 11:09:19

        This program is part of the open-source Quantum ESPRESSO suite
        ...

Beyond ``glibc``, the base image also gives us a shell and standard utilities, which is convenient.

--------------------------------------
Spack environments as container images
--------------------------------------

So far we've created an image per package.
Often we want a single image that contains a *combination* of packages — the full environment.

Pass ``--tag`` to give the environment image a human-readable name:

.. code-block:: console

   $ spack -e . buildcache push --without-build-dependencies \
         --base-image ubuntu:26.04 \
         --tag qe-and-numpy \
         my-registry
   ...
   ==> Tagged localhost:5000/buildcache:qe-and-numpy

Spack publishes each package as its own image layer.
Layers are shared between image tags, so the combined image is essentially free in storage terms.
Unlike Docker, where each ``RUN`` line creates a layer that depends on the previous one, Spack package layers are independent and can be combined in any order.

Pull and run:

.. code-block:: console

   $ docker run --rm localhost:5000/buildcache:qe-and-numpy bash -c \
       'pw.x 2>&1 | head -3; python3 -c "import numpy; print(\"numpy\", numpy.__version__)"'

        Program PWSCF v.7.5 starts on 15May2026 at 11:19:11

        This program is part of the open-source Quantum ESPRESSO suite
   numpy 2.4.4

Both Quantum ESPRESSO and NumPy are immediately usable because Spack writes a ``PATH`` and ``PYTHONPATH`` into the image's environment that points at each package's install prefix.
Note that Spack does *not* materialize the environment's view inside the image — the packages live at their original Spack prefixes, just like on the host.

------------------------------------
Do I need ``docker`` or ``buildah``?
------------------------------------

In older versions of Spack it was common practice to generate a ``Dockerfile`` from a Spack environment using ``spack containerize`` and then build the image with ``docker build``:

.. code-block:: Dockerfile

   FROM <base image> AS build
   COPY spack.yaml /root/env/spack.yaml
   RUN spack -e /root/env install

   FROM <base image>
   COPY --from=build /opt/spack/opt /opt/spack/opt

This approach still works and ``spack containerize`` still exists, but it has a few downsides:

* If ``RUN spack -e /root/env install`` fails, Docker discards the whole layer, so successfully built dependencies are lost.
  Troubleshooting typically means starting from scratch in a ``docker run`` session.
* In some CI environments you cannot run ``docker build`` safely — for example, when the CI script itself runs inside a container ("Docker-in-Docker").

The OCI build cache approach decouples the three things ``docker build`` combines: build isolation, running the build, and creating an image.
You run ``spack install`` wherever you like (host, sandbox, container) and then ``spack buildcache push`` to turn the result into images.

----------
Relocation
----------

Spack lets users install packages into any prefix they like — typically ``~/spack/opt/spack/...``.
That makes it more flexible than most package managers, but it also means binaries contain *absolute paths* to machine-specific locations, which must be rewritten when the binary is reinstalled somewhere else.

Spack handles this automatically when installing from a binary cache.
But when you *produce* binaries that are meant to be redistributed, remember: Spack can only relocate paths in a binary if the **target prefix is no longer than the prefix used during the build**.

The reason is that absolute paths typically live in the binary's string table — a list of null-terminated strings referenced by offset.
Strings can be edited in place, but they cannot grow without overwriting their neighbors.

To maximize the chances of successful relocation, build in a relatively long path.
Spack can pad install prefixes for you:

.. code-block:: console

   $ spack -e . config add config:install_tree:padded_length:256

------------------------
Using build caches in CI
------------------------

Build caches are also a great way to speed up CI pipelines.
Both GitHub Actions and GitLab CI support container registries, so the same workflow we used here works in CI.

Spack provides a basic GitHub Action that wires up a shared build cache for you:

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

In this tutorial we have:

* consumed a pre-populated **filesystem** build cache at ``/buildcache`` to install Quantum ESPRESSO and NumPy without any source builds;
* steered Spack's concretizer towards a fully *reusable* solution with ``packages:{c,cxx,fortran}:prefer``;
* set up a **local OCI registry** as a second build cache and pushed our environment to it;
* used the same OCI artifacts as **runnable container images**, both per-package and as a combined environment.
