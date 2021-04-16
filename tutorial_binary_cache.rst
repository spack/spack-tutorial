.. Copyright 2013-2021 Lawrence Livermore National Security, LLC and other
   Spack Project Developers. See the top-level COPYRIGHT file for details.

   SPDX-License-Identifier: (Apache-2.0 OR MIT)

.. include:: common/setup.rst

.. _binary-cache-tutorial:

============================
Mirror Tutorial
============================

This tutorial will guide you through the process of setting up a
mirror to cache source and binary files. Source and binary caches are
extremely useful when using spack on a machine without internet
access. Source cache mirrors allow you to fetch source code from a
directory on your filesystem instead of accessing the outside
internet, and binary cache mirrors allow you to install pre-compiled
binaries to your spack installation path. Together, these caches can
be used to speed up builds when using spack within a larger
development team.

We will use the filesystem for the mirrors in this tutorial, but
mirrors can also be setup on web servers or s3 buckets -- any URL that
``curl`` can access can be setup as a Spack mirror.

By default, Spack comes configured with a source mirror in the cloud
to increase download reliability. We've also already set up a mirror
in this tutorial for binary caches. We can see these mirrors are
configured

.. literalinclude:: outputs/cache/mirror-list-0.out
   :language: console

--------------------------------
Setting up a source cache mirror
--------------------------------

When you run ``spack install``, spack goes out to the internet to grab
the source code for your package in order to build your packages. This
works fine on most clusters, but what do you do if the cluster in
question doesn't have access to the outside internet? This could
happen for a variety of reasons. Maybe you're building on a compute
node that isn't connected to the greater internet, or maybe even the
whole cluster has been isolated from the internet.

Spack has an easy answer to this -- setting up a source mirror. When you
use a source mirror, spack checks the mirror for the source code
before going to the outside internet.

Building a source mirror is easy. Let's start with the same simple
environment. First, let's build our software on a computer with
external internet access.

.. literalinclude:: outputs/cache/setup-scr.out
   :language: console

Once we've created and installed this environment, we can easily
upload source code needed to reproduce this build to a mirror.  The
following command both creates the mirror and uploads the source code
for the ``scr`` package included in our environment. The ``-d`` flag
tells spack where to place the mirrored source code files.

.. literalinclude:: outputs/cache/spack-mirror-single.out
   :language: console

We can configure spack to use this source mirror by adding
a few lines to your ``spack.yaml`` file.

.. literalinclude:: outputs/cache/spack-mirror-config.out
   :language: console

Manually uploading every package in an environment can be
tedious. Luckily, when run within an environment, ``spack mirror
create`` with the ``-a`` flag will upload every source used to build
the current environment to the specified directory.

.. literalinclude:: outputs/cache/spack-mirror-all.out
   :language: console

This directory can be shared between users on a shared filesystem and
protected with typical unix file permissions. If you're making a spack
mirror on a shared filesystem, remember to fix the file permissions
every time you update the mirror, or update your
`umask <https://man7.org/linux/man-pages/man2/umask.2.html>`_ settings
so any new files you create have the appropriate permissions. Here you
would replace the word ``spack`` to the appropriate unix group.

.. literalinclude:: outputs/cache/spack-mirror-permissions.out
   :language: console

As long as spack can read from the mirror directory, spack will
attempt to read source packages from the mirror instead of accessing
the internet. This can be a huge boon for computers that can't access
the external internet but can access a shared filesystem. If you need
to use spack on a system that is isolated from the external internet,
you must bundle the whole spack mirror directory and unbundle it on
the isolated system. From there, you follow the same steps to use the
spack mirror as you would on any computer that can't access the
external internet.

If you need to add more sources to the mirror, you can re-run the
command you used to create the mirror. For example, assume we want to
add bzip2 to our environment.

.. literalinclude:: outputs/cache/spack-mirror-3.out
   :language: console

Now that we've added bzip2, we need to update the mirror.

.. literalinclude:: outputs/cache/spack-mirror-4.out
   :language: console

Spack will skip uploading source code packages that are already
included in the spack mirror. Mirrors can be shared across different
environments, meaning one mirror can house all the source code needed
to build your team's dependencies.

--------------------------------
Setting up a binary cache mirror
--------------------------------

