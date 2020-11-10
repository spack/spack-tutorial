.. Copyright 2013-2020 Lawrence Livermore National Security, LLC and other
   Spack Project Developers. See the top-level COPYRIGHT file for details.

   SPDX-License-Identifier: (Apache-2.0 OR MIT)

.. include:: common/setup.rst

.. _developer-workflows-tutorial:

============================
Developer Workflows Tutorial
============================

This tutorial will guide you through the process of using the `spack
dev-build` command to manage dependencies while developing
software. This will allow you to install a package from local source,
develop that source code, and iterate on the different phases of your
build system as necessary.

-----------------------------
Installing from local source
-----------------------------

The `spack install` command, as you know, fetches source code from a
mirror or the internet before building and installing your package. As
developers, we want to build from local source, which we will
constantly change, build, and test.

Let's imagine for a second we're working on `hwloc`.  `hwloc` is a tool used
by MPI libraries to understand the hierarchy (NUMA, sockets, etc.) of modern
node architectures.  It's a pretty low-level library, but we've chosen it as an
example here because it's quick to build, and we already have binary
packages for its dependencies:

.. graphviz::

    digraph G {
    labelloc = "b"
    rankdir = "TB"
    ranksep = "1"
    edge[
       penwidth=4  ]
    node[
       fontname=Monaco,
       penwidth=4,
       fontsize=24,
       margin=.2,
       shape=box,
       fillcolor=lightblue,
       style="rounded,filled"  ]

    "hwloc" -> "libxml2"
    "libxml2" -> "xz"
    "automake" -> "perl"
    "libxml2" -> "pkgconf"
    "autoconf" -> "perl"
    "libpciaccess" -> "libtool"
    "hwloc" -> "pkgconf"
    "libpciaccess" -> "util-macros"
    "autoconf" -> "m4"
    "hwloc" -> "m4"
    "hwloc" -> "automake"
    "automake" -> "autoconf"
    "hwloc" -> "libtool"
    "libpciaccess" -> "pkgconf"
    "ncurses" -> "pkgconf"
    "libxml2" -> "libiconv"
    "perl" -> "gdbm"
    "hwloc" -> "libpciaccess"
    "gdbm" -> "readline"
    "libtool" -> "m4"
    "hwloc" -> "autoconf"
    "m4" -> "libsigsegv"
    "readline" -> "ncurses"
    "libxml2" -> "zlib"
  }

.. literalinclude:: outputs/dev/setup-hwloc.out
   :language: console


Here we have the local `hwloc` source that we've been working on. If we
want to build and install it, we can do so using the ``spack
dev-build`` command. Note that we need to provide a version in the
spec we pass to ``spack dev-build``. By default, the ``spack
dev-build`` command will print verbose output from the build system to
the console.

.. literalinclude:: outputs/dev/dev-build-1.out
   :language: console

Done! `hwloc` is installed.

So what's going on here? When we use the `spack dev-build` command,
Spack still manages the package's dependencies as it would for the
``spack install`` command. The dependencies for `hwloc` are all
installed, either from binary or source, if they were not
already. Instead of downloading the source code for `hwloc`, Spack
constructed a stage in the current directory to use the local
source. Spack then constructed the build environment and arguments for
the `hwloc` build system as it would for the ``spack install``
command. The resulting installation is added to Spack's database as
usual, and post-install hooks including modulefile generation are ran
as well.

-----------------------------
Development iteration cycles
-----------------------------

Generally, as developers, we only want to configure our package once,
and then we want to iterate developing and building our code, before
installing it once if at all. We can do this in Spack using the
``-u/--until`` option with the ``spack dev-build`` command. To do this
we need to know the phases of the build that Spack will
use. Fortunately, as experienced `hwloc` developers we all happen to know
that those phases are ``autoreconf``, ``configure``, ``build``, and
``install``. If we don't remember the phases, we could find out using
the ``spack info`` command.

.. literalinclude:: outputs/dev/info.out
   :language: console


We will tell Spack to stop installing `hwloc` after the ``configure``
stage. This will execute exactly the same as before, except it will
stop the installation after the listed, in our case ``configure``,
phase completes. We will also tell Spack to launch a subshell in the
build environment, so that we can use the ``hwloc`` build system
manually as Spack would use it.

.. literalinclude:: outputs/dev/dev-build-2.out
   :language: console


Now, we can develop our code. For the sake of this demo, we're just
going to intentionally introduce an error. Let's edit a file and
remove the first semi-colon we find.

.. literalinclude:: outputs/dev/edit-1.out
   :language: console


To build our code, we have a couple options. We could use `spack
dev-build` and the `-u` option to configure and build our code, but
we've already configured our code, and the changes we made don't
affect the build system. Instead, let's run our build system directly
-- we are developers of this code now, after all. If you forgot the
`--drop-in` option above, you can use ``spack build-env hwloc@master
-- bash`` to launch it now.

.. literalinclude:: outputs/dev/hand-build-1.out
   :language: console


This is exactly what we'd expect, since we broke the code on
purpose. Now let's fix it and rebuild directly.

.. literalinclude:: outputs/dev/hand-build-2.out
   :language: console


We've now used Spack to install all of our dependencies and configure
our code, but we can have a faster development cycle using our build
system directly.

-------------------
Workflow Summary
-------------------

Use the ``spack dev-build`` command with the ``-u/--until`` and
``--drop-in`` options to setup all of your dependencies and the build
environment with Spack, and iterate using your native build system as
Spack would use it.
