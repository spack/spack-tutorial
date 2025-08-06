.. Copyright Spack Project Developers. See COPYRIGHT file for details.

   SPDX-License-Identifier: (Apache-2.0 OR MIT)

.. include:: common/setup.rst

.. _binary-cache-tutorial:

==================================
Binary Caches Tutorial
==================================

In this section of the tutorial, you will learn how to share Spack-built binaries across machines and users using build caches.

We will explore a few concepts that apply to all types of build caches, but the focus is primarily on **OCI container registries** (like Docker Hub or Github Packages) as a storage backend for binary caches.
Spack supports a range of storage backends, such as an ordinary filesystem, Amazon S3, and Google Cloud Storage, but OCI build caches have a few interesting properties that make them worth exploring more in-depth.

Before we configure a build cache, let's install the ``julia`` package, which is an interesting example because it has some non-trivial dependencies like ``llvm``, and features an interactive REPL that we can use to verify that the installation works.

.. code-block:: spec

   $ mkdir ~/myenv && cd ~/myenv
   $ spack env create --with-view view .
   $ spack -e . add julia
   $ spack -e . install

Let's run the ``julia`` REPL

.. code-block:: console

   $ ./view/bin/julia
   julia> 1 + 1
   2

Now we'd like to share these executables with other users.
First we will focus on sharing the binaries with other *Spack* users, and later we will see how users completely unfamiliar with Spack can easily use the applications too.

------------------------------------------------
Setting up an OCI build cache on GitHub Packages
------------------------------------------------

For this tutorial we will be using GitHub Packages as an OCI registry, since most people have a GitHub account and it's easy to use.

First, go to `<https://github.com/settings/tokens>`_ to generate a Personal Access Token (classic) with ``write:packages`` permissions.
Copy this token.

Next, we will add this token to the mirror configuration section for the Spack environment.
Replace `<your-github-username>` with your GitHub username and `<your-github-username-or-org>` with your GitHub username or an organization where you have permission to create packages.
The build cache name, `buildcache-${USER}-${HOSTNAME}`, is a suggestion; you can choose your own.

.. code-block:: console

   $ export MY_OCI_TOKEN=<paste-your-token-here>
   $ spack -e . mirror add \
       --oci-username <your-github-username> \
       --oci-password-variable MY_OCI_TOKEN \
       --unsigned \
       my-mirror \
       oci://ghcr.io/<your-github-username-or-org>/buildcache-${USER}-${HOSTNAME}


.. note::

   We talk about mirrors and build caches almost interchangeably, because every build cache is a binary mirror.
   Source mirrors exist too, which we will not cover in this tutorial.


Your ``spack.yaml`` file should now contain the following:

.. code-block:: yaml

   spack:
     specs:
     - julia
     mirrors:
        my-mirror:
           url: oci://ghcr.io/<github_user>/buildcache-<user>-<host>
           access_pair:
              id: <user>
              secret_variable: MY_OCI_TOKEN
           signed: false

Let's push ``julia`` and its dependencies to the build cache

.. code-block:: console

   $ spack -e . buildcache push my-mirror

which outputs

.. code-block:: text

   ==> Selected 66 specs to push to oci://ghcr.io/<github_user>/buildcache-<user>-<host>
   ==> Checking for existing specs in the buildcache
   ==> 66 specs need to be pushed to ghcr.io/<github_user>/buildcache-<user>-<host>
   ==> Uploaded sha256:d8d9a5f1fa443e27deea66e0994c7c53e2a4a618372b01a43499008ff6b5badb (0.83s, 0.11 MB/s)
   ...
   ==> Uploading manifests
   ==> Uploaded sha256:cdd443ede8f2ae2a8025f5c46a4da85c4ff003b82e68cbfc4536492fc01de053 (0.64s, 0.02 MB/s)
   ...
   ==> Pushed zstd@1.5.6/ew3aaos to ghcr.io/<user>/buildcache-<user>-<host>:zstd-1.5.6-ew3aaosbmf3ts2ylqgi4c6enfmf3m5dr.spack
   ...
   ==> Pushed julia@1.9.3/dfzhutf to ghcr.io/<user>/buildcache-<user>-<host>:julia-1.9.3-dfzhutfh3s2ekaltdmujjn575eip5uhl.spack

The location of the pushed package, when referred to as an OCI image, will be:

.. code-block:: text

   ghcr.io/<github_user>/buildcache-<user>-<host>:julia-1.9.3-dfzhutfh3s2ekaltdmujjn575eip5uhl.spack

look very similar to a container image --- we will get to that in a bit.

.. note::

   Binaries pushed to GitHub packages are ``private`` by default, which means you need a token to download them.
   You can change the visibility to ``public`` by going to GitHub Packages from your GitHub account, selecting the ``buildcache`` package, go to ``package settings``, and change the visibility to ``public`` in the ``Danger Zone`` section.
   This page can also be directly accessed by going to

   .. code-block:: text

      https://github.com/users/<user>/packages/container/buildcache/settings


-------------------------------
Installing from the build cache
-------------------------------

We will now verify that the build cache works by reinstalling ``julia``.

