.. Copyright 2013-2023 Lawrence Livermore National Security, LLC and other
   Spack Project Developers. See the top-level COPYRIGHT file for details.

   SPDX-License-Identifier: (Apache-2.0 OR MIT)

.. include:: common/setup.rst

.. _developer-workflows-tutorial:

============================
Developer Workflows Tutorial
============================

This tutorial will guide you through using the ``spack develop`` command to develop software from local source code within a Spack environment.
With this command, Spack manages your dependencies while you focus on testing changes to your library and/or application.

-----------------------------
Installing from Local Source
-----------------------------

The ``spack install`` command typically fetches source code from a mirror or the internet before building and installing your package.
As developers, however, we often want to build from local source code that we continuously modify, build, and test.

Let's imagine we're working on ``scr``—a library used to implement scalable checkpointing in application codes.
It supports fast, efficient checkpoint read/write operations using MPI and high-bandwidth file I/O.
We want to test changes to ``scr`` within an actual application, so we'll use ``macsio``, a proxy application that mimics typical HPC I/O workloads.

We've chosen ``scr`` and ``macsio`` because they are both quick to build.

We'll begin by creating a Spack environment for our development work.
We need to build ``macsio`` with ``scr`` support, and for now, we want everything built without Fortran support.
Let's set up this development workflow:

.. literalinclude:: outputs/dev/setup-scr.out
   :language: console

Before making any changes, we verify that everything builds correctly.
Spack builds the entire development tree as specified and links all components together for you.


.. literalinclude:: outputs/dev/setup-scr.out
   :language: console


Before making any changes, we verify that everything builds correctly.
Spack builds the entire development tree as specified and links all components together for you.


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

