.. Copyright 2013-2019 Lawrence Livermore National Security, LLC and other
   Spack Project Developers. See the top-level COPYRIGHT file for details.

   SPDX-License-Identifier: (Apache-2.0 OR MIT)

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
Prepare for the tutorial
-----------------------------

If you have already done the :ref:`basics-tutorial` you have probably
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

    "eifxmpsduqbsvgrk2sx5pn7cy5eraanr" [label="pkgconf"]
    "surdjxdcankv3xqk5tnnwroz3tor77o7" [label="gdbm"]
    "hzwkvqampr3c6mfceyxq4xej7eyxoxoj" [label="readline"]
    "vhehc322oo5ipbbk465m6py6zzr4kdam" [label="libpciaccess"]
    "3khohgmwhbgvxehlt7rcnnzqfxelyv4p" [label="libsigsegv"]
    "ut64la6rptcwos3uwl2kp5mle572hlhi" [label="m4"]
    "qk6frrw75e7r5wp7f5r65x23cxtv5p4i" [label="hwloc"]
    "g23qfulbkb5qtgmpuwyv65o3p2r7w434" [label="autoconf"]
    "s4rsiori6blknfxf2jx4nbfxfzvcww2k" [label="ncurses"]
    "4neu5jwwmuo26mjs6363q6bupczjk6hk" [label="libtool"]
    "ur2jffeua3gzg5otnmqgfnfdexgtjxcl" [label="xz"]
    "o2viq7yriiaw6nwqpaa7ltpyzqkaonhb" [label="zlib"]
    "fg5evg4bxx4jy3paclojb46lok4fjclf" [label="libxml2"]
    "a226ran4thxadofd7yow3sfng3gy3t3k" [label="util-macros"]
    "io3tplo73zw2v5lkbknnvsk7tszjaj2d" [label="automake"]
    "zvmmgjbnfrzbo3hl2ijqxcjpkiv7q3ab" [label="libiconv"]
    "cxcj6eisjsfp3iv6xlio6rvc33fbxfmc" [label="perl"]

    "qk6frrw75e7r5wp7f5r65x23cxtv5p4i" -> "fg5evg4bxx4jy3paclojb46lok4fjclf"
    "fg5evg4bxx4jy3paclojb46lok4fjclf" -> "ur2jffeua3gzg5otnmqgfnfdexgtjxcl"
    "io3tplo73zw2v5lkbknnvsk7tszjaj2d" -> "cxcj6eisjsfp3iv6xlio6rvc33fbxfmc"
    "fg5evg4bxx4jy3paclojb46lok4fjclf" -> "eifxmpsduqbsvgrk2sx5pn7cy5eraanr"
    "g23qfulbkb5qtgmpuwyv65o3p2r7w434" -> "cxcj6eisjsfp3iv6xlio6rvc33fbxfmc"
    "vhehc322oo5ipbbk465m6py6zzr4kdam" -> "4neu5jwwmuo26mjs6363q6bupczjk6hk"
    "qk6frrw75e7r5wp7f5r65x23cxtv5p4i" -> "eifxmpsduqbsvgrk2sx5pn7cy5eraanr"
    "vhehc322oo5ipbbk465m6py6zzr4kdam" -> "a226ran4thxadofd7yow3sfng3gy3t3k"
    "g23qfulbkb5qtgmpuwyv65o3p2r7w434" -> "ut64la6rptcwos3uwl2kp5mle572hlhi"
    "qk6frrw75e7r5wp7f5r65x23cxtv5p4i" -> "ut64la6rptcwos3uwl2kp5mle572hlhi"
    "qk6frrw75e7r5wp7f5r65x23cxtv5p4i" -> "io3tplo73zw2v5lkbknnvsk7tszjaj2d"
    "io3tplo73zw2v5lkbknnvsk7tszjaj2d" -> "g23qfulbkb5qtgmpuwyv65o3p2r7w434"
    "qk6frrw75e7r5wp7f5r65x23cxtv5p4i" -> "4neu5jwwmuo26mjs6363q6bupczjk6hk"
    "vhehc322oo5ipbbk465m6py6zzr4kdam" -> "eifxmpsduqbsvgrk2sx5pn7cy5eraanr"
    "s4rsiori6blknfxf2jx4nbfxfzvcww2k" -> "eifxmpsduqbsvgrk2sx5pn7cy5eraanr"
    "fg5evg4bxx4jy3paclojb46lok4fjclf" -> "zvmmgjbnfrzbo3hl2ijqxcjpkiv7q3ab"
    "cxcj6eisjsfp3iv6xlio6rvc33fbxfmc" -> "surdjxdcankv3xqk5tnnwroz3tor77o7"
    "qk6frrw75e7r5wp7f5r65x23cxtv5p4i" -> "vhehc322oo5ipbbk465m6py6zzr4kdam"
    "surdjxdcankv3xqk5tnnwroz3tor77o7" -> "hzwkvqampr3c6mfceyxq4xej7eyxoxoj"
    "4neu5jwwmuo26mjs6363q6bupczjk6hk" -> "ut64la6rptcwos3uwl2kp5mle572hlhi"
    "qk6frrw75e7r5wp7f5r65x23cxtv5p4i" -> "g23qfulbkb5qtgmpuwyv65o3p2r7w434"
    "ut64la6rptcwos3uwl2kp5mle572hlhi" -> "3khohgmwhbgvxehlt7rcnnzqfxelyv4p"
    "hzwkvqampr3c6mfceyxq4xej7eyxoxoj" -> "s4rsiori6blknfxf2jx4nbfxfzvcww2k"
    "fg5evg4bxx4jy3paclojb46lok4fjclf" -> "o2viq7yriiaw6nwqpaa7ltpyzqkaonhb"
  }

