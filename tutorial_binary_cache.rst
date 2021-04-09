.. Copyright 2013-2021 Lawrence Livermore National Security, LLC and other
   Spack Project Developers. See the top-level COPYRIGHT file for details.

   SPDX-License-Identifier: (Apache-2.0 OR MIT)

.. include:: common/setup.rst

.. _binary-cache-tutorial:

============================
Cache Tutorial
============================

This tutorial will guide you through the process of setting up a
source cache mirror and a binary cache mirror. Source and binary
caches are extremely useful when using spack on a machine without
internet access. Source cache mirrors allow you to fetch source code
from a directory on your filesystem instead of accessing the outside
internet, and binary cache mirrors allow you to install pre-compiled
binaries to your spack installation path. Together, these caches can
be used to speed up builds when using spack within a larger
development team.

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

Once we've built this environment, we can easily make a spack mirror
that contains all the sources required for this build.

When run within an environment, spack mirror create will upload every
source used to build the current environment to the specified
directory. We can configure spack to use this source mirror by adding
a few lines to your spack.yaml file.

This directory can be shared between users on a shared filesystem and
protected with typical unix file permissions. As long as spack can
read from the mirror directory, spack will attempt to read source
packages from the mirror instead of accessing the internet. This can
be a huge boon for computers that can't access the external internet
but can access a shared filesystem. If you need to use spack on a
system that is isolated from the external internet, you must bundle
the whole spack mirror directory and unbundle it on the isolated
system. From there, you follow the same steps to use the spack mirror
as you would on any computer that can't access the external internet..

If you need to add more sources to the mirror, you can re-run the
command you used to create the mirror. For example, assume we want to
add bzip2 to our environment.

Now that we've added bzip2, we need to update the mirror.

Spack will skip uploading source code packages that are already
included in the spack mirror. Mirrors can be shared across different
environments, meaning one mirror can house all the source code needed
to build your team's dependencies.

If you're making a spack mirror on a shared filesystem, remember to
fix the file permissions every time you update the mirror.

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
binary package, ending with a .spack extension, is a tarball of an
installed spack package signed with a gpg signature. When you install
a package from a mirror with a binary cache, spack

* Checks to see if there is a spack binary package that matches your
  exact SHA.
• If a binary package is found, spack checks to see if the
  signature on the spack binary package is trusted.
* If the signature is trusted, then spack
  * Unzips the spack package to a temporary directory.
  * Searches all text files to replace the package builder's path with
    your specific local installation path.
  * Uses ``patchelf`` to replace all the rpaths in your binaries to
    point to your specific local installation path.
  * Searches all binaries to replace hard-coded C strings of the
    package builder's path with your specific local installation path.
  * Copies all these transformed files into your specific local
    installation path.
* Otherwise, spack proceeds to build the package from source.

For the user, spack binary caches are transparent to use. We've
already demonstrated using spack binary caches earlier in the tutorial
when we set up spack to use a binary mirror. As a reminder, we ran:

The spack gpg command is needed to tell spack that we "trust" the gpg
key of the user who built the spack binary package.

Building a spack binary cache mirror has some gotchas, but is almost
as easy as building a source mirror. Before we build anything, we need
to modify the following line in our spack configuration file:

This change ensures that spack installs all our packages to a path
that is at least 128 characters. We need to take this precaution
because when spack installs a binary package, it replaces our path
with the user's installation path. For text files this replacement can
be done in place, but for binaries we need to make sure that all C
strings hard-coded into the binaries are large enough to hold the
user's eventual install path. We advise picking 128 because longer
strings sometimes cause compilation problems with some software
packages.

We also need to create a gpg key to sign all our packages.

We recommend backing up the secret and public keys to a secure place
so they can be re-used in the future.

With this setup done, we're ready to fill a binary cache with binary
packages. Binary packages are attached to an existing source mirror.
We follow the same steps we used for the source mirror -- making an
environment, creating the source mirror, and building the packages to
a spack installation with our padded path. After we've built our
environment, we run the following commands to create binary packages from our build software.


Voila, done! Our spack mirror has now been augmented with a binary
cache.  This cache can be used on systems without external internet
access, just like with a spack source mirror.  As always, remember to
update the file permissions after updating the mirror.

-------------
Cache Summary
-------------

If you're using spack within a development team, consider setting up
source and binary cache mirrors. Source mirrors will let you replicate
a spack environment on a machine without external internet access, and
binary mirrors free you from the burden of recompiling everything from
scratch and save you development time.
