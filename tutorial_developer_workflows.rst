.. Copyright Spack Project Developers. See COPYRIGHT file for details.

   SPDX-License-Identifier: (Apache-2.0 OR MIT)

.. include:: common/setup.rst

.. _developer-workflows-tutorial:

============================
Developer Workflows Tutorial
============================

This tutorial will guide you through the process of using the ``spack develop`` command to work from local source code within a Spack environment.
In this workflow, Spack uses a local source tree when you run ``spack install``, while continuing to manage the dependencies and build environment for your library or application.


-----------------------------
Installing from local source
-----------------------------

The ``spack install`` command, as you know, normally fetches source code from a mirror or the internet before building and installing a package.
In a development workflow, we instead want to change the source locally and have Spack rebuild the package and any affected dependents.

Let's imagine that we're working on ``scr``.
``scr`` is a library for scalable checkpointing in HPC applications.
It supports writing and reading checkpoints efficiently using MPI and high-bandwidth file I/O.
We'd like to test changes to ``scr`` within an actual application, so we'll use ``macsio``, a proxy application designed to mimic typical HPC I/O workloads.

Let's start by making an environment for our development.
We'll need to build ``macsio`` with ``scr`` support, and we'd like everything to be built without Fortran support for the time being.
Let's set up that development workflow.

.. literalinclude:: outputs/dev/setup-scr.out
   :language: console

Before we do any work, let's verify that this environment builds successfully.
Spack ends up building the entire development tree below, and links everything together for us.


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

Now we are ready to begin modifying ``scr`` and ``macsio``.

-----------------------------
Development iteration cycles
-----------------------------

Let's assume that ``scr`` has a bug that we want to investigate.
First, we'll tell Spack to develop the version of ``scr`` used in our environment.
In this case, we want to modify the 2.0.0 release:

.. literalinclude:: outputs/dev/develop-1.out
   :language: spec

The ``spack develop`` command marks a package for development based on the supplied develop spec.
Develop specs are listed in their own ``develop`` section in ``spack.yaml``.
Spack uses this information as follows:

1. Specs in the environment that ``satisfy`` the develop specs are selected for development.
2. Any specs selected in step 1 receive a ``dev_path=`` variant.
   This variant tells Spack where to find the source code for the spec.
   Adding the variant modifies the DAG hash of the spec and all of its downstream dependencies.
3. Calls to ``spack install`` will now use the source code at ``dev_path`` when building that package.
4. Spack doesn't clean this build up after a successful build so subsequent calls to ``spack install`` trigger incremental builds.

If the environment is already concretized, ``spack develop`` performs steps 1 and 2 in place and updates ``spack.lock`` by default.
If the environment is not yet concretized, Spack selects the develop specs and assigns ``dev_path`` during concretization.

So how does Spack determine the value of the ``dev_path`` variant?
By default, Spack downloads the source code into a subdirectory of the environment.
You can change this location by setting the ``path:`` attribute in the develop configuration or by passing ``--path`` to ``spack develop``.

Now that our develop config is set up, we'll tell Spack to rebuild both ``scr`` and ``macsio`` by running ``spack install``.

.. literalinclude:: outputs/dev/develop-2.out
   :language: console

This rebuilds ``scr`` using the source code from the subdirectory we specified.

Now let's start making changes.
For the sake of this demo, we'll intentionally introduce an error by editing a file and removing the first semicolon we find.

.. literalinclude:: outputs/dev/edit-1.out
   :language: console

Once you have a development package, ``spack install`` works much like ``make``.
Since Spack knows the package's source directory, it checks the file times to see whether any files have changed.
If they have, Spack rebuilds ``scr`` and any packages that depend on it.

.. literalinclude:: outputs/dev/develop-3.out
   :language: console

