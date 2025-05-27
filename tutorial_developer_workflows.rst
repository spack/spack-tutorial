.. Copyright 2013-2023 Lawrence Livermore National Security, LLC and other
   Spack Project Developers. See the top-level COPYRIGHT file for details.

   SPDX-License-Identifier: (Apache-2.0 OR MIT)

.. include:: common/setup.rst

.. _developer-workflows-tutorial:

============================
Developer Workflows Tutorial
============================

This tutorial will guide you through the process of using the ``spack
develop`` command to develop software from local source code within a
Spack environment. With this command, Spack will manage your
dependencies while you focus on testing changes to your library and/or
application.


-----------------------------
Installing from local source
-----------------------------

The ``spack install`` command, as you know, fetches source code from a
mirror or the internet before building and installing your package. As
developers, we want to build from local source, which we will
constantly change, build, and test.

Let's imagine for this tutorial we're working on ``scr``. ``scr`` is a
library used to implement scalable checkpointing in application
codes. It supports writing/reading checkpoints quickly and efficiently
using MPI and high-bandwidth file I/O. We'd like to test changes to
``scr`` within an actual application, so we'll test with ``macsio``, a
proxy application written to mimic typical HPC I/O workloads. We've
chosen ``scr`` and ``macsio`` because together they are quick to
build.

We'll start by making an environment for our development. We need to
build ``macsio`` with ``scr`` support, and we'd like everything to be
built without Fortran support for the time being. Let's set up that
development workflow.

.. literalinclude:: outputs/dev/setup-scr.out
   :language: console