"wbqbc5vw5sxzwhvu56p6x5nd5n4abrvh" -> "jdxbjftheiotj6solpomva7dowrhlerl" "zqwfzhw5k2ollygh6nrjpsi7u4d4g6lu" -> "4sh6pymrm2ms4auu3ajbjjr6fiuhz5g7" "sz72vygmht66khd5aa4kihz5alg4nrbm" -> "vfrf7asfclt7epufnoxibfqbkntbk5k3" "vfrf7asfclt7epufnoxibfqbkntbk5k3" -> "t54jzdy2jj4snltjazlm3br2urcilc6v" "crhlefo3dv7lmsv5pf4icsy4gepkdorm" -> "4sh6pymrm2ms4auu3ajbjjr6fiuhz5g7" "7tkgwjvu2mi4ea2wsdetunq7g4k4r2nh" -> "mkc3u4x2p2wie6jfhuku7g5rkovcrxps" "sz72vygmht66khd5aa4kihz5alg4nrbm" -> "pmsyupw6w3gql4loaor25gfumlmvkl25" "zqwfzhw5k2ollygh6nrjpsi7u4d4g6lu" -> "wbqbc5vw5sxzwhvu56p6x5nd5n4abrvh" "7tkgwjvu2mi4ea2wsdetunq7g4k4r2nh" -> "d2krmb5gweivlnztcymhklzsqbrpatt6" "es377uqsqougfc67jyg7yfjyyuukin52" -> "smoyzzo2qhzpn6mg6rd3l2p7b23enshg" "bltycqwh5oofai4f6o42q4uuj4w5zb3j" -> "crhlefo3dv7lmsv5pf4icsy4gepkdorm" "mm33a3ocsv3jsh2tfxc4mlab4xsurtdd" -> "zfdvt2jjuaees43ffrrtphqs2ky3o22t" "es377uqsqougfc67jyg7yfjyyuukin52" -> "zfdvt2jjuaees43ffrrtphqs2ky3o22t" "7tkgwjvu2mi4ea2wsdetunq7g4k4r2nh" -> "jdxbjftheiotj6solpomva7dowrhlerl" "mkc3u4x2p2wie6jfhuku7g5rkovcrxps" -> "lbrx7lnfz46ukewxbhxnucmx76g23c6q" "bltycqwh5oofai4f6o42q4uuj4w5zb3j" -> "es377uqsqougfc67jyg7yfjyyuukin52" "vedchc5aoqyu3ydbp346qrbpe6kg46rq" -> "smoyzzo2qhzpn6mg6rd3l2p7b23enshg" "wbqbc5vw5sxzwhvu56p6x5nd5n4abrvh" -> "d2krmb5gweivlnztcymhklzsqbrpatt6" "zfdvt2jjuaees43ffrrtphqs2ky3o22t" -> "4av4gywgpaspkhy3dvbb62nulqogtzbb" "vedchc5aoqyu3ydbp346qrbpe6kg46rq" -> "pmsyupw6w3gql4loaor25gfumlmvkl25" "d2krmb5gweivlnztcymhklzsqbrpatt6" -> "mm33a3ocsv3jsh2tfxc4mlab4xsurtdd" "bob4o5m3uku6vtdil5imasprgy775zg7" -> "jdxbjftheiotj6solpomva7dowrhlerl" "yn2r3wfhiilelyulh5toteicdtxjhw7d" -> "komekkmyciga3kl24edjmredhj3uyt7v" "pmsyupw6w3gql4loaor25gfumlmvkl25" -> "smoyzzo2qhzpn6mg6rd3l2p7b23enshg" "wbqbc5vw5sxzwhvu56p6x5nd5n4abrvh" -> "mm33a3ocsv3jsh2tfxc4mlab4xsurtdd" "vfrf7asfclt7epufnoxibfqbkntbk5k3" -> "vedchc5aoqyu3ydbp346qrbpe6kg46rq" "bob4o5m3uku6vtdil5imasprgy775zg7" -> "gs6ag7ktdoiirb62t7bcagjw62szrrg2" "d2krmb5gweivlnztcymhklzsqbrpatt6" -> "zfdvt2jjuaees43ffrrtphqs2ky3o22t" "7tkgwjvu2mi4ea2wsdetunq7g4k4r2nh" -> "mm33a3ocsv3jsh2tfxc4mlab4xsurtdd" "vfrf7asfclt7epufnoxibfqbkntbk5k3" -> "smoyzzo2qhzpn6mg6rd3l2p7b23enshg" "zfdvt2jjuaees43ffrrtphqs2ky3o22t" -> "4ihuiazsglf22f3pntq5hc4kyszqzexn" "bob4o5m3uku6vtdil5imasprgy775zg7" -> "4sh6pymrm2ms4auu3ajbjjr6fiuhz5g7" "vfrf7asfclt7epufnoxibfqbkntbk5k3" -> "pmsyupw6w3gql4loaor25gfumlmvkl25" "zqwfzhw5k2ollygh6nrjpsi7u4d4g6lu" -> "bob4o5m3uku6vtdil5imasprgy775zg7" "yn2r3wfhiilelyulh5toteicdtxjhw7d" -> "jearpk4xci4zc7dkrza4fufaqfkq7rfl" "sz72vygmht66khd5aa4kihz5alg4nrbm" -> "bltycqwh5oofai4f6o42q4uuj4w5zb3j" "pmsyupw6w3gql4loaor25gfumlmvkl25" -> "wbqbc5vw5sxzwhvu56p6x5nd5n4abrvh" "sz72vygmht66khd5aa4kihz5alg4nrbm" -> "7tkgwjvu2mi4ea2wsdetunq7g4k4r2nh" "yn2r3wfhiilelyulh5toteicdtxjhw7d" -> "smoyzzo2qhzpn6mg6rd3l2p7b23enshg" "t54jzdy2jj4snltjazlm3br2urcilc6v" -> "crhlefo3dv7lmsv5pf4icsy4gepkdorm" "pmsyupw6w3gql4loaor25gfumlmvkl25" -> "zqwfzhw5k2ollygh6nrjpsi7u4d4g6lu" "4av4gywgpaspkhy3dvbb62nulqogtzbb" -> "t54jzdy2jj4snltjazlm3br2urcilc6v" "jdxbjftheiotj6solpomva7dowrhlerl" -> "mkc3u4x2p2wie6jfhuku7g5rkovcrxps" "yn2r3wfhiilelyulh5toteicdtxjhw7d" -> "4sh6pymrm2ms4auu3ajbjjr6fiuhz5g7" "mm33a3ocsv3jsh2tfxc4mlab4xsurtdd" -> "mkc3u4x2p2wie6jfhuku7g5rkovcrxps" "zqwfzhw5k2ollygh6nrjpsi7u4d4g6lu" -> "yn2r3wfhiilelyulh5toteicdtxjhw7d" "pmsyupw6w3gql4loaor25gfumlmvkl25" -> "4sh6pymrm2ms4auu3ajbjjr6fiuhz5g7" "wbqbc5vw5sxzwhvu56p6x5nd5n4abrvh" -> "mkc3u4x2p2wie6jfhuku7g5rkovcrxps" }