Here, the build failed as expected after removing that semicolon.
If we didn't know what had caused the build to fail we could inspect ``scr/build-linux-*/spack-build-out.txt`` to find out why.
The ``build-linux-*`` directory inside the source tree is a symlink generated by Spack to the spec's stage directory, where all the logs are stored.
You can find its full name with ``spack location --stage scr`` or navigate to it with ``spack cd --stage scr``.
We can also launch a shell with the appropriate environment variables by running ``spack build-env scr -- bash``.
If that's too much to remember, sourcing ``scr/build-linux-*/spack-build-env.txt`` sets the same environment variables for manual debugging.
Now let's fix the error and rebuild.

.. literalinclude:: outputs/dev/develop-4.out
   :language: console

You'll notice here that Spack rebuilt both ``scr`` and ``macsio``, as expected.

Taking advantage of iterative builds with Spack requires support from your build system.
When Spack rebuilds a development package, it reruns the build stages without cleaning the source and build directories back to a pristine state.
If your build system can reuse previously compiled object files, you will get an iterative build, like ``make``.

- If your package uses CMake with the typical ``cmake`` / ``build`` / ``install`` build stages, you'll get iterative builds for free with Spack because CMake doesn’t modify the filetime on the ``CMakeCache.txt`` file if your cmake flags haven't changed.
- If your package uses autoconf, then rerunning the typical ``autoreconf`` stage typically modifies the filetime of ``config.h``, which can trigger a cascade of rebuilding.

Multi-package development
-------------------------

You may have noticed that ``macsio`` is restaged and fully rebuilt each time we run ``spack install``.
Usually, developers do not want to fully rebuild the application every time, either for performance or because they are co-developing both packages.
Spack does not limit how many packages can be developed, so ``spack develop`` can be applied to any spec in the environment, including ``macsio``.
The ``--recursive`` option provides a convenient way to mark all downstream dependents as develop specs.


.. literalinclude:: outputs/dev/develop-5.out
   :language: console

``spack develop --recursive`` can only be used with a concrete environment.
When called, Spack traces the graph from the supplied develop spec to every root that transitively depends on the develop package.
This can be especially useful when developing applications deep in the dependency graph.
In this case, our development point is already close to the root spec, so we could have called ``spack develop macsio`` and gotten the same result.

Pre-configuring development environments
----------------------------------------

So far, all of our calls to ``spack develop`` have been in a concretized environment, and we have allowed Spack to update the build specs automatically.
If we do not want Spack to update the concrete environment's specs, we can pass ``--no-modify-concrete-spec``.
Using ``--no-modify-concrete-spec`` requires you to force concretize the environment before the develop specs take effect.

There are a limited number of cases where you might want to use this option.
For example:

- Updating a develop spec before updating the environment to change a variant or version
- Adding a develop spec that is not yet in the environment
- Debugging unexpected behavior

For illustration, we will switch ``scr`` to a debug build using the ``build_type=Debug`` variant.

.. literalinclude:: outputs/dev/develop-6.out
   :language: console

We can see that naively updating the develop spec first results in an error and then in an undesired version change.
To preserve the version and add the new variant, we run the following commands:

.. literalinclude:: outputs/dev/develop-7.out
   :language: console

Here are a few additional points to keep in mind when using ``spack develop``:

* ``spack add <package>`` with the matching version you want to develop is a way to ensure the develop spec is satisfied in the ``spack.yaml`` environment file.
* If the spec is not already concrete in the environment, you need to provide Spack with a spec version so it can supply the correct flags for the package's build system.
* If a version is not supplied or detectable in the environment, then Spack falls back to the maximum version defined in the package, where `infinity versions <https://spack.readthedocs.io/en/latest/packaging_guide_creation.html#version-comparison>`_ like ``develop`` and ``main`` have a higher value than numeric versions.
* The source code located at the spec's ``dev_path`` is the user's responsibility to manage.
  Spack does provide an initial clone of the source code, but it makes no guarantees or additional verification of the source beyond that.
  Users can manage the code locally via a version control system like ``git``, or they can trigger a re-stage by calling ``spack develop --force``.


