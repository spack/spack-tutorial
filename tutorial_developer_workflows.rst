.. Copyright Spack Project Developers. See COPYRIGHT file for details.

   SPDX-License-Identifier: (Apache-2.0 OR MIT)

.. include:: common/setup.rst

.. _developer-workflows-tutorial:

============================
Developer Workflows Tutorial
============================

This tutorial will guide you through the process of using the ``spack develop`` command to develop software from local source code within a Spack environment.
With this command, Spack will manage your dependencies while you focus on testing changes to your library and/or application.


-----------------------------
Installing from local source
-----------------------------

The ``spack install`` command, as you know, fetches source code from a mirror or the internet before building and installing your package.
As developers, we want to build from local source, which we will constantly change, build, and test.

Let's imagine, for a second, we're working on ``scr``.
``scr`` is a library used to implement scalable checkpointing in application codes.
It supports writing/reading checkpoints quickly and efficiently using MPI and high-bandwidth file I/O.
We'd like to test changes to ``scr`` within an actual application, so we'll test with ``macsio``, a proxy application written to mimic typical HPC I/O workloads.
We've chosen ``scr`` and ``macsio`` because together they are quick to build.

We'll start by making an environment for our development.
We need to build ``macsio`` with ``scr`` support, and we'd like everything to be built without Fortran support for the time being.
Let's set up that development workflow.

.. literalinclude:: outputs/dev/setup-scr.out
   :language: console

Before we do any work, we verify that this all builds.
Spack ends up building the entire development tree below, and links everything together for you.


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

Let's assume that ``scr`` has a bug, and we'd like to patch ``scr`` to find out what the problem is.
First, we tell Spack that we'd like to check out the version of ``scr`` in our environment.
In this case, it will be the 3.1.0 release that we want to write a patch for:

.. literalinclude:: outputs/dev/develop-1.out
   :language: spec

The ``spack develop`` command marks the package as being a "development" package based on the supplied ``develop spec``.
Develop specs are listed in their own ``develop`` section inside the ``spack.yaml``.
The mechanics of how this section is used to enforce develpoment are as follows:

1. Specs in the environment that ``satisfy`` the develop specs are selected for development.
2. Any specs selected in step 1 receive a ``dev_path=`` variant.
   This variant tells Spack where to find the source code for the spec.
3. Calls to ``spack install`` will now use the source code at ``dev_path`` when building that package.
4. Spack doesn't clean this build up after a successful build so subsequent calls to ``spack install`` trigger incremental builds.

If the environment is already concretized ``spack develop`` performs step 1 and 2 in situ and updates the ``spack.lock`` file unless the ``--no-modify-concrete-specs`` option is passed.
If ``--no-modify-concrete-specs`` is passed, the environment is not yet concretized, or needs to be futher changed to satisfy the develop specs (i.e. change version of the package) then selection of develop specs and assignment of ``dev_path`` are handled by the concretizer.

So how does Spack determine the value of the ``dev_path`` variant?
By default, the source code is downloaded into a subdirectory of the environment using Spack's staging functionality.
You can change the location of this source directory by modifying the ``path:`` attribute of the develop configuration in the environment or by passing the ``--path`` options when calling ``spack develop``.


.. literalinclude:: outputs/dev/develop-conc.out
   :language: console

Now that we have this done, we tell Spack to rebuild both ``scr`` and ``macsio`` by running ``spack install``.

.. literalinclude:: outputs/dev/develop-2.out
   :language: console

This rebuilds ``scr`` from the subdirectory we specified.
If your package uses CMake, Spack will build the package in a build directory that matches the hash for your package.
From here you can change into the appropriate directory and perform your own build/test cycles.

Now, we can develop our code.
For the sake of this demo, we're just going to intentionally introduce an error.
Let's edit a file and remove the first semi-colon we find.

.. literalinclude:: outputs/dev/edit-1.out
   :language: console

Once you have a development package, ``spack install`` also works much like "make".
Since Spack knows the source code directory of the package, it checks the filetimes on the source directory to see if we've made recent changes.
If the file times are newer, it will rebuild ``scr`` and any other package that depends on ``scr``.

