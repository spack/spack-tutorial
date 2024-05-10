.. Copyright 2013-2023 Lawrence Livermore National Security, LLC and other
   Spack Project Developers. See the top-level COPYRIGHT file for details.

   SPDX-License-Identifier: (Apache-2.0 OR MIT)

.. include:: common/setup.rst

.. _binary-cache-tutorial:

==================================
Binary Caches Tutorial
==================================

In this section of the tutorial we will be focused on sharing Spack-built
binaries with other users. Build caches are a way to 

What we will showcase is primarily how to set up a binary cache on top of
an **OCI container registry** like Docker Hub or Github Packages. Spack
supports other storage backends, like the filesystem, S3, and Google Cloud
Storage, but OCI build caches have a few interesting properties that make
them worth exploring further.

Before we configure a build cache, let's install a somewhat non-trivial package
in a new environment:

.. code-block:: console

   $ mkdir ~/myenv && cd ~/myenv
   $ spack env create --with-view view .
   $ spack -e . add julia
   $ spack -e . install

This should install ``julia`` with all of its dependencies such as ``llvm`` from
the builtin binary cache. Let's see if it works by running the julia REPL:

.. code-block:: console

   $ ./view/bin/julia
   julia> 1 + 1
   2

Now we'd like to share these executables with other users. First we will focus
on sharing the binaries with other Spack users, but later we will see how
users completely unfamiliar with Spack can easily use the binaries too.

------------------------------------------------
Setting up an OCI build cache on GitHub Packages
------------------------------------------------

For this tutorial we will be using GitHub Packages as an OCI registry, since
most people have a GitHub account and it's easy to use.

First go to `<https://github.com/settings/tokens>`_ to generate a Personal access
token with ``write:packages`` permissions. Copy this token.

Next, we will add this token to the mirror config section of the Spack environment:

.. code-block:: console

   $ spack -e . mirror add \
     --oci-username <user> \
     --oci-password <token> \
     --unsigned \
     my-mirror \
     oci://ghcr.io/<user>/buildcache


.. note ::

   We talk about mirrors and build caches almost interchangeably, because every build
   cache is a binary mirror. Source mirrors exist too, which we will not cover in this
   tutorial.


Your ``spack.yaml`` file should now contain the following:

.. code-block:: yaml

   spack:
     specs:
     - julia
     mirrors:
        my-mirror:
           url: oci://ghcr.io/<user>/buildcache
           access_pair:
           - <user>
           - <token>
           signed: false

Let's push ``julia`` and its dependencies to the build cache

.. code-block:: console

   $ spack -e . buildcache push my-mirror

which outputs

.. code-block:: text

   ==> Selected 66 specs to push to oci://ghcr.io/<user>/buildcache
   ==> Checking for existing specs in the buildcache
   ==> 66 specs need to be pushed to ghcr.io/<user>/buildcache
   ==> Uploaded sha256:d8d9a5f1fa443e27deea66e0994c7c53e2a4a618372b01a43499008ff6b5badb (0.83s, 0.11 MB/s)
   ...
   ==> Uploading manifests
   ==> Uploaded sha256:cdd443ede8f2ae2a8025f5c46a4da85c4ff003b82e68cbfc4536492fc01de053 (0.64s, 0.02 MB/s)
   ...
   ==> Pushed zstd@1.5.6/ew3aaos to ghcr.io/<user>/buildcache:zstd-1.5.6-ew3aaosbmf3ts2ylqgi4c6enfmf3m5dr.spack
   ...
   ==> Pushed julia@1.9.3/dfzhutf to ghcr.io/<user>/buildcache:julia-1.9.3-dfzhutfh3s2ekaltdmujjn575eip5uhl.spack

The location of the pushed package

.. code-block:: text

   ghcr.io/<user>/buildcache:julia-1.9.3-dfzhutfh3s2ekaltdmujjn575eip5uhl.spack

looks very similar to a container image --- we will get to that in a bit.

.. note ::

   The package is ``private`` by default, which means you need the token to access it. We want to
   make it public so that anyone can access it. This can be done by going to GitHub Packages from
   your GitHub account, selecting the package, go to ``package settings``, and change the
   visibilty to ``public`` in the ``Danger Zone`` section. A direct URL for this page is

   .. code-block:: text

      https://github.com/users/<user>/packages/container/buildcache/settings


-------------------------------
Installing from the build cache
-------------------------------

Let's make sure that we *only* use the build cache that we just created, and not the
builtin one that is configured for the tutorial. The easiest way to do this is to
override the ``mirrors`` config section in the environment by using a double colon
in the ``spack.yaml`` file:

.. code-block:: yaml

   spack:
     specs:
     - vim
     - julia
     mirrors::  # <- note the double colon
        my-mirror:
           url: oci://ghcr.io/<user>/buildcache
           access_pair:
           - <user>
           - <token>
           signed: false

If we now reinstall all binaries, we'll see that Spack automatically fetches them
from the GitHub registry:

.. code-block:: console

   $ spack -e . uninstall --all
   $ spack -e . install
   ==> Installing gcc-runtime-11.4.0-f47qm6qeplqyahc4zhfpfdnf5mo6gxvd [2/68]
   ==> Fetching https://ghcr.io/v2/<user>/buildcache/blobs/sha256:b272a2193fa03472b85f731bdf24a04c8d9d0553cf9457f0ed9c896988ad16ff
   ==> Fetching https://ghcr.io/v2/<user>/buildcache/blobs/sha256:fedc2c76e472372caf8f04976e75e81b511ed7a7b1c4501bf5c90fe978728169
   ==> Extracting gcc-runtime-11.4.0-f47qm6qeplqyahc4zhfpfdnf5mo6gxvd from binary cache
   ==> gcc-runtime: Successfully installed gcc-runtime-11.4.0-f47qm6qeplqyahc4zhfpfdnf5mo6gxvd
   ...

Two blobs are fetched for each spec: a metadata file and the actual binary package. If you've
used ``docker pull`` or other container runtimes before, these types of hashes may look
familiar. There are no human readable file names, files are addressed by their content hash.

------------------------------------
Reuse of binaries from a build cache
------------------------------------

Spack's concretizer optimizes for **reuse**. This means that it will avoid source builds if it
can use specs for which binaries are readily available.

In the previous example we managed to install packages from our build cache, but we did not
concretize our environment again. Users on other machines with different distributions will have
to concretize, and therefore we should make sure that the build cache is indexed so that the
concretizer can take it into account. This can be done by running

.. code-block:: console

   $ spack -e . buildcache update-index

This operation can take a while for large build caches, since it fetches all metatadata of
available packages. For convenience you can also run ``spack buildcache push --update-index ...``
to avoid a separate step.


.. note::

   As of Spack 0.22, build caches can be used across different Linux distros. The concretizer
   will reuse specs that have a host compatible ``libc`` dependency (e.g. ``glibc`` or ``musl``).
   For packages compiled with ``gcc`` (and a few others), users do not have to install compilers
   first, as the build cache is self-contained.
  
----------------------------------
Creating runnable container images
----------------------------------

The build cache we have created uses an OCI registry, which is the same technology that is used
to store container images. So far we have used this build cache as any other build cache: the
concretizer can use it to avoid source builds, and ``spack install`` will fetch binaries from it.

However, we can also use this build cache to share binaries directly as runnable container images.

We can already attempt to run the image associated with the ``julia`` package that we have
pushed earlier:

.. code-block:: console

   $ docker run ghcr.io/<user>/buildcache:julia-1.9.3-dfzhutfh3s2ekaltdmujjn575eip5uhl.spack julia
   exec /home/spack/spack/opt/spack/linux-ubuntu22.04-x86_64_v3/gcc-11.4.0/julia-1.9.3-dfzhutfh3s2ekaltdmujjn575eip5uhl/bin/julia: no such file or directory

but immediately we see it fails. The reason is that one crucial part is missing, and that is a
``glibc``, which Spack always treats as an external package.

To fix this, we force push to the registry again, but this time we specify a base image with a
recent version of ``glibc``, for example from ``ubuntu:24.04``:

.. code-block:: console

   $ spack -e . buildcache push --force --base-image ubuntu:24.04 my-mirror
   ...
   ==> Pushed julia@1.9.3/dfzhutf to ghcr.io/<user>/buildcache:julia-1.9.3-dfzhutfh3s2ekaltdmujjn575eip5uhl.spack

Now let's pull this image again and run it:

.. code-block:: console

   $ docker pull ghcr.io/<user>/buildcache:julia-1.9.3-dfzhutfh3s2ekaltdmujjn575eip5uhl.spack
   $ docker run ghcr.io/<user>/buildcache:julia-1.9.3-dfzhutfh3s2ekaltdmujjn575eip5uhl.spack
   root@f53920f8695a:/# julia
   julia> 1 + 1
   2

This time it works! The minimal ``ubuntu:24.04`` image provides us not only with ``glibc``, but
also other utilities like a shell.

Notice that you can use any base image of choice, like ``fedora`` or ``rockylinux``. The only
constraint is that it has a ``libc`` compatible with the external in the Spack built the binaries.
Spack does not validate this.

--------------------------------------
Spack environments as container images
--------------------------------------

The previous container image is a good start, but it would be nice to add some more utilities to
the image. If you've paid attention, Spack generates exactly one container image for each package
it pushed to the OCI registry. All these images share their layers: every Spack package corresponds
to a layer in each image.

Because Spack installs every pacakge into a unique prefix, it is incredibly easy for us to compose
multiple packages into a single image.

Let's add a simple text editor like ``vim`` to our previous environment next to ``julia``, so that
we could both edit and run Julia code:

.. code-block:: console

   $ spack -e . add vim
   $ spack -e . install

This time we push to the OCI registry, but also pass ``--tag julia-and-vim`` to instruct Spack
to create an image for the environment as a whole, with a human-readable tag:

   $ spack -e . buildcache push --base-image ubuntu:24.04 --tag julia-and-vim my-mirror
   ==> Tagged ghcr.io/<user>/buildcache:julia-and-vim

Now let's run a container from this image:

.. code-block:: console

   $ docker run -it --rm ghcr.io/<user>/buildcache:julia-and-vim
   root@f53920f8695a:/# vim ~/example.jl  # create a new file with some Julia code 
   root@f53920f8695a:/# julia ~/example.jl  # and run it

-------
Summary
-------

In this tutorial we have created a build cache on top of an OCI registry, which can be used

* to ``spack install julia vim`` on machines without source builds
* to automatically create container images for individual packages while pushing to the cache
* to create container images for multiple packages at once
