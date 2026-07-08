.. Copyright Spack Project Developers. See COPYRIGHT file for details.

   SPDX-License-Identifier: (Apache-2.0 OR MIT)

.. include:: common/setup.rst

.. _binary-cache-tutorial:

==================================
Binary Caches Tutorial
==================================

This section covers how to share Spack-built binaries across machines and users using **build caches**.

Spack supports a range of storage backends for build caches: an ordinary filesystem, Amazon S3, Google Cloud Storage, and any OCI-compatible container registry (Docker Hub, GitHub Packages, a local ``docker registry``, and so on).
We begin with the filesystem mirror that the tutorial container is already configured to use, and then move on to OCI registries, which carry the additional property that the same artifacts can be used as runnable container images.

``julia`` is the running example throughout.
It has a non-trivial dependency in ``llvm`` and an interactive REPL that makes it easy to confirm an installation works.

-------------------------------------------
Installing julia from the build cache
-------------------------------------------

The tutorial container ships a pre-populated filesystem build cache, registered in the :ref:`basics section <basics-tutorial>` as the signed mirror named ``tutorial``.
Because that mirror is already active, ``julia`` and its dependencies are available as binaries without any further configuration.

Create an environment with a view and add ``julia`` to it:

.. literalinclude:: outputs/cache/install-julia.out
   :language: console

.. note::

   The terms *mirror* and *build cache* are used almost interchangeably, since every build cache is a binary mirror.
   Source mirrors also exist but are not covered in this tutorial.

Install the environment:

.. literalinclude:: outputs/cache/install.out
   :language: spec

Both ``julia`` and every transitive dependency, including ``llvm``, are fetched and relocated from the ``tutorial`` mirror; nothing is built from source.
Given a build cache, the concretizer prefers concrete specs for which binaries already exist.

Confirm that the executable works through the environment's view:

.. literalinclude:: outputs/cache/julia-run.out
   :language: console

.. note::

   Build caches can be used across different Linux distributions.
   The concretizer reuses specs that have a host-compatible ``libc`` (e.g. ``glibc`` or ``musl``), and binaries built with ``gcc`` carry their compiler runtime libraries as a separate dependency, so users do not need to install a compiler first.

-------------------------------------------------
Setting up a local OCI build cache
-------------------------------------------------

The previous section consumed binaries from a build cache.
This section covers publishing binaries to one, using an **OCI container registry** as the backend.

OCI registries are useful in this role because the same artifacts can serve both as a Spack build cache and as runnable container images.
OCI registries in common use include Docker Hub, GitHub Container Registry (GHCR), and Amazon ECR.
For this tutorial we run a registry locally, which avoids authentication:

.. literalinclude:: outputs/cache/registry.out
   :language: console

This is the official `registry image <https://hub.docker.com/_/registry>`_ from Docker Hub.
It serves an empty OCI registry on ``http://localhost:5000``.

Add it as a second mirror:

.. literalinclude:: outputs/cache/mirror-add.out
   :language: console

The URL has three parts:

* ``oci+http://``: an OCI registry over plain HTTP, without TLS.
  A remote registry would normally use ``oci://`` (HTTPS).
* ``localhost:5000``: the registry's host and port.
* ``/buildcache``: the image name under which Spack publishes all artifacts.

The environment's ``spack.yaml`` now contains the mirror:

.. code-block:: yaml

   mirrors:
     my-registry:
       url: oci+http://localhost:5000/buildcache
       signed: false

The same configuration works against a hosted registry such as GHCR or Docker Hub by switching to an ``oci://`` URL and supplying credentials with ``--oci-username`` and ``--oci-password-variable``.

-------------------------------------
Pushing to the OCI build cache
-------------------------------------

Push the environment to the local registry:

.. literalinclude:: outputs/cache/push.out
   :language: console

Two things about this invocation are worth noting.

The ``--without-build-dependencies`` flag is passed because ``julia`` was installed from a binary cache, so build-only dependencies like ``cmake`` are not present on this machine.
Without the flag, Spack would report that those packages are not installed.