If you're going to be setting up a team to use spack as part of their
development practice, you'll run up against the biggest disadvantage
to using spack: building all your packages from scratch is
slow. Recompiling the software dependencies for a large project can
take hours to complete. If every developer is rebuilding their own
software stack, that leads to a massive waste of computational
resources and a loss of developer productivity.

Spack has two ways to help alleviate this problem: chained spack
instances and spack binary caches. For now, we're going to discuss
spack binary caches as a way of solving this issue.

A spack binary cache is made up of spack binary packages.  Each spack
binary package, ending with a ``.spack`` extension, is a tarball of an
installed spack package signed with a gpg signature. When you install
a package from a mirror with a binary cache, spack

* Checks to see if there is a spack binary package that exactly
  matches the hash of the spec you want to build.
* If a binary package is found, spack checks to see if the signature
  on the spack binary package is trusted. If the signature isn't
  trusted or no package was found, spack builds the package from
  source.
* If the signature is trusted, then spack unzips and relocates the
  spack package.

For the user, spack binary caches are transparent to use. This is a
clear departure from systems like conda, where you need to chose
separate workflows for binary and source packages. We've already
demonstrated using spack binary caches earlier in the tutorial when we
set up spack to use a binary mirror. As a reminder, we ran:

.. literalinclude:: outputs/basics/mirror.out
   :language: console

Building a spack binary cache mirror has some gotchas, but is almost
as easy as building a source mirror. We'll start by making a new
environment for ourselves.  Since we're intending to publish to a
binary cache, we'll need to compile all these packages ourselves.
This can take some time, so we'll make a new environment with some
packages that compile quickly.

.. literalinclude:: outputs/cache/binary-cache-1.out
   :language: console

Before we build anything, we need to modify the following line in our
spack configuration file. Then, just to be sure, we'll initiate a
build of this environment and force ourselves to not use any cache.

.. literalinclude:: outputs/cache/binary-cache-2.out
   :language: console

This configuration change ensures that spack installs all our packages
to a path that is at least 128 characters. We need this change because
of how spack relocates packages. Relocation consists of the following
steps:

  * Search all text files to replace the package builder's path with
    your specific local installation path.
  * Use ``patchelf`` to replace all the RPATHs in your binaries to
    point to your specific local installation path.
  * Search all binaries to replace hard-coded C strings of the package
    builder's path with your specific local installation path.

Adding padding ensures that any paths hard-coded as C strings in our
binaries will be large enough to hold our user's eventual install
path. We advise picking 128 because longer strings occasionally cause
compilation problems with some software packages. If the user's
install path is too long, spack will give you a warning. All scripts
and and RPATHs will still be properly relocated, but C strings within
any binaries will not be modified. Depending on the package, this may
cause problems when you try and use the software.

We also need to create a gpg key to sign all our packages. You should
back up the secret and public keys to a secure place so they can be
re-used in the future.

.. literalinclude:: outputs/cache/binary-cache-3.out
   :language: console

With this setup done, we're ready to fill a binary cache with binary
packages. Binary packages are attached to an existing source mirror.
We follow the same steps we used for the source mirror -- making an
environment, creating the source mirror, and building the packages to
a spack installation with our padded path. To upload a spec to a
binary cache, simply use the command ``spack buildcache
create --only=package spec``. We use this here in a for loop to create
binary packages for every non-external package in our environment.

.. literalinclude::  outputs/cache/binary-cache-4.out
   :language: console

Voila, done! Our spack mirror has now been augmented with a binary
cache.  This cache can be used on systems without external internet
access, just like with a spack source mirror. As always, remember to
update the file permissions after updating the mirror.

.. literalinclude:: outputs/cache/spack-mirror-permissions.out
   :language: console

Though it's outside the scope of this tutorial, spack mirrors and
build caches can also be hosted over ``https://`` and ``s3://`` as
well. Consult the spack documentation for more information on how to
do this.

Before a user can use this binary cache, they will need to make sure
that they trust all the packages listed in the binary cache. If you're
sharing files between trusted users on a filesystem, you can do this
with the following command:

.. literalinclude:: outputs/cache/trust.out
   :language: console

Together, this means download all the keys on the binary cache and
trust them. Have your users run the above command on a new spack
instance before they initiate a build.

-------------
Cache Summary
-------------

If you're using spack within a development team, consider setting up
source mirrors with binary caches. Source mirrors will let you
replicate a spack environment on a machine without external internet
access, and binary mirrors free you from the burden of recompiling
everything from scratch and save you development time.