.. literalinclude:: outputs/dev/develop-3.out
   :language: console

Here, the build failed as expected.
We can look at the output for the build in ``scr/spack-build-out.txt`` to find out why, or we can launch a shell directly with the appropriate environment variables to figure out what went wrong by using ``spack build-env scr -- bash``.
If that's too much to remember, then sourcing ``scr/spack-build-env.txt`` will also set all the appropriate environment variables so we can diagnose the build ourselves.
Now let's fix it and rebuild directly.

.. literalinclude:: outputs/dev/develop-4.out
   :language: console

You'll notice here that Spack rebuilt both ``scr`` and ``macsio``, as expected.

Taking advantage of iterative builds with Spack requires cooperation from your build system.
When Spack performs a rebuild on a development package, it reruns all the build stages for your package without cleaning the source and build directories to a pristine state.
If your build system can take advantage of the previously compiled object files then you'll end up with an iterative build.

- If your package just uses make, you also should get iterative builds for free when running ``spack develop``.
- If your package uses CMake with the typical ``cmake`` / ``build`` / ``install`` build stages, you'll get iterative builds for free with Spack because CMake doesn’t modify the filetime on the ``CMakeCache.txt`` file if your cmake flags haven't changed.
- If your package uses autoconf, then rerunning the typical ``autoreconf`` stage typically modifies the filetime of ``config.h``, which can trigger a cascade of rebuilding.

Multi-package development
-------------------------

You may have noticed that ``macsio`` is restaged and fully rebuilt each time we call ``spack install``.
This is an unnecessary expense for cross package development.
Luckily, Spack has tools to reduce this expense.
We will use this as an opportunity to introduce another ``spack develop`` feature: the ``--recursive`` option.

.. literalinclude:: outputs/dev/develop-5.out
   :language: console

``spack develop --recursive`` can only be used with a concrete environment.
When called Spack traces the graph from the supplied develop spec to every root in the graph that transitively depends on the develop package.
Using ``--recursive`` can be very powerful when developing applications deep in a graph.
In this case our development point is very close to the root spec so we could have called ``spack develop macsio`` and gotten the same result.

Pre-configuring development environments
----------------------------------------

So far all of our calls to ``spack develop`` have been on a concretized environment, and we have allowed Spack to automatically update the build specs for us.
If we don't want Spack to update the concrete environment's specs we can pass the ``---no-modify-concrete-spec``.
Using ``---no-modify-concrete-spec`` will require you to force concretize an environment to have the develop specs take affect.

Examples of where we might want to use this feature are:
- The package we wish to develop is repeated in our environment and we need to be more selective.
- We want to mark a develop spec that doesn't exist yet in the environment.

We will show an example of the latter, and how to update the local source if you decide to change the version.
Let's say we plan to extend our environment to develop the ``nekbone`` package.

.. literalinclude:: outputs/dev/develop-6.out
   :language: console

The ``spack develop`` command only has any effect if the developed package appears in the environment, as a root or dependency.
Some additional concerns to use the ``spack develop`` command  effectively:

* ``spack add <package>`` with the matching version you want to develop is a way to ensure the develop spec is satisfied in the ``spack.yaml`` environments file.
* If the spec is not already concrete in the environment, you need to provide Spack a spec version so it can supply the correct flags for the package's build system.
* If a version is not supplied or detectable in the environment, then Spack falls back to the maximum version defined in the package where `infinity versions <https://spack.readthedocs.io/en/latest/packaging_guide_creation.html#version-comparison>`_ like ``develop`` and ``main`` have a higher value than the numeric versions.
* The source code located at the spec's ``dev_path`` is the users responsibility to manage.
  Spack does provide an initial clone of the source code, but it makes no guarantees or additional verification of the source beyond that.
  Users can manage the code locally via a version control system like ``git``, or can trigger a re-stage by calling ``spack develop --force``.


Sharing development environments
--------------------------------

Using development workflows also lets us ship our whole development process to another developer on the team.
They can simply take our ``spack.yaml``, create a new environment, and use this to replicate our build process.
For example, we'll make another development environment here.