Before we do any work, we verify that this all builds.  Spack ends up
building the entire development tree below, and links everything
together for you.


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

      "4sh6pymrm2ms4auu3ajbjjr6fiuhz5g7" [label="pkgconf"]
      "7tkgwjvu2mi4ea2wsdetunq7g4k4r2nh" [label="json-cwx"]
      "4ihuiazsglf22f3pntq5hc4kyszqzexn" [label="berkeley-db"]
      "jearpk4xci4zc7dkrza4fufaqfkq7rfl" [label="libiconv"]
      "d2krmb5gweivlnztcymhklzsqbrpatt6" [label="automake"]
      "gs6ag7ktdoiirb62t7bcagjw62szrrg2" [label="util-macros"]
      "yn2r3wfhiilelyulh5toteicdtxjhw7d" [label="libxml2"]
      "lbrx7lnfz46ukewxbhxnucmx76g23c6q" [label="libsigsegv"]
      "bob4o5m3uku6vtdil5imasprgy775zg7" [label="libpciaccess"]
      "pmsyupw6w3gql4loaor25gfumlmvkl25" [label="openmpi"]
      "mkc3u4x2p2wie6jfhuku7g5rkovcrxps" [label="m4"]
      "jdxbjftheiotj6solpomva7dowrhlerl" [label="libtool"]
      "mm33a3ocsv3jsh2tfxc4mlab4xsurtdd" [label="autoconf"]
      "zfdvt2jjuaees43ffrrtphqs2ky3o22t" [label="perl"]
      "t54jzdy2jj4snltjazlm3br2urcilc6v" [label="readline"]
      "4av4gywgpaspkhy3dvbb62nulqogtzbb" [label="gdbm"]
      "crhlefo3dv7lmsv5pf4icsy4gepkdorm" [label="ncurses"]
      "bltycqwh5oofai4f6o42q4uuj4w5zb3j" [label="cmake"]
      "zqwfzhw5k2ollygh6nrjpsi7u4d4g6lu" [label="hwloc"]
      "vedchc5aoqyu3ydbp346qrbpe6kg46rq" [label="hdf5"]
      "wbqbc5vw5sxzwhvu56p6x5nd5n4abrvh" [label="numactl"]
      "komekkmyciga3kl24edjmredhj3uyt7v" [label="xz"]
      "es377uqsqougfc67jyg7yfjyyuukin52" [label="openssl"]
      "vfrf7asfclt7epufnoxibfqbkntbk5k3" [label="silo"]
      "smoyzzo2qhzpn6mg6rd3l2p7b23enshg" [label="zlib"]
      "sz72vygmht66khd5aa4kihz5alg4nrbm" [label="macsio"]

      "wbqbc5vw5sxzwhvu56p6x5nd5n4abrvh" -> "jdxbjftheiotj6solpomva7dowrhlerl"
      "zqwfzhw5k2ollygh6nrjpsi7u4d4g6lu" -> "4sh6pymrm2ms4auu3ajbjjr6fiuhz5g7"
      "sz72vygmht66khd5aa4kihz5alg4nrbm" -> "vfrf7asfclt7epufnoxibfqbkntbk5k3"
      "vfrf7asfclt7epufnoxibfqbkntbk5k3" -> "t54jzdy2jj4snltjazlm3br2urcilc6v"
      "crhlefo3dv7lmsv5pf4icsy4gepkdorm" -> "4sh6pymrm2ms4auu3ajbjjr6fiuhz5g7"
      "7tkgwjvu2mi4ea2wsdetunq7g4k4r2nh" -> "mkc3u4x2p2wie6jfhuku7g5rkovcrxps"
      "sz72vygmht66khd5aa4kihz5alg4nrbm" -> "pmsyupw6w3gql4loaor25gfumlmvkl25"
      "zqwfzhw5k2ollygh6nrjpsi7u4d4g6lu" -> "wbqbc5vw5sxzwhvu56p6x5nd5n4abrvh"
      "7tkgwjvu2mi4ea2wsdetunq7g4k4r2nh" -> "d2krmb5gweivlnztcymhklzsqbrpatt6"
      "es377uqsqougfc67jyg7yfjyyuukin52" -> "smoyzzo2qhzpn6mg6rd3l2p7b23enshg"
      "bltycqwh5oofai4f6o42q4uuj4w5zb3j" -> "crhlefo3dv7lmsv5pf4icsy4gepkdorm"
      "mm33a3ocsv3jsh2tfxc4mlab4xsurtdd" -> "zfdvt2jjuaees43ffrrtphqs2ky3o22t"
      "es377uqsqougfc67jyg7yfjyyuukin52" -> "zfdvt2jjuaees43ffrrtphqs2ky3o22t"
      "7tkgwjvu2mi4ea2wsdetunq7g4k4r2nh" -> "jdxbjftheiotj6solpomva7dowrhlerl"
      "mkc3u4x2p2wie6jfhuku7g5rkovcrxps" -> "lbrx7lnfz46ukewxbhxnucmx76g23c6q"
      "bltycqwh5oofai4f6o42q4uuj4w5zb3j" -> "es377uqsqougfc67jyg7yfjyyuukin52"
      "vedchc5aoqyu3ydbp346qrbpe6kg46rq" -> "smoyzzo2qhzpn6mg6rd3l2p7b23enshg"
      "wbqbc5vw5sxzwhvu56p6x5nd5n4abrvh" -> "d2krmb5gweivlnztcymhklzsqbrpatt6"
      "zfdvt2jjuaees43ffrrtphqs2ky3o22t" -> "4av4gywgpaspkhy3dvbb62nulqogtzbb"
      "vedchc5aoqyu3ydbp346qrbpe6kg46rq" -> "pmsyupw6w3gql4loaor25gfumlmvkl25"
      "d2krmb5gweivlnztcymhklzsqbrpatt6" -> "mm33a3ocsv3jsh2tfxc4mlab4xsurtdd"
      "bob4o5m3uku6vtdil5imasprgy775zg7" -> "jdxbjftheiotj6solpomva7dowrhlerl"
      "yn2r3wfhiilelyulh5toteicdtxjhw7d" -> "komekkmyciga3kl24edjmredhj3uyt7v"
      "pmsyupw6w3gql4loaor25gfumlmvkl25" -> "smoyzzo2qhzpn6mg6rd3l2p7b23enshg"
      "wbqbc5vw5sxzwhvu56p6x5nd5n4abrvh" -> "mm33a3ocsv3jsh2tfxc4mlab4xsurtdd"
      "vfrf7asfclt7epufnoxibfqbkntbk5k3" -> "vedchc5aoqyu3ydbp346qrbpe6kg46rq"
      "bob4o5m3uku6vtdil5imasprgy775zg7" -> "gs6ag7ktdoiirb62t7bcagjw62szrrg2"
      "d2krmb5gweivlnztcymhklzsqbrpatt6" -> "zfdvt2jjuaees43ffrrtphqs2ky3o22t"
      "7tkgwjvu2mi4ea2wsdetunq7g4k4r2nh" -> "mm33a3ocsv3jsh2tfxc4mlab4xsurtdd"
      "vfrf7asfclt7epufnoxibfqbkntbk5k3" -> "smoyzzo2qhzpn6mg6rd3l2p7b23enshg"
      "zfdvt2jjuaees43ffrrtphqs2ky3o22t" -> "4ihuiazsglf22f3pntq5hc4kyszqzexn"
      "bob4o5m3uku6vtdil5imasprgy775zg7" -> "4sh6pymrm2ms4auu3ajbjjr6fiuhz5g7"
      "vfrf7asfclt7epufnoxibfqbkntbk5k3" -> "pmsyupw6w3gql4loaor25gfumlmvkl25"
      "zqwfzhw5k2ollygh6nrjpsi7u4d4g6lu" -> "bob4o5m3uku6vtdil5imasprgy775zg7"
      "yn2r3wfhiilelyulh5toteicdtxjhw7d" -> "jearpk4xci4zc7dkrza4fufaqfkq7rfl"
      "sz72vygmht66khd5aa4kihz5alg4nrbm" -> "bltycqwh5oofai4f6o42q4uuj4w5zb3j"
      "pmsyupw6w3gql4loaor25gfumlmvkl25" -> "wbqbc5vw5sxzwhvu56p6x5nd5n4abrvh"
      "sz72vygmht66khd5aa4kihz5alg4nrbm" -> "7tkgwjvu2mi4ea2wsdetunq7g4k4r2nh"
      "yn2r3wfhiilelyulh5toteicdtxjhw7d" -> "smoyzzo2qhzpn6mg6rd3l2p7b23enshg"
      "t54jzdy2jj4snltjazlm3br2urcilc6v" -> "crhlefo3dv7lmsv5pf4icsy4gepkdorm"
      "pmsyupw6w3gql4loaor25gfumlmvkl25" -> "zqwfzhw5k2ollygh6nrjpsi7u4d4g6lu"
      "4av4gywgpaspkhy3dvbb62nulqogtzbb" -> "t54jzdy2jj4snltjazlm3br2urcilc6v"
      "jdxbjftheiotj6solpomva7dowrhlerl" -> "mkc3u4x2p2wie6jfhuku7g5rkovcrxps"
      "yn2r3wfhiilelyulh5toteicdtxjhw7d" -> "4sh6pymrm2ms4auu3ajbjjr6fiuhz5g7"
      "mm33a3ocsv3jsh2tfxc4mlab4xsurtdd" -> "mkc3u4x2p2wie6jfhuku7g5rkovcrxps"
      "zqwfzhw5k2ollygh6nrjpsi7u4d4g6lu" -> "yn2r3wfhiilelyulh5toteicdtxjhw7d"
      "pmsyupw6w3gql4loaor25gfumlmvkl25" -> "4sh6pymrm2ms4auu3ajbjjr6fiuhz5g7"
      "wbqbc5vw5sxzwhvu56p6x5nd5n4abrvh" -> "mkc3u4x2p2wie6jfhuku7g5rkovcrxps"
    }