Now we are ready to begin work on the actual application.

Now we are ready to begin work on the actual application.

-----------------------------
Development Iteration Cycle
-----------------------------

Let's assume that ``scr`` has a bug, and we'd like to patch it to find out what the problem is.
First, we tell Spack that we want to check out the version of ``scr`` we intend to work on.
In this case, it's the 3.1.0 release that we want to patch:

.. literalinclude:: outputs/dev/develop-1.out
   :language: console

The ``spack develop`` command marks the package as a "development" package in the ``spack.yaml``.
This adds a special ``dev_path=`` attribute to the spec for the package, so Spack remembers where the source code is located.
The ``develop`` command also downloads or checks out the source code for the package.
By default, the source code is downloaded into a subdirectory of the environment.
You can change the location of this source directory by modifying the ``path:`` attribute of the ``develop`` configuration in the environment.

There are a few gotchas with the ``spack develop`` command:

* You often need to specify the package version manually when marking a package as a development package.  
  Spack requires this version so it can supply the correct flags for the package's build system.  
  If no version is supplied, Spack uses the highest version defined in the package—where `infinity versions <https://spack.readthedocs.io/en/latest/packaging_guide.html#version-comparison>`_ like ``develop`` and ``main`` rank higher than numeric versions.

* You must ensure that a spec for the package you are developing appears in the DAG of at least one of the environment's roots, using the same version that you are developing.  
  ``spack add <package>@<version>`` is one way to ensure that the ``develop`` spec is satisfied in the ``spack.yaml``.  
  This is necessary because develop specs are not treated as concretization constraints, but rather as criteria for adding the ``dev_path=`` variant to an existing spec.

* You'll need to re-concretize the environment so that the version number and ``dev_path=`` attributes are properly added to the cached spec in ``spack.lock``.

.. literalinclude:: outputs/dev/develop-conc.out
   :language: console

Now that this is done, we tell Spack to rebuild both ``scr`` and ``macsio`` by running ``spack install``.

.. literalinclude:: outputs/dev/develop-2.out
   :language: console

This rebuilds ``scr`` from the subdirectory we specified.
If your package uses CMake, Spack will build it in a directory corresponding to the hash of your package.
From there, you can change into the appropriate directory and perform your own build/test cycles.

Now we can develop our code.
For the sake of this demo, we're going to intentionally introduce an error.
Let’s edit a file and remove the first semicolon we find.

.. literalinclude:: outputs/dev/edit-1.out
   :language: console

Once you have a development package, ``spack install`` works like ``make``.
Because Spack knows the source code directory of the package, it checks file timestamps to detect recent changes.
If any files have been modified, Spack will rebuild ``scr`` and its dependents.

.. literalinclude:: outputs/dev/develop-3.out
   :language: console

Here, the build failed as expected.
We can inspect the build output in ``scr/spack-build-out.txt``.
Alternatively, to debug interactively, we can launch a shell within the build environment using:

``spack build-env scr@2.0 -- bash``

If that’s too much to remember, sourcing ``scr/spack-build-env.txt`` will set the appropriate environment variables so you can diagnose the build manually.
Now let's fix the issue and rebuild directly.

.. literalinclude:: outputs/dev/develop-4.out
   :language: console

You'll notice that Spack rebuilt both ``scr`` and ``macsio``, as expected.

Taking advantage of iterative builds with Spack requires cooperation from your build system.
When Spack performs a rebuild on a development package, it reruns all the build stages without cleaning the source and build directories to a pristine state.
If your build system can reuse previously compiled object files, you’ll benefit from an iterative build.

- If your package uses ``make``, you should get iterative builds automatically when using ``spack develop``.
- If your package uses CMake with the standard ``cmake`` / ``build`` / ``install`` stages, you'll also get iterative builds automatically.  
  This is because CMake doesn’t modify the file time of ``CMakeCache.txt`` unless your CMake flags change.
- If your package uses Autoconf, rerunning the typical ``autoreconf`` stage will usually modify the timestamp of ``config.h``, which may trigger a full rebuild.

Multiple packages can also be marked as development packages.
If we were co-developing ``macsio``, we could run:

.. literalinclude:: outputs/dev/develop-5.out
   :language: console

Using development workflows also allows us to share our full development setup with other team members.
They can simply use our ``spack.yaml`` to create a new environment and replicate the entire build process.
For example, here we create another development environment:

.. literalinclude:: outputs/dev/otherdevel.out
   :language: console

In this case, running ``spack develop`` with no arguments will check out or download the source code and place it in the correct directories.

When we're done developing, we simply tell Spack that it no longer needs to keep a development version of the package:

.. literalinclude:: outputs/dev/wrapup.out
   :language: console

-------------------
Workflow Summary
-------------------

Use the ``spack develop`` command within an environment to create a reproducible build setup for your development workflow.
Spack will manage all dependencies and link your packages together automatically.
Within a development environment, ``spack install`` behaves similarly to ``make``: it checks file timestamps and rebuilds only the minimum set of Spack packages required to reflect your changes.

-------------------
Optional: Tips and Tricks
-------------------

This section covers additional features that complement the core tutorial above.
Many of these tips are especially useful for specific projects and developer workflows.

A list of available options for the ``spack develop`` command can be viewed below:

.. code-block:: console

   $ spack develop --help


Source Code Management
----------------------

The ``spack develop`` command allows users to control the location of source code.
By default, Spack manages source locations and handles cloning automatically, but software developers often prefer more control.

You can specify the source directory using the ``--path`` argument when invoking ``spack develop``.
If the specified directory already exists, Spack will not attempt to fetch the source code.
This allows developers to pre-clone repositories or use preferred directory paths as needed.

.. code-block:: console

   # pre-clone the source code and then point spack develop to it
   # note that we can clone into any repo/branch combination desired
   $ git clone https://github.com/llnl/scr.git $SPACK_ENV/code
   # note that with `--path` the code directory and package name can be different
   $ spack develop --path $SPACK_ENV/code scr@3.1.0
   $ spack concretize -f

Navigation and the Build Environment
------------------------------------

Diving into the build environment was introduced earlier in the packaging section using the ``spack build-env scr -- bash`` command.
This is a helpful feature because it allows you to run commands inside the package’s build environment.

In the packaging section, this was combined with ``spack cd`` to demonstrate a manual build process outside of Spack’s automated workflow.
This approach is especially useful in developer environments, providing a streamlined workflow for iterating on a single package without the overhead of the ``spack install`` command.

The extra features of the ``spack install`` command are often unnecessary when rapidly iterating between building and testing a specific package.

For example, the development workflow for modifying ``scr`` that we just covered can be simplified as follows:


 .. code-block:: console

    $ spack build-env scr -- bash
    # Shell wrappers didn't propagate to the subshell
    $ source $SPACK_ROOT/share/spack/setup-env.sh
    # Lets look at navigation features
    $ spack cd --help
    $ spack cd -c scr
    $ touch src/scr_copy.c
    $ spack cd -b scr
    # Lets look at whats here
    $ ls
    # Build and run tests
    $ make -j2
    $ make test
    $ exit


Working directly within the build environment, combined with Spack's navigation features, provides a powerful way to iterate quickly and navigate through Spack’s hash-heavy directory structures.

Combinatorics
-------------

The final topic in this tutorial highlights the power of combinatorial development builds.
There are many cases where developers want to see how a single set of changes affects multiple build configurations—for example: ``+cuda`` vs ``~cuda``, ``%gcc`` vs ``%clang``, or ``build_type=Release`` vs ``build_type=Debug``.

Developers can build all of these configurations with a single ``spack install`` call, as long as the develop spec is generic enough to cover the spec variations of the packages.

.. code-block:: console

   # First we have to allow repeat specs in the environment
   $ spack config add concretizer:unify:false
   # Next we need to specify the specs we want ('==' propagates the variant to deps)
   $ spack change macsio build_type==Release
   $ spack add macsio+scr build_type==Debug
   # Inspect the graph for multiple dev_path=
   $ spack concretize -f

While we won't build out this example, it illustrates how the ``dev_path`` for both ``build_type=Release`` and ``build_type=Debug`` points to the same source code.

If we want to do most of our incremental builds using the ``Release`` configuration and periodically check results using the ``Debug`` build, we can combine the workflow from the previous example: First, enter the ``Release`` build environment using:

``spack build-env scr build_type=Release -- bash``

Then, navigate to the build directory with:

``spack cd -b scr build_type=Release``

Note that since there are two ``scr`` specs in the environment, we must disambiguate which one we want when using these commands.

When we're ready to check our changes in the ``Debug`` build, we can exit the build environment subshell, rerun ``spack install`` to rebuild everything, and then inspect the debug build using our preferred method.