.. literalinclude:: outputs/dev/otherdevel.out
   :language: console

Here, ``spack develop`` with no arguments will check out or download the source code and place it in the appropriate places.

When we're done developing, we simply tell Spack that it no longer needs to keep a development version of the package.

.. literalinclude:: outputs/dev/wrapup.out
   :language: console

----------------
Workflow Summary
----------------

Use the ``spack develop`` command with an environment to make a reproducible build environment for your development workflow.
Spack will set up all the dependencies for you and link all your packages together.
Within a development environment, ``spack install`` works similarly to ``make`` in that it will check file times to rebuild the minimum number of Spack packages necessary to reflect the changes to your build.

-------------------------
Optional: Tips and Tricks
-------------------------

This section will cover some additional features that are useful additions to the core tutorial above.
Many of these items are very useful to specific projects and developers.
A list of the options for the ``spack develop`` can be viewed below:

.. code-block:: console

   $ spack develop --help

Source Code Management
----------------------

``spack develop`` allows users to manipulate the source code locations The default behavior is to let Spack manage its location and cloning operations, but software developers often want more control over these.

The source directory can be set with the ``--path`` argument when calling ``spack develop``.
If this directory already exists then ``spack develop`` will not attempt to fetch the code for you.
This allows developers to pre-clone the software or use preferred paths as they wish.

.. code-block:: console

   # pre-clone the source code and then point spack develop to it
   # note that we can clone into any repo/branch combination desired
   $ git clone https://github.com/llnl/scr.git $SPACK_ENV/code
   # note that with `--path` the code directory and package name can be different
   $ spack develop --path $SPACK_ENV/code scr@3.1.0
   $ spack concretize -f

Navigation and the Build Environment
------------------------------------

Diving into the build environment was introduced previously in the packaging section with the ``spack build-env scr -- bash`` command.
This is a helpful function because it allows you to run commands inside the build environment.
In the packages section of the tutorial this was combined with ``spack cd`` to produce a manual build outside of Spack's automated Process.
This command is particularly useful in developer environments—it allows developers a streamlined workflow when iterating on a single package without the overhead of the ``spack install`` command.
The additional features of the install command are unnecessary when tightly iterating between building and testing a particular package.
For example, the workflow modifying ``scr`` that we just went through can be simplified to:

.. code-block:: spec

   $ spack build-env scr -- bash
   # Shell wrappers did not propagate to the subshell
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

Working with the build environment and along with Spack navigation features provides a nice way to iterate quickly and navigate through the hash-heavy Spack directory structures.

Combinatorics
-------------

The final note we will look at in this tutorial will be the power of combinatoric development builds.
There are many instances where developers want to see how a single set of changes affects multiple builds i.e. ``+cuda`` vs ``~cuda``, ``%gcc`` vs ``%clang``, ``build_type=Release`` vs ``build_type=Debug``, etc.

Developers can achieve builds of both cases from a single ``spack install`` as long as the develop spec is generic enough to cover the packages' spec variations

.. code-block:: spec

   # First we have to allow repeat specs in the environment
   $ spack config add concretizer:unify:false
   # Next we need to specify the specs we want ('==' propagates the variant to deps)
   $ spack change macsio build_type==Release
   $ spack add macsio+scr build_type==Debug
   # Inspect the graph for multiple dev_path=
   $ spack concretize -f

While we won't build out this example it illustrates how the ``dev_path`` for ``build_type=Release`` and ``build_type=Debug`` points to the same source code.

Now if we want to do most of our incremental builds using the ``Release`` build and periodically check the results using the ``Debug`` build we can combine the workflow from the previous example: dive into the ``Release`` versions build environment using ``spack build-env scr build_type=Release -- bash`` and navigate with ``spack cd -b scr build_type=Release``.
Note that since there are two ``scr`` specs in the environment we must distinguish which one we want for these commands.
When we are ready to check our changes for the debug build, we can exit out of the build environment subshell, rerun ``spack install`` to rebuild everything, and then inspect the debug build through our method of choice.