Now we are ready to begin work on the actual application.

-----------------------------
Development iteration cycles
-----------------------------

Let's assume that scr has a bug, and we'd like to patch scr to find
out what the problem is.  First, we tell spack that we'd like to check
out the version of scr that we want to work on. In this case, it will
be the 3.1.0 release that we want to write a patch for:

.. literalinclude:: outputs/dev/develop-1.out
   :language: console

The ``spack develop`` command marks the package as being a "development"
package in the ``spack.yaml`` file of the current environment. This adds a
special ``dev_path=<path_to_source>`` attribute to the spec for the package in
the environment's ``spack.lock`` file once concretized, so Spack remembers
where the local source code for this package is located. The ``spack develop``
command also downloads or checks out the source code for the package if it's
not already present at the specified path (or default path). By default, if
no path is specified, the source code is placed into a subdirectory within the
environment (e.g., ``./spack-src/scr``). You can specify a custom location for
this source directory using the ``--path`` option with ``spack develop``, or by
modifying the ``path:`` attribute of the develop configuration in the ``spack.yaml``
file.

There are a few important considerations (or "gotchas") when using the ``spack develop`` command:

* You often need to specify the package version manually when marking a
  package for development (e.g., ``spack develop scr@3.1.0``). Spack needs to
  know the version of the development package to correctly apply dependencies
  and flags from its ``package.py`` file. If a version is not supplied, Spack
  will try to infer it, often defaulting to the highest version defined in the
  package file, where `infinity versions <https://spack.readthedocs.io/en/latest/packaging_guide.html#version-comparison>`_
  (like ``@develop`` or ``@main`` if defined in the package) are considered higher
  than numeric versions.