Let's make sure that we *only* use the build cache that we just created, and not the builtin one that is configured for the tutorial.
The easiest way to do this is to override the ``mirrors`` config section in the environment by using a double colon in the ``spack.yaml`` file:

.. code-block:: yaml

   spack:
     specs:
     - julia
     mirrors::  # <- note the double colon
        my-mirror:
           url: oci://ghcr.io/<github_user>/buildcache-<user>-<host>
           access_pair:
              id: <user>
              secret_variable: MY_OCI_TOKEN
           signed: false

An "overwrite install" should be enough to show that the build cache is used (output will vary based on your specific configuration):

.. code-block:: spec

   $ spack -e . install --overwrite julia
   ==> Fetching https://ghcr.io/v2/<user>/buildcache-<user>-<host>/blobs/sha256:34f4aa98d0a2c370c30fbea169a92dd36978fc124ef76b0a6575d190330fda51
   ==> Fetching https://ghcr.io/v2/<user>/buildcache-<user>-<host>/blobs/sha256:3c6809073fcea76083838f603509f10bd006c4d20f49f9644c66e3e9e730da7a
   ==> Extracting julia-1.9.3-dfzhutfh3s2ekaltdmujjn575eip5uhl from binary cache
   [+] /home/spack/spack/opt/spack/linux-ubuntu22.04-x86_64_v3/gcc-11.4.0/julia-1.9.3-dfzhutfh3s2ekaltdmujjn575eip5uhl

Two blobs are fetched for each spec: a metadata file and the actual binary package.
If you've used ``docker pull`` or other container runtimes before, these types of hashes may look familiar.
OCI registries are content addressed, which means that we see hashes like these instead of human-readable file names.

------------------------------------
Reuse of binaries from a build cache
------------------------------------

Spack's concretizer optimizes for **reuse**.
This means that it will avoid source builds if it can use specs for which binaries are readily available.

In the previous example we managed to install packages from our build cache, but we did not concretize our environment again.
Users on other machines with different distributions will have to concretize, and therefore we should make sure that the build cache is indexed so that the concretizer can take it into account.
This can be done by running

.. code-block:: console

   $ spack -e . buildcache update-index my-mirror

This operation can take a while for large build caches, since it fetches all metadata of available packages.
For convenience you can also run ``spack buildcache push --update-index ...`` to avoid a separate step.


.. note::

   As of Spack 0.22, build caches can be used across different Linux distros.
   The concretizer will reuse specs that have a host-compatible ``libc`` dependency (e.g. ``glibc`` or ``musl``).
   For packages compiled with ``gcc`` (and a few other compilers), users do not have to install compilers first, as the build cache contains the compiler runtime libraries as a separate package dependency.

After an index is created, it's possible to list the available packages in the build cache:

.. code-block:: console

   $ spack -e . buildcache list --allarch


----------------------------------
Creating runnable container images
----------------------------------

The build cache we have created uses an OCI registry, which is the same technology that is used to store container images.
So far we have used this build cache as any other build cache: the concretizer can use it to avoid source builds, and ``spack install`` will fetch binaries from it.

However, we can also use this build cache to share binaries directly as runnable container images.

We can already attempt to run the image associated with the ``julia`` package that we have pushed earlier:

.. code-block:: console

   $ docker run ghcr.io/<user>/buildcache-<user>-<host>:julia-1.9.3-dfzhutfh3s2ekaltdmujjn575eip5uhl.spack julia
   exec /home/spack/spack/opt/spack/linux-ubuntu22.04-x86_64_v3/gcc-11.4.0/julia-1.9.3-dfzhutfh3s2ekaltdmujjn575eip5uhl/bin/julia: no such file or directory

but immediately we see it fails.
The reason is that one crucial part is missing, and that is ``glibc``, which Spack always treats as an external package.

To fix this, we force push to the registry again, but this time we specify a base image with a recent version of ``glibc``, for example from ``ubuntu:24.04``:

.. code-block:: console

   $ spack -e . buildcache push --force --base-image ubuntu:24.04 my-mirror
   ...
   ==> Pushed julia@1.9.3/dfzhutf to ghcr.io/<user>/buildcache:julia-1.9.3-dfzhutfh3s2ekaltdmujjn575eip5uhl.spack

Now let's pull this image again and run it:

.. code-block:: console

   $ docker pull ghcr.io/<github_user>/buildcache-<user>-<host>:julia-1.9.3-dfzhutfh3s2ekaltdmujjn575eip5uhl.spack
   $ docker run -it --rm ghcr.io/<github_user>/buildcache-<user>-<host>:julia-1.9.3-dfzhutfh3s2ekaltdmujjn575eip5uhl.spack
   root@f53920f8695a:/# julia
   julia> 1 + 1
   2

This time it works!
The minimal ``ubuntu:24.04`` image provides us not only with ``glibc``, but also other utilities like a shell.

Notice that you can use any base image of choice, like ``fedora`` or ``rockylinux``.
The only constraint is that it has a ``libc`` compatible with the external ``libc`` Spack used to build the binaries.
Spack does not validate this.