.. code-block:: console

  $ cd ~
  $ git clone https://github.com/open-mpi/hwloc.git
  $ cd hwloc

Here we have the local `hwloc` source that we've been working on. If we
want to build and install it, we can do so using the ``spack
dev-build`` command. Note that we need to provide a version in the
spec we pass to ``spack dev-build``. By default, the ``spack
dev-build`` command will print verbose output from the build system to
the console.

.. code-block:: console

  $ spack dev-build hwloc@master
  ...
  ==> Installing hwloc
  ==> Searching for binary cache of hwloc
  ==> Finding buildcaches in /mirror/build_cache
  ==> No binary for hwloc found: installing from source
  ==> No need to fetch for DIY.
  ==> No checksum needed for DIY.
  ==> Sources for DIY stages are not cached
  ==> Using source directory: /home/spack/hwloc
  ==> No patches needed for hwloc
  ==> Building hwloc [AutotoolsPackage]
  ==> Executing phase: 'autoreconf'
  ==> Executing phase: 'configure'
  ==> [2019-11-14-15:57:44.921343] '/home/spack/hwloc/configure' '--prefix=/home/spack/spack/opt/spack/linux-ubuntu18.04-x86_64/gcc-7.4.0/hwloc-master-qk6frrw75e7r5wp7f5r65x23cxtv5p4i' '--disable-opencl' '--enable-netloc' '--disable-cairo' '--disable-nvml' '--disable-gl' '--disable-cuda' '--enable-libxml2' '--enable-pci' '--enable-shared'

  ###
  ### Configuring hwloc distribution tarball
  ### Startup tests
  ###
  checking build system type... x86_64-pc-linux-gnu
  checking host system type... x86_64-pc-linux-gnu
  checking target system type... x86_64-pc-linux-gnu
  checking for a BSD-compatible install... /usr/bin/install -c
  checking whether build environment is sane... yes

  ...

  ==> Successfully installed hwloc
  Fetch: 0.00s.  Build: 55.16s.  Total: 55.16s.
  [+] /home/spack/spack/opt/spack/linux-ubuntu18.04-x86_64/gcc-7.4.0/hwloc-master-qk6frrw75e7r5wp7f5r65x23cxtv5p4i

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

