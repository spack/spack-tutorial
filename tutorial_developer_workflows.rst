.. Copyright 2013-2019 Lawrence Livermore National Security, LLC and other
   Spack Project Developers. See the top-level COPYRIGHT file for details.

   SPDX-License-Identifier: (Apache-2.0 OR MIT)

.. _developer-workflows-tutorial

============================
Developer Workflows Tutorial
============================

This tutorial will guide you through the process of using the `spack
dev-build` command to manage dependencies while developing
software. This will allow you to install a package from local source,
develop that source code, and iterate on the different phases of your
build system as necessary.

-----------------------------
Prepare for the tutorial
-----------------------------

If you have already done the :ref:_basics-tutorial you have probably
already set up Spack to run in the tutorial image. If not, you will
want to run the following commands:

.. code-block:: console

  $ git clone https://github.com/spack/spack
  $ cd spack
  $ git checkout releases/v0.13
  $ . share/spack/setup-env.sh
  $ spack mirror add tutorial /mirror
  $ spack gpg trust /mirror/public.key

These commands install Spack into your home directory, add Spack to
your path, and configure Spack to make use of the binary packages
published for this tutorial.

-----------------------------
Installing from local source
-----------------------------

The `spack install` command, as you know, fetches source code from a
mirror or the internet before building and installing your package. As
a developer, we want to build from local source, which we will
constantly change, build, and test.

Let's imagine for a second we're HDF5 developers.

.. code-block:: console

  $ cd ~
  $ git clone https://bitbucket.hdfgroup.org/scm/hdffv/hdf5.git
  $ cd hdf5

Here we have the local HDF5 source that we've been working on. If we
want to build and install it, we can do so using the ``spack
dev-build`` command. Note that we need to provide a version in the
spec we pass to ``spack dev-build``. By default, the ``spack
dev-build`` command will print verbose output from the build system to
the console.

.. code-block:: console

  $ spack dev-build hdf5@develop ~mpi
  ...
  ==> Installing hdf5
  ==> Searching for binary cache of hdf5
  ==> Finding buildcaches in /Users/becker33/mirror/build_cache
  ==> No binary for hdf5 found: installing from source
  ==> No need to fetch for DIY.
  ==> No checksum needed for DIY.
  ==> Sources for DIY stages are not cached
  ==> Using source directory: /Users/becker33/hdf5
  ==> No patches needed for hdf5
  ==> Building hdf5 [AutotoolsPackage]
  ==> Executing phase: 'autoreconf'
  ==> [2019-10-28-15:08:15.788680] './autogen.sh'

  **************************
  * HDF5 autogen.sh script *
  **************************

  Running trace script:
  ...

  ==> Successfully installed hdf5
    Fetch: 0.00s.  Build: 2m 33.28s.  Total: 2m 33.28s.
  [+] /Users/becker33/spack/opt/spack/darwin-mojave-x86_64/clang-9.0.0-apple/hdf5-develop-ncccarpcwda4zgirtricb7psqikcbrc4

Done! HDF5 is installed.

So what's going on here? When we use the `spack dev-build` command,
Spack still manages the package's dependencies as it would for the
``spack install`` command. The dependencies for HDF5 are all
installed, either from binary or source, if they were not
already. Instead of downloading the source code for HDF5, Spack
constructed a stage in the current directory to use the local
source. Spack then constructed the build environment and arguments for
the HDF5 build system as it would for the ``spack install``
command. The resulting installation is added to Spack's database as
usual, and post-install hooks including modulefile generation are ran
as well.

-----------------------------
Development iteration cycles
-----------------------------

Generally, as a developer, we only want to configure our package once,
and then we want to iterate developing and building our code, before
installing it once if at all. We can do this in Spack using the
``-u/--until`` option with the ``spack dev-build`` command. To do this
we need to know the phases of the build that Spack will
use. Fortunately, as experienced HDF5 developers we all happen to know
that those phases are ``autoreconf``, ``configure``, ``build``, and
``install``. If we didn't remember the phases, we could find
out using the ``spack info`` command.