* You must ensure that a spec for the package you are developing (with the
  correct version) exists in the environment's list of root specs (e.g., added via
  ``spack add <package>@<version>``) *before* running ``spack develop``.
  The ``spack develop`` command doesn't add the package to the environment's
  roots; it modifies an *existing* spec in the environment by associating it
  with a local source path. If the package/version isn't already a root spec,
  the ``dev_path`` attribute won't be associated correctly.
* After running ``spack develop`` or changing which packages are in development
  mode, you **must** re-concretize the environment (e.g., ``spack concretize -f``
  or ``spack install`` which triggers concretization). This ensures that the
  ``dev_path=`` attribute is correctly recorded in the ``spack.lock`` file and
  used for subsequent builds.

.. literalinclude:: outputs/dev/develop-conc.out
   :language: console

Now that we have this done, we tell Spack to rebuild both ``scr`` and
``macsio`` by running ``spack install``.

.. literalinclude:: outputs/dev/develop-2.out
   :language: console

This rebuilds ``scr`` from the subdirectory we specified. If your
package uses CMake, Spack will perform an out-of-source build, creating a
build directory typically inside ``<dev_path_to_scr>/.spack-build-<hash>/`` or similar,
depending on the Spack version and package recipe. You can change into
the appropriate build directory and perform your own build/test cycles manually if needed.

Now, we can develop our code. For the sake of this demo, we're just
going to intentionally introduce an error. Let's edit a file and
remove the first semi-colon we find.

.. literalinclude:: outputs/dev/edit-1.out
   :language: console

Once you have a development package, subsequent ``spack install`` calls work somewhat
like ``make``. Since Spack knows the source code directory of the
development package, it checks the timestamps of the files in that directory.
If the source files are newer than the last build time, Spack will
rebuild that package and any other packages in the environment that depend on it.

.. literalinclude:: outputs/dev/develop-3.out
   :language: console

Here, the build failed as expected. We can look at the build log using
``spack build-log scr`` (Spack will show the path to the log file).
Alternatively, to debug interactively, we can launch a shell directly within
the correct build environment using ``spack build-env scr -- bash``.
If you prefer to source the environment script manually, you can dump it first
with ``spack build-env --dump scr > my_scr_build_env.sh`` and then ``source ./my_scr_build_env.sh``.
Now let's fix the error in the source code and rebuild using ``spack install``.

.. literalinclude:: outputs/dev/develop-4.out
   :language: console

You'll notice here that Spack rebuilt both ``scr`` and ``macsio``, as
expected.

Taking advantage of iterative builds with Spack requires cooperation
from your package's build system. When Spack performs a rebuild on a
development package, it typically reruns all the build phases defined in the
Spack package file (e.g., `cmake`, `build`, `install` for `CMakePackage`)
without cleaning the source and build directories to a pristine state. If your
build system can detect unchanged files and avoid recompiling them (e.g.,
via correct `Makefile` dependencies), then you'll achieve an incremental/iterative
build.