--------------------------------------
Spack environments as container images
--------------------------------------

The previous container image is a good start, but it would be nice to add some more utilities to the image.
If you've paid attention to the output of some of the commands we have run so far, you may have noticed that Spack generates exactly one image tag for each package it pushes to the registry.
Every Spack package corresponds to a single layer in each image, and the layers are shared across the different image tags.

Because Spack installs every package into a unique prefix, it is incredibly easy to compose multiple packages into a container image.
In contrast to Docker images built from commands in a ``Dockerfile`` where each command is run in sequence, Spack package layers are independent, and can in principle be combined in any order.

Let's add a simple text editor like ``vim`` to our previous environment next to ``julia``, so that we could both edit and run Julia code.

.. note::

   You may want to change ``mirrors::`` to ``mirrors:`` in the ``spack.yaml`` file to avoid
   a source build of ``vim`` --- but a source build should be quick.

.. code-block:: spec

   $ spack -e . install --add vim

This time, when we push to the OCI registry, we also pass ``--tag julia-and-vim`` to instruct Spack to create an additional image tag for the environment as a whole, with a more human-readable name:


.. code-block:: console

   $ spack -e . buildcache push --base-image ubuntu:24.04 --tag julia-and-vim my-mirror
   ==> Tagged ghcr.io/<user>/buildcache:julia-and-vim

Now let's run a container from this image:

.. code-block:: console

   $ docker run -it --rm ghcr.io/<github_user>/buildcache-<user>-<host>:julia-and-vim
   root@f53920f8695a:/# vim ~/example.jl  # create a new file with some Julia code
   root@f53920f8695a:/# julia ~/example.jl  # and run it

------------------------------------
Do I need ``docker`` or ``buildah``?
------------------------------------

In older versions of Spack it was common practice to generate a ``Dockerfile`` from a Spack environment using the ``spack containerize`` command, and then use ``docker build`` or other runtimes to create a container image.

This would trigger a multi-stage build, where the first stage would install Spack itself, compilers and the environment, and the second stage would copy the installed environment into a smaller image.
For those familiar with ``Dockerfile`` syntax, it would structurally look like this:

.. code-block:: Dockerfile

   FROM <base image> AS build
   COPY spack.yaml /root/env/spack.yaml
   RUN spack -e /root/env install

   FROM <base image>
   COPY --from=build /opt/spack/opt /opt/spack/opt

This approach is still valid, and the ``spack containerize`` command continues to exist, but it has a few downsides:

* When ``RUN spack -e /root/env install`` fails, ``docker`` will not cache the layer, meaning that all dependencies that did install successfully are lost. Troubleshooting the build typically means starting from scratch either within a ``docker run`` session or on the host system.
* In certain CI environments, it is not possible to use ``docker build`` directly. For example, the CI script itself may already run in a Docker container, and running ``docker build`` *safely* inside a container (Docker-in-Docker) is tricky.

The takeaway is that Spack decouples the steps that ``docker build`` combines: build isolation, running the build, and creating an image.
You can run ``spack install`` on your host machine or in a container, and run ``spack buildcache push`` separately to create an image.

----------
Relocation
----------

Spack is different from many package managers in that it lets users choose where to install packages.
This makes Spack very flexible, as users can install packages in their home directory and do not need root privileges.
The downside is that sharing binaries is more complicated, as binaries may contain hard-coded, absolute paths to machine specific locations, which have to be adjusted when these binaries are installed on a different machine or in a different path.

Fortunately Spack handles this automatically upon install from a binary cache.
But when you build binaries that are intended to be shared, there is one thing you have to keep in mind: Spack can relocate hard-coded paths in binaries *provided that the target prefix is shorter than the prefix used during the build*.

The reason is that binaries typically embed these absolute paths in string tables, which is a list of null-terminated strings, to which the program stores offsets.
That means we can only modify strings in-place, and if the new path is longer than the old one, we would overwrite the next string in the table.

To maximize the chances of successful relocation, you should build your binaries in a relatively long path.
Fortunately Spack can automatically pad paths to make them longer, using the following command:

.. code-block:: console

   $ spack -e . config add config:install_tree:padded_length:256

------------------------
Using build caches in CI
------------------------

Build caches are a great way to speed up CI pipelines.
Both GitHub Actions and GitLab CI support container registries, and this tutorial should give you a good starting point to leverage them.

Spack also provides a basic GitHub Action that already provides you with a binary cache:

.. code-block:: yaml

   jobs:
     build:
       runs-on: ubuntu-22.04
       steps:
       - name: Set up Spack
         uses: spack/setup-spack@v2
       - run: spack install python  # uses a shared build cache

and the `setup-spack readme <https://github.com/spack/setup-spack>`_ shows you how to cache further binaries that are not in the shared build cache.

-------
Summary
-------

In this tutorial we have created a build cache on top of an OCI registry, which can be used

* to run ``spack install julia vim`` on machines and have Spack fetch pre-built binaries instead of building from source.
* to automatically create container images for individual packages when pushing to the cache.
* to create container images for entire Spack environments (multiple packages) at once.