All artifacts live under the single image name ``localhost:5000/buildcache``.
Spack auto-generates one tag per spec, of the form ``<name>-<version>-<hash>.spack``, including the package hash so that each spec resolves to a distinct tag.

Re-running the push detects that nothing needs to be uploaded:

.. literalinclude:: outputs/cache/push-again.out
   :language: console

-------------------------------------------
Reinstalling from the OCI build cache
-------------------------------------------

So far ``julia`` could have come from either mirror.
To confirm that the OCI registry works as a build cache on its own, disable the filesystem ``tutorial`` mirror by changing ``mirrors:`` to ``mirrors::`` in ``spack.yaml``.
The trailing ``::`` replaces, rather than extends, the mirrors inherited from Spack's global configuration:

.. code-block:: yaml

   mirrors::
     my-registry:
       url: oci+http://localhost:5000/buildcache
       signed: false

Reinstall ``julia`` with ``--overwrite``.
Only ``julia`` is reinstalled; its dependencies remain installed and are not refetched.

.. literalinclude:: outputs/cache/reinstall.out
   :language: spec

Each spec is stored as two blobs: a JSON manifest and the binary tarball.
OCI registries are content-addressed, hence the ``sha256:...`` identifiers shown in the push output rather than human-readable filenames.

----------------------------------
Creating runnable container images
----------------------------------

So far the OCI registry has been used only as a Spack build cache.
Since the artifacts are also valid OCI images, they can be pulled directly with ``docker``.

Consider what happens when running an image without a base image:

.. literalinclude:: outputs/cache/docker-run-fail.out
   :language: console

The run fails because the layers we pushed contain the Spack-built artifacts but not the host's ``glibc``, which Spack always treats as an external package.
Without a base image the container has no ``/lib`` directory at all, which produces the error above.

The resolution is to push again with ``--base-image`` pointing at a minimal distribution that provides a compatible ``glibc``:

.. literalinclude:: outputs/cache/push-base-image.out
   :language: console

The base image's ``libc`` must be at least as new as the one used at build time, otherwise the binaries fail at runtime with errors of the form ``version `GLIBC_2.38' not found``.
The distribution itself need not match.
``archlinux:latest``, for example, ships a sufficiently recent ``glibc`` while providing a different userland (``pacman`` instead of ``apt``, and so on).

The image now runs.
Because the tag was pushed once already, ``docker`` has the old single-layer image cached locally; ``--pull always`` forces it to fetch the rebuilt image with the base layer:

.. literalinclude:: outputs/cache/docker-run.out
   :language: console

In addition to ``glibc``, the base image provides a shell and the standard utilities.

--------------------------------------
Spack environments as container images
--------------------------------------

The preceding section produced one image per package.
For most uses a single image containing the full environment is more convenient.

Add a text editor to the environment, so that the image can both edit and run Julia code:

.. literalinclude:: outputs/cache/install-vim.out
   :language: spec

.. note::

   With the ``tutorial`` mirror disabled, ``vim`` is built from source.
   Change ``mirrors::`` back to ``mirrors:`` first to install it from the ``tutorial`` cache; either way the build is quick.

Pass ``--tag`` to assign the environment image a human-readable name:

.. literalinclude:: outputs/cache/push-tag.out
   :language: console

Spack publishes each package as its own image layer.
Layers are shared between image tags, so the combined image takes almost no extra storage.
Unlike Docker, where each ``RUN`` line creates a layer that depends on the previous one, Spack package layers are independent and can be combined in any order.

Run the combined image:

.. code-block:: console

   $ docker run -it --rm localhost:5000/buildcache:julia-and-vim
   root@f53920f8695a:/# vim example.jl    # write some Julia code
   root@f53920f8695a:/# julia example.jl  # and run it

Both ``julia`` and ``vim`` are immediately usable because Spack writes ``PATH`` into the image's environment, pointing at each package's install prefix.
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

* installing ``julia`` from the pre-configured ``tutorial`` build cache without any source builds;
* setting up a local OCI registry as a second build cache and pushing the environment to it;
* reinstalling from the OCI cache to confirm that it functions as a regular Spack mirror;
* using the same OCI artifacts as runnable container images, both per-package and as a combined environment with ``--tag``.