- If your package just uses `make` and has a well-structured `Makefile`,
  you should get iterative builds for free when using ``spack develop``.
- If your package uses CMake and follows typical practices, you'll generally
  get iterative builds because CMake and the generated build files (e.g., Makefiles
  or Ninja files) are designed for this. Spack doesn't interfere with CMake's
  own change detection unless CMake flags themselves change.
- If your package uses Autotools, rerunning the `autoreconf` or `configure`
  stages (if Spack deems it necessary due to changes or if the package recipe
  forces it) might modify files like `config.h` or Makefiles, which can
  sometimes trigger more extensive rebuilds than desired.

Multiple packages can also be marked as develop. If we were
co-developing ``macsio``, we could run

.. literalinclude:: outputs/dev/develop-5.out
   :language: console

Using development workflows also lets us ship our whole development
process to another developer on the team. They can simply take our
``spack.yaml`` file, create a new environment from it, and use ``spack develop``
(potentially with ``--path`` pointing to their local checkouts if they differ)
to replicate the build process. For example, we'll make another development
environment here.

.. literalinclude:: outputs/dev/otherdevel.out
   :language: console

Here, ``spack develop`` with no arguments will check out or download
the source code and place it in the appropriate places.

When we're done developing a particular package locally, we can tell Spack
that it no longer needs to use the local development version by using
``spack develop --uninstall <package_name>``. This removes the ``dev_path``
attribute. Remember to re-concretize and reinstall if you want Spack to use a
standard (non-dev) version of the package.

.. literalinclude:: outputs/dev/wrapup.out
   :language: console

-------------------
Workflow Summary
-------------------

Use the ``spack develop`` command within a Spack environment to create a
reproducible build setup for your development workflow. Spack
will manage all the dependencies and link your packages
together. Within such an environment, subsequent ``spack install`` commands
work similarly to ``make`` in that they will check file timestamps to rebuild
the minimum number of Spack packages necessary to reflect changes you've made
to your local source code.

-------------------
Optional: Tips and Tricks
-------------------

This section will cover some additional features that are useful additions
to the core tutorial above. Many of these items are very useful to specific
projects and developers. A list of the options for the ``spack develop`` can
be viewed below:

.. code-block:: console

   $ spack develop --help

Source Code Management
----------

``spack develop`` allows users to manipulate the source code locations
The default behavior is to let Spack manage its location (typically within the
environment directory, e.g., ``./spack-src/<package-name>``) and cloning operations.
However, software developers often want more control.

The source directory can be explicitly set with the ``--path <local_path_to_source>``
argument when calling ``spack develop``. If this directory already exists and
contains source code, Spack will use it and will not attempt to fetch or clone
the code. This allows developers to pre-clone their software (e.g., to a specific
branch or fork) or use preferred project directory structures.

.. code-block:: console

   # Example: pre-clone the source code and then point spack develop to it
   # We'll use a directory relative to our environment for this example.
   # Assume your environment is in 'my-dev-env'.
   $ mkdir -p my-dev-env/local-code
   $ git clone https://github.com/llnl/scr.git my-dev-env/local-code/scr-custom-checkout
   # Activate your environment if not already active
   $ spack env activate ./my-dev-env
   # Add scr to the environment if not already present
   $ spack add scr@3.1.0
   # Now, tell Spack to use the local checkout for scr@3.1.0
   $ spack develop --path local-code/scr-custom-checkout scr@3.1.0
   $ spack concretize -f

Navigation and the Build Environment
----------