Sharing development environments
--------------------------------

Development workflows also let us share our full development process with another developer on the team.
They can take our ``spack.yaml``, create a new environment, and use it to replicate our build process.
For example, we'll create another development environment here.

.. literalinclude:: outputs/dev/otherdevel.out
   :language: console

Here, ``spack develop`` with no arguments checks out or downloads the source code and places it in the appropriate locations.

When we're done developing, we tell Spack that it no longer needs to keep a development version of the package.

.. literalinclude:: outputs/dev/wrapup.out
   :language: console

----------------
Workflow Summary
----------------

Use ``spack develop`` with an environment to create a reproducible build environment for your development workflow.
Spack sets up all the dependencies for you and links your packages together.
Within a development environment, ``spack install`` works similarly to ``make`` by checking file times and rebuilding the minimum number of Spack packages needed to reflect your changes.

-------------------------
Optional: Tips and Tricks
-------------------------

This section covers some additional features that build on the core tutorial above.
Many of these are especially useful for specific projects and development workflows.
A list of options for ``spack develop`` is shown below:

.. code-block:: console

   $ spack develop --help

Source Code Management
----------------------

``spack develop`` lets users control source code locations.
By default, Spack manages the source location and cloning operations, but developers often want more control over them.

You can set the source directory with the ``--path`` argument when calling ``spack develop``.
If this directory already exists, ``spack develop`` will not attempt to fetch the code for you.
This allows developers to pre-clone the software or use whichever paths they prefer.

.. code-block:: console

   # pre-clone the source code and then point spack develop to it
   # note that we can clone into any repo/branch combination desired
   $ git clone https://github.com/llnl/scr.git $SPACK_ENV/code
   # note that with `--path` the code directory and package name can be different
   $ spack develop --path $SPACK_ENV/code scr@3.1.0
   $ spack concretize -f

Navigation and the Build Environment
------------------------------------

We introduced the build environment earlier in the packaging section with the ``spack build-env scr -- bash`` command.
This is useful because it allows you to run commands inside the build environment.
In the packaging section, we combined it with ``spack cd`` to produce a manual build outside Spack's automated process.
This command is particularly useful in development environments because it streamlines iteration on a single package without the overhead of ``spack install``.
Those additional features are often unnecessary when you are iterating tightly between building and testing a particular package.
For example, the workflow for modifying ``scr`` that we just went through can be simplified to:

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

Working in the build environment together with Spack's navigation features provides a convenient way to iterate quickly and move through Spack's hash-heavy directory structure.

Combinatorics
-------------

The final topic in this tutorial is combinatoric development builds.
There are many cases where developers want to see how a single set of changes affects multiple builds, for example ``+cuda`` vs.
``~cuda``, ``%gcc`` vs.
``%clang``, or ``build_type=Release`` vs.
``build_type=Debug``.

Developers can build both cases from a single ``spack install`` as long as the develop spec is general enough to cover the package spec variations.

.. code-block:: spec

   # First we have to allow repeat specs in the environment
   $ spack config add concretizer:unify:false
   # Next we need to specify the specs we want ('==' propagates the variant to deps)
   $ spack change macsio build_type==Release
   $ spack add macsio+scr build_type==Debug
   # Inspect the graph for multiple dev_path=
   $ spack concretize -f

While we will not work through this example, it illustrates how the ``dev_path`` for ``build_type=Release`` and ``build_type=Debug`` points to the same source code.

If we want to do most of our incremental builds with the ``Release`` build and periodically check the results with the ``Debug`` build, we can combine the workflow from the previous example.
We can enter the ``Release`` build environment using ``spack build-env scr build_type=Release -- bash`` and navigate with ``spack cd -b scr build_type=Release``.
Note that since there are two ``scr`` specs in the environment, we must distinguish which one we want for these commands.
When we are ready to check our changes in the debug build, we can exit the build environment subshell, rerun ``spack install`` to rebuild everything, and then inspect the debug build using our preferred method.