.. code-block:: console
  :emphasize-lines: 54,55

  $ spack info hdf5
  AutotoolsPackage:   hdf5

  Description:
      HDF5 is a data model, library, and file format for storing and managing
      data. It supports an unlimited variety of datatypes, and is designed for
      flexible and efficient I/O and for high volume and complex data.

  Homepage: https://support.hdfgroup.org/HDF5/

  Tags:
      None

  Preferred version:
      1.10.5           https://support.hdfgroup.org/ftp/HDF5/releases/hdf5-1.10/hdf5-1.10.5/src/hdf5-1.10.5.tar.gz

  Safe versions:
      develop          [git] https://bitbucket.hdfgroup.org/scm/hdffv/hdf5.git on branch develop
      1.10.5           https://support.hdfgroup.org/ftp/HDF5/releases/hdf5-1.10/hdf5-1.10.5/src/hdf5-1.10.5.tar.gz
      1.10.4           https://support.hdfgroup.org/ftp/HDF5/releases/hdf5-1.10/hdf5-1.10.4/src/hdf5-1.10.4.tar.gz
      1.10.3           https://support.hdfgroup.org/ftp/HDF5/releases/hdf5-1.10/hdf5-1.10.3/src/hdf5-1.10.3.tar.gz
      1.10.2           https://support.hdfgroup.org/ftp/HDF5/releases/hdf5-1.10/hdf5-1.10.2/src/hdf5-1.10.2.tar.gz
      1.10.1           https://support.hdfgroup.org/ftp/HDF5/releases/hdf5-1.10/hdf5-1.10.1/src/hdf5-1.10.1.tar.gz
      1.10.0-patch1    https://support.hdfgroup.org/ftp/HDF5/releases/hdf5-1.10/hdf5-1.10.0-patch1/src/hdf5-1.10.0-patch1.tar.gz
      1.10.0           https://support.hdfgroup.org/ftp/HDF5/releases/hdf5-1.10/hdf5-1.10.0/src/hdf5-1.10.0.tar.gz
      1.8.21           https://support.hdfgroup.org/ftp/HDF5/releases/hdf5-1.8/hdf5-1.8.21/src/hdf5-1.8.21.tar.gz
      1.8.19           https://support.hdfgroup.org/ftp/HDF5/releases/hdf5-1.8/hdf5-1.8.19/src/hdf5-1.8.19.tar.gz
      1.8.18           https://support.hdfgroup.org/ftp/HDF5/releases/hdf5-1.8/hdf5-1.8.18/src/hdf5-1.8.18.tar.gz
      1.8.17           https://support.hdfgroup.org/ftp/HDF5/releases/hdf5-1.8/hdf5-1.8.17/src/hdf5-1.8.17.tar.gz
      1.8.16           https://support.hdfgroup.org/ftp/HDF5/releases/hdf5-1.8/hdf5-1.8.16/src/hdf5-1.8.16.tar.gz
      1.8.15           https://support.hdfgroup.org/ftp/HDF5/releases/hdf5-1.8/hdf5-1.8.15/src/hdf5-1.8.15.tar.gz
      1.8.14           https://support.hdfgroup.org/ftp/HDF5/releases/hdf5-1.8/hdf5-1.8.14/src/hdf5-1.8.14.tar.gz
      1.8.13           https://support.hdfgroup.org/ftp/HDF5/releases/hdf5-1.8/hdf5-1.8.13/src/hdf5-1.8.13.tar.gz
      1.8.12           https://support.hdfgroup.org/ftp/HDF5/releases/hdf5-1.8/hdf5-1.8.12/src/hdf5-1.8.12.tar.gz
      1.8.10           https://support.hdfgroup.org/ftp/HDF5/releases/hdf5-1.8/hdf5-1.8.10/src/hdf5-1.8.10.tar.gz

  Variants:
      Name [Default]      Allowed values    Description


      cxx [off]           True, False       Enable C++ support
      debug [off]         True, False       Builds a debug version of the
                                            library
      fortran [off]       True, False       Enable Fortran support
      hl [off]            True, False       Enable the high-level library
      mpi [on]            True, False       Enable MPI support
      pic [on]            True, False       Produce position-independent
                                            code (for shared libs)
      shared [on]         True, False       Builds a shared version of the
                                            library
      szip [off]          True, False       Enable szip support
      threadsafe [off]    True, False       Enable thread-safe
                                            capabilities

  Installation Phases:
      autoreconf    configure    build    install

  Build Dependencies:
      autoconf  automake  libtool  m4  mpi  szip  zlib

  Link Dependencies:
      mpi  szip  zlib

  Run Dependencies:
      None

  Virtual Packages:
      None

We will tell Spack to stop installing HDF5 after the ``configure``
stage. This will execute exactly the same as before, except it will
stop the installation after the listed, in our case ``configure``,
phase completes.

.. code-block:: console

  $ spack dev-build --until configure hdf5@develop +hl ~mpi

Now, we can develop our code. For the sake of this demo, we're just
going to intentionally introduce an error. Let's edit a file and
remove the first semi-colon we find.

.. code-block:: console

  $ $EDITOR src/H5D.c

To build our code, we have a couple options. We could use `spack
dev-build` and the `-u` option to configure and build our code, but
we've already configured our code, and the changes we made don't
affect the build system. Instead, let's run our build system directly
-- we are developers of this code now after all. The first thing we
need to do is activate Spack's build environment for our code:

.. code-block:: console

  $ spack build-env hdf5@develop +hl ~mpi -- bash
  $ make
  Making all in src
  ...
  H5D.c:55:32: error: expected ';' after top level declarator
  hbool_t H5_PKG_INIT_VAR = FALSE
                                 ^
                                 ;
  1 error generated.
  make[2]: *** [H5D.lo] Error 1
  make[1]: *** [all] Error 2
  make: *** [all-recursive] Error 1

This is exactly what we'd expect, since we broke the code on
purpose. Now let's fix it and rebuild directly.

.. code-block:: console

  $ $EDITOR src/H5D.c
  $ make
  Making all in src
  ...
  make[3]: Nothing to be done for `all-am'.
  make[2]: Nothing to be done for `all-am'.

We've now used Spack to install all of our dependencies and configure
our code, but we can have a faster development cycle using our build
system directly.

-------------------
Workflow Summary
-------------------

Use the ``spack dev-build`` command with the ``-u/--until`` option and
the ``spack build-env`` command to setup all your dependencies with
Spack and iterate using your native build system as Spack would use it.