Diving into the build environment was introduced previously in the packaging tutorial
with the ``spack build-env <spec> -- bash`` command. This is a helpful feature because
it allows you to run commands interactively inside the build environment that Spack
sets up. In the packaging tutorial, this was combined with ``spack cd`` to demonstrate
a manual build outside of Spack's automated process.
This command is particularly useful in developer environments, offering a streamlined
workflow when iterating on a single package without the full overhead of the ``spack install``
command each time. The dependency management and environment setup features of Spack
are still active, but you gain finer control over the build steps for the package
you are actively developing. For example, the workflow modifying ``scr`` that we
just went through can be simplified for rapid iteration:

 .. code-block:: console

    # Enter the build environment for scr
    $ spack build-env scr -- bash
    # If spack shell integration isn't active in the subshell, you might need to re-source it:
    # $ source $SPACK_ROOT/share/spack/setup-env.sh
    # (Alternatively, spack build-env tries to handle this for you)

    # Navigate to the source directory of scr
    $ spack cd -s scr
    # Make your code changes, e.g., edit src/scr_copy.c
    # $ vim src/scr_copy.c (or your favorite editor)
    # $ touch src/scr_copy.c # Example: simulate a change

    # Navigate to the build directory of scr
    $ spack cd -b scr
    # Let's see what's here
    $ ls
    # Build (e.g., assuming a Makefile-based system for scr)
    $ make -j$(nproc)  # Use available processors
    # Run tests if available
    $ make test
    # When done with this iteration, exit the subshell
    $ exit

Working directly within the build environment, along with Spack navigation features
(``spack cd``), provides a powerful way to iterate quickly and navigate through
the hash-heavy Spack directory structures without repeatedly running ``spack install``.

Combinatorics
------------

The final note we will look at in this tutorial will be the power of combinatorial
development builds. There are many instances where developers want to see how
a single set of local source code changes affects multiple build configurations
(e.g., ``+cuda`` vs ``~cuda``, ``%gcc`` vs ``%clang``, ``build_type=Release`` vs
``build_type=Debug``).

Developers can achieve builds of multiple variants from the same local source using
a single ``spack install`` command, as long as the ``spack develop`` spec
is generic enough (e.g., ``scr`` without specific variants) to apply to all desired
package spec variations in the environment.

.. code-block:: console

   # First, we might need to allow multiple, non-unified versions of packages
   # if we are testing different configurations of the same package.
   # For this example, we assume 'macsio' will have two different specs.
   # If scr itself had different variants we wanted to test from the same dev_path,
   # we would add those variations of scr to the environment.
   $ spack config add concretizer:unify:false  # If testing different versions of 'scr' itself.
                                             # For different 'macsio' using the *same* 'scr' dev version,
                                             # this might not be strictly needed for 'scr' if 'scr' spec is unified.

   # Add two different configurations of macsio, both depending on our dev version of scr.
   # Ensure 'scr' is added to the environment and marked with 'spack develop scr@version'.
   $ spack add macsio build_type=Release ^scr@3.1.0
   $ spack add macsio build_type=Debug   ^scr@3.1.0
   # Mark 'scr' for development (assuming it's already added with the correct version)
   $ spack develop scr@3.1.0

   # Concretize to see the plan. Both macsio specs should point to the same dev_path for scr.
   $ spack concretize -f
   # $ spack spec -l macsio # to see details including dev_paths

This setup illustrates how the ``dev_path`` for ``scr`` can be used by multiple
dependent specs (``macsio build_type=Release`` and ``macsio build_type=Debug``),
both pointing to the same local source code for ``scr``. When you run ``spack install``,
Spack will build both versions of ``macsio``, each linking against the ``scr`` built
from your local development path.

Now, if we want to do most of our incremental builds targeting the ``Release``
configuration of ``macsio`` (which uses our dev ``scr``), and periodically check
the results with the ``Debug`` configuration, we can combine workflows.
For focused iteration on `scr` that primarily affects the `Release` `macsio`:
Dive into the build environment of the `scr` that is a dependency of the `Release` `macsio`.
You might need to be specific if `scr` itself had variants:
``spack build-env scr -- bash`` (if `scr` spec is unambiguous or unified for dev)
or more specifically, find the hash for `scr` under the release `macsio` and use that.
Navigate with ``spack cd -b scr ...``.
When ready to check changes against the `Debug` build of `macsio`, exit any specific
build environment subshell, then run ``spack install``. This will rebuild your
local `scr` (if changed) and then rebuild both `macsio` configurations that depend on it.
You can then inspect or run the `Debug` version of `macsio`.