.. code-block:: console
  :emphasize-lines: 56,57

  $ spack info hwloc
  AutotoolsPackage:   hwloc

  Description:
      The Hardware Locality (hwloc) software project. The Portable Hardware
      Locality (hwloc) software package provides a portable abstraction
      (across OS, versions, architectures, ...) of the hierarchical topology
      of modern architectures, including NUMA memory nodes, sockets, shared
      caches, cores and simultaneous multithreading. It also gathers various
      system attributes such as cache and memory information as well as the
      locality of I/O devices such as network interfaces, InfiniBand HCAs or
      GPUs. It primarily aims at helping applications with gathering
      information about modern computing hardware so as to exploit it
      accordingly and efficiently.

  Homepage: http://www.open-mpi.org/projects/hwloc/

  Tags:
      None

  Preferred version:
      2.0.2      http://www.open-mpi.org/software/hwloc/v2.0/downloads/hwloc-2.0.2.tar.gz

  Safe versions:
      master    [git] https://github.com/open-mpi/hwloc.git on branch master
      2.0.2      http://www.open-mpi.org/software/hwloc/v2.0/downloads/hwloc-2.0.2.tar.gz
      2.0.1      http://www.open-mpi.org/software/hwloc/v2.0/downloads/hwloc-2.0.1.tar.gz
      2.0.0      http://www.open-mpi.org/software/hwloc/v2.0/downloads/hwloc-2.0.0.tar.gz
      1.11.11    http://www.open-mpi.org/software/hwloc/v1.11/downloads/hwloc-1.11.11.tar.gz
      1.11.10    http://www.open-mpi.org/software/hwloc/v1.11/downloads/hwloc-1.11.10.tar.gz
      1.11.9     http://www.open-mpi.org/software/hwloc/v1.11/downloads/hwloc-1.11.9.tar.gz
      1.11.8     http://www.open-mpi.org/software/hwloc/v1.11/downloads/hwloc-1.11.8.tar.gz
      1.11.7     http://www.open-mpi.org/software/hwloc/v1.11/downloads/hwloc-1.11.7.tar.gz
      1.11.6     http://www.open-mpi.org/software/hwloc/v1.11/downloads/hwloc-1.11.6.tar.gz
      1.11.5     http://www.open-mpi.org/software/hwloc/v1.11/downloads/hwloc-1.11.5.tar.gz
      1.11.4     http://www.open-mpi.org/software/hwloc/v1.11/downloads/hwloc-1.11.4.tar.gz
      1.11.3     http://www.open-mpi.org/software/hwloc/v1.11/downloads/hwloc-1.11.3.tar.gz
      1.11.2     http://www.open-mpi.org/software/hwloc/v1.11/downloads/hwloc-1.11.2.tar.gz
      1.11.1     http://www.open-mpi.org/software/hwloc/v1.11/downloads/hwloc-1.11.1.tar.gz
      1.9        http://www.open-mpi.org/software/hwloc/v1.9/downloads/hwloc-1.9.tar.gz

  Variants:
      Name [Default]    Allowed values    Description


      cairo [off]       True, False       Enable the Cairo back-end of
                                          hwloc's lstopo command
      cuda [off]        True, False       Support CUDA devices
      gl [off]          True, False       Support GL device discovery
      libxml2 [on]      True, False       Build with libxml2
      nvml [off]        True, False       Support NVML device discovery
      pci [on]          True, False       Support analyzing devices on
                                          PCI bus
      shared [on]       True, False       Build shared libraries

  Installation Phases:
      autoreconf    configure    build    install

  Build Dependencies:
      autoconf  automake  cairo  cuda  gl  libpciaccess  libtool  libxml2  m4  numactl  pkgconfig

  Link Dependencies:
      cairo  cuda  gl  libpciaccess  libxml2  numactl

  Run Dependencies:
      None

  Virtual Packages:
      None

We will tell Spack to stop installing `hwloc` after the ``configure``
stage. This will execute exactly the same as before, except it will
stop the installation after the listed, in our case ``configure``,
phase completes.

.. code-block:: console

  $ spack dev-build --until configure hwloc@master

Now, we can develop our code. For the sake of this demo, we're just
going to intentionally introduce an error. Let's edit a file and
remove the first semi-colon we find.

.. code-block:: console

  $ $EDITOR hwloc/base64.c

To build our code, we have a couple options. We could use `spack
dev-build` and the `-u` option to configure and build our code, but
we've already configured our code, and the changes we made don't
affect the build system. Instead, let's run our build system directly
-- we are developers of this code now, after all. The first thing we
need to do is activate Spack's build environment for our code:

.. code-block:: console

  $ spack build-env hwloc@master -- bash
  $ make
  Making all in include
  make[1]: Entering directory '/home/spack/hwloc/include'
  make[1]: Nothing to be done for 'all'.
  make[1]: Leaving directory '/home/spack/hwloc/include'
  Making all in hwloc
  make[1]: Entering directory '/home/spack/hwloc/hwloc'
    CC       base64.lo
  base64.c:64:1: error: expected ',' or ';' before 'static'
   static const char Pad64 = '=';
   ^~~~~~
  base64.c: In function 'hwloc_encode_to_base64':
  base64.c:176:27: error: 'Pad64' undeclared (first use in this function); did you mean 'Base64'?
      target[datalength++] = Pad64;
                             ^~~~~
                             Base64
  base64.c:176:27: note: each undeclared identifier is reported only once for each function it appears in
  base64.c: In function 'hwloc_decode_from_base64':
  base64.c:207:13: error: 'Pad64' undeclared (first use in this function); did you mean 'Base64'?
     if (ch == Pad64)
               ^~~~~
               Base64
  Makefile:924: recipe for target 'base64.lo' failed
  make[1]: *** [base64.lo] Error 1
  make[1]: Leaving directory '/home/spack/hwloc/hwloc'
  Makefile:686: recipe for target 'all-recursive' failed
  make: *** [all-recursive] Error 1

This is exactly what we'd expect, since we broke the code on
purpose. Now let's fix it and rebuild directly.

.. code-block:: console

  $ $EDITOR hwloc/base64.c
  $ make
  Making all in include
  make[1]: Entering directory '/home/spack/hwloc/include'
  ...
  make[1]: Leaving directory '/home/spack/hwloc/doc'
  make[1]: Entering directory '/home/spack/hwloc'
  make[1]: Nothing to be done for 'all-am'.

We've now used Spack to install all of our dependencies and configure
our code, but we can have a faster development cycle using our build
system directly.

-------------------
Workflow Summary
-------------------

Use the ``spack dev-build`` command with the ``-u/--until`` option and
the ``spack build-env`` command to setup all your dependencies with
Spack and iterate using your native build system as Spack would use it.
