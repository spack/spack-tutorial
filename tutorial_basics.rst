.. Copyright Spack Project Developers. See COPYRIGHT file for details.

   SPDX-License-Identifier: (Apache-2.0 OR MIT)

.. _basics-tutorial:

=========================================
Basic Installation Tutorial
=========================================

This tutorial will provide a step-by-step guide for installing software with Spack.

A few fundamental ideas underpin everything that follows:

1. Spack builds software either from source or from prebuilt binaries.
2. Spack keeps every configuration of a package isolated from every other, so many versions, compilers, and build options can coexist on the same machine.
3. Each configuration is identified by a hash of its full provenance.
4. Spack reuses an existing build whenever it can, instead of rebuilding from scratch.

Keep these points in mind, as we'll illustrate them with examples.

We will begin by introducing the ``spack install`` command, highlighting the versatility of Spack’s spec syntax and the flexibility it offers users.
Next, we will demonstrate how to use the ``spack find`` command to view installed packages, as well as the ``spack uninstall`` command to remove them.

Additionally, we will discuss how Spack manages compilers, with a particular focus on using Spack-built compilers within the Spack environment.
Throughout the tutorial, we will present complete command outputs; however, we will often emphasize only the most relevant sections or simply confirm successful execution.
All examples and outputs are based on an Ubuntu 26.04 Docker image.

.. _basics-tutorial-install:

----------------
Installing Spack
----------------

Spack is ready to use immediately after installation.
To get started, we simply clone the Spack repository and check out the latest v1.2 release:

.. literalinclude:: outputs/basics/clone.out
   :language: console

Next, we'll add Spack to our path.
Spack has some nice command line integration tools, so instead of simply prepending to our ``PATH`` variable, we'll source the Spack setup script.

.. code-block:: console

  $ . share/spack/setup-env.sh

And now we're good to go!

-----------------
What is in Spack?
-----------------

The ``spack list`` command shows available packages.

.. literalinclude:: outputs/basics/list.out
   :language: console
   :lines: 1-6


The ``spack list`` command can also take a query string.
Spack automatically adds wildcards to both ends of the string, or we can add our own wildcards for more advanced searches.
For example, let's view all available Python packages.

.. literalinclude:: outputs/basics/list-py.out
   :language: console
   :lines: 1-6

-------------------
Installing Packages
-------------------

Installing a package is as simple as typing ``spack install`` followed by its name:

.. code-block:: console

  $ spack install <package_name>

Let's install ``gmake``:

.. literalinclude:: outputs/basics/gmake.out
   :language: spec

In the output, the ``[e]`` marker denotes a package that was found on the system rather than built by Spack.
Spack's output lists ``gmake``, ``gcc``, ``gcc-runtime``, ``glibc``, and ``compiler-wrapper``:

* ``gmake`` is the package we requested.
* ``gcc`` is the compiler used to build ``gmake``, which needs a C compiler.
* The ``gcc-runtime`` and ``glibc`` packages are records of the compiler runtime Spack used, which it tracks to keep those components consistent across a build.
* ``compiler-wrapper`` is a wrapper Spack uses to inject the right include, library, and RPATH flags when it invokes the compiler.

**In Spack a compiler is an ordinary dependency rather than a special case**, so ``gmake`` depends on one just as it depends on anything else.
Spack automatically searches your ``PATH`` for installed compilers, so the ones already on the system are ready to use.
Run ``spack compiler list`` (or simply ``spack compilers``) to see the ones it found:

.. literalinclude:: outputs/basics/compiler-list.out
   :language: console

All compilers Spack found are configured as *external packages*.
We'll cover externals in the "Spack Concepts" slides and in the :ref:`Configuration Tutorial <configs-tutorial>` later on.

**Spack can install software either from source or from a binary cache.**
We just built ``gmake`` from source.
To speed up the rest of the tutorial, let's add a binary cache:

.. Its packages are signed with GPG, so enabling it takes two steps: telling Spack where the cache lives and trusting the key the binaries were signed with.

.. literalinclude:: outputs/basics/mirror.out
   :language: console

From here on, the same ``spack install`` command will fetch a package from the cache when a matching binary exists and fall back to building from source when it doesn't.

---------------
The Spec Syntax
---------------

So far we've installed packages with their default configuration.
Spack's *spec syntax* is the interface by which we can request specific configurations of a package.
A *spec* describes a package together with any constraints we want to place on how it is built: its version, its build options, the compiler it uses, and even the configuration of its dependencies.
We express each kind of constraint with its own sigil -- ``@`` for versions, ``+`` and ``~`` for variants, ``%`` for direct dependencies such as compilers, and ``^`` for dependencies anywhere in the graph.
The subsections below introduce these one at a time, building up from a bare package name to fully constrained dependency graphs.

^^^^^^^^
Versions
^^^^^^^^

We can install multiple versions of the same package side by side.
Before installing a specific version, let's check which versions of ``zlib-ng`` are available using the ``spack versions`` command.

.. literalinclude:: outputs/basics/versions-zlib.out
   :language: spec

The ``@`` sigil is used to specify versions.

.. literalinclude:: outputs/basics/zlib-2.0.7.out
   :language: spec

^^^^^^^^
Variants
^^^^^^^^

Besides versions, packages expose build options called variants.
Boolean variants are toggled with the ``+`` (enable) and ``~`` or ``-`` (disable) sigils.
There are two sigils for "disable" to avoid conflicts with shell parsing in different situations.
For example, ``zlib-ng`` has an ``ipo`` variant that enables interprocedural optimization, which we turn on with ``+ipo``.

.. literalinclude:: outputs/basics/zlib-ipo.out
   :language: spec

Not every variant is boolean.
Some take a value, which we set with the same ``name=value`` syntax used for compiler flags.
Here we build ``zlib-ng`` in debug mode through its ``build_type`` variant.

.. literalinclude:: outputs/basics/zlib-build-type.out
   :language: spec

The ``ipo`` and ``build_type`` options come from zlib-ng's CMake build system, so requesting either one builds it with CMake rather than its default Autotools build.

^^^^^^^^^^^^^^^^^^^
Direct Dependencies
^^^^^^^^^^^^^^^^^^^

The ``%`` sigil specifies a direct dependency of the package we're installing.
The most common direct dependency is a compiler -- every package built from source needs one -- so that is what we will use ``%`` for first.
So far we've let Spack choose the compiler, building ``zlib-ng`` with GCC just as we did for gmake.
This time we'll install it with ``%clang`` to build it with the clang compiler instead.

.. literalinclude:: outputs/basics/zlib-clang.out
   :language: spec

Notice that this installation is located separately from the previous one.
As described in the overview, this separation is fundamental to how Spack supports multiple configurations and versions of software packages simultaneously.

The spec syntax is recursive -- any syntax we can specify for the "root" package we can also use for a dependency.
For example, because a compiler is just another dependency, we can pin the version Spack builds with:

.. literalinclude:: outputs/basics/zlib-gcc-10.out
   :language: spec

^^^^^^^^^^^^^^^^^^^^^^^
Transitive Dependencies
^^^^^^^^^^^^^^^^^^^^^^^

As we work with more complex packages that have multiple software dependencies, we will see that Spack efficiently reuses existing packages to satisfy dependency requirements.
By default, Spack prioritizes reusing installations that already exist, whether they are stored locally or available from configured remote binary caches.
This approach helps us avoid unnecessary rebuilds of common dependencies, which is especially valuable if we update Spack frequently.

.. literalinclude:: outputs/basics/tcl.out
   :language: spec

Sometimes it is simpler to specify dependencies without caring whether they are direct or transitive dependencies.
To do that, use the ``^`` sigil.
Note that a dependency specified by ``^`` is always applied to the root package, whereas a direct dependency specified by ``%`` is applied to either the root or any intervening dependency specified by ``^``.

.. literalinclude:: outputs/basics/tcl-zlib-clang.out
   :language: spec

We can also refer to packages from the command line by their hash.
Spack generates a unique hash for each spec, reflecting its complete provenance.
Any change to the spec -- such as compiler version, build options, or dependencies -- results in a different hash, and Spack uses these hashes to give every configuration its own installation directory.
Each build of zlib-ng we installed therefore has a distinct hash.
Instead of typing out the entire spec, we can depend on a specific build -- for example our ``zlib-ng %gcc@14`` build -- by using the ``/`` sigil followed by its hash.

Similar to tools like Git, we do not need to enter the entire hash on the command line—just enough digits to uniquely identify the package.
If the prefix we provide matches more than one installed package, Spack will report an error and prompt us to be more specific.

.. literalinclude:: outputs/basics/tcl-zlib-hash.out
   :language: spec

The ``spack find`` command can take a ``-d`` flag, which shows dependency information.
Note that each package has a top-level entry, even if it also appears as a dependency.

.. literalinclude:: outputs/basics/find-ldf.out
   :language: spec

Spack models the dependencies of packages as a directed acyclic graph (DAG).
The ``spack find -d`` command shows the tree representation of that graph, which loses some dependency relationship information.
We can also use the ``spack graph`` command to view the entire DAG as a graph.

.. literalinclude:: outputs/basics/graph-tcl.out
   :language: spec

^^^^^^^^^^^^^^^^^^^^
Virtual Dependencies
^^^^^^^^^^^^^^^^^^^^

Let's move on to a more complicated package.
HDF5 is a good example: it depends on MPI, but ``mpi`` is not an ordinary package.
It is a *virtual package* -- an interface that several real packages provide -- and Spack handles dependencies on such interfaces through "virtual dependencies".

Because HDF5 is more involved than the packages we've installed so far, let's preview the concretized install plan before building, using the ``spack spec`` command (which accepts the same spec syntax as ``spack install``).

.. literalinclude:: outputs/basics/hdf5-spec.out
   :language: spec

With default settings HDF5 builds against OpenMPI, so installing it also brings in an MPI implementation.

.. literalinclude:: outputs/basics/hdf5.out
   :language: spec

HDF5 controls this through a boolean ``mpi`` variant; disabling it with ``~mpi`` drops the MPI dependency entirely.

.. literalinclude:: outputs/basics/hdf5-no-mpi.out
   :language: spec

We might instead want HDF5 built against a *different* MPI implementation.
Actual MPI implementation packages (like ``openmpi``, ``mpich``, ``mvapich2``, etc.) provide the ``mpi`` interface, and any of these providers can be requested to satisfy an MPI dependency.
For example, we can build HDF5 with MPI support provided by MPICH by specifying a dependency on ``mpich`` (e.g., ``hdf5 ^mpich``).
Spack also supports versioning of virtual dependencies.
A package can depend on the MPI interface at version 3 (e.g., ``hdf5 ^mpi@3``), and provider packages specify what version of the interface *they* provide.
The partial spec ``^mpi@3`` can be satisfied by any of several MPI implementation packages that provide MPI version 3.

We've actually already been using virtual packages when we changed compilers earlier.
Compilers are providers for virtual packages like ``c``, ``cxx``, and ``fortran``.
Because these are often provided by the same package but we might want to use C and C++ from one compiler and Fortran from another, we need a syntax to specify which virtual a package provides.
We call this "virtual assignment", and can be specified by ``%virtual=provider`` or ``^virtual=provider``.

For example if we wanted to install hdf5 using GCC for the C and C++ components but Intel OneAPI for the Fortran compiler we could write:

.. code-block:: spec

   hdf5 %c,cxx=gcc %fortran=oneapi

However, we'll keep it simple for now and install HDF5 with MPI support provided by MPICH.
We could use the same syntax for ``^mpi=mpich``, but there's no need because the only way for ``hdf5`` to depend on ``mpich`` is to provide ``mpi``.
This is also why we didn't care to specify which virtuals ``gcc`` and ``clang`` provided earlier when building simpler packages.

.. literalinclude:: outputs/basics/hdf5-hl-mpi.out
   :language: spec

.. note::

   It is frequently sufficient to specify ``%gcc`` even for packages that use multiple languages, because Spack prefers to minimize the number of packages needed for a build.
   Later on we will discuss more complex compiler requests, and how and when they are useful.

We'll do a quick check in on what we have installed so far.

.. literalinclude:: outputs/basics/find-ldf-2.out
   :language: spec

HDF5 is more complicated than our basic example of zlib-ng and Tcl, but it's still within the realm of software that an experienced HPC user could reasonably expect to manually install given a bit of time.
Now let's look at an even more complicated package.

.. literalinclude:: outputs/basics/trilinos.out
   :language: spec

Now we're starting to see the power of Spack.
Depending on the spec, Trilinos can have over 30 direct dependencies, many of which have dependencies of their own.
Installing more complex packages can take days or weeks even for an experienced user.
Although we've done a binary installation for the tutorial, a source installation of Trilinos using Spack takes about 3 hours (depending on the system), but only 20 seconds of programmer time.

Spack manages consistency of the entire DAG.
Every MPI dependency will be satisfied by the same configuration of MPI, etc.
If we install Trilinos again specifying a dependency on our previous HDF5 built with MPICH:

.. literalinclude:: outputs/basics/trilinos-hdf5.out
   :language: spec

We see that every package in the Trilinos DAG that depends on MPI now uses MPICH.

.. literalinclude:: outputs/basics/find-d-trilinos.out
   :language: spec

As we discussed before, the ``spack find -d`` command shows the dependency information as a tree.
While that is often sufficient, many complicated packages, including Trilinos, have dependencies that cannot be fully represented as a tree.
Again, the ``spack graph`` command shows the full DAG of the dependency information.

.. literalinclude:: outputs/basics/graph-trilinos.out
   :language: spec

You can control how the output is displayed with a number of options.

The ASCII output from ``spack graph`` can be difficult to parse for complicated packages.
The output can be changed to the Graphviz ``.dot`` format using the ``--dot`` flag.

.. code-block:: console

  $ spack graph --dot trilinos | dot -Tpdf > trilinos_graph.pdf

^^^^^^^^^^^^^^
Compiler Flags
^^^^^^^^^^^^^^

As an aside, the spec syntax can also set compiler flags directly on a build.
Spack accepts ``cppflags``, ``cflags``, ``cxxflags``, ``fflags``, ``ldflags``, and ``ldlibs`` -- written like ``cflags="-O3"`` -- and its compiler wrappers inject them into the appropriate compilation commands (values containing spaces must be quoted on the command line).
This is an escape hatch for special cases rather than the usual way to configure a build: most of the time a package's variants and build system already select appropriate options, so reach for explicit flags only when you genuinely need them.

.. _basics-tutorial-query:

----------------------
Querying Installations
----------------------

Now that we have installed a variety of packages, we can use the ``spack find`` command to query which packages are installed.

.. literalinclude:: outputs/basics/find.out
   :language: spec

Notice that by default, some installed packages appear identical in the output.
To help distinguish between them, we can add the ``-l`` flag to display each package's unique hash.

.. literalinclude:: outputs/basics/find-lf.out
   :language: spec

As we saw when referring to builds by hash, every installed package has a distinct hash, so configurations that look alike in the default output still occupy separate installations.

The ``spack find`` command can also accept what we call "anonymous specs": expressions in spec syntax that do not contain a package name.
For example, ``spack find ^mpich`` will return every installed package that depends on MPICH.

.. literalinclude:: outputs/basics/find-dep-mpich.out
   :language: spec

The ``find`` command can show which packages were installed explicitly (rather than pulled in as a dependency) using the lowercase ``-x`` flag; the uppercase ``-X`` flag shows implicit installs only.
It can also show the path to which a package was installed using the ``-p`` flag.

.. literalinclude:: outputs/basics/find-px.out
   :language: spec

.. _basics-tutorial-uninstall:

---------------------
Uninstalling Packages
---------------------

Earlier we installed many configurations each of zlib-ng and Tcl.
Now we will go through and uninstall some of those packages that we didn't really need.

.. literalinclude:: outputs/basics/find-d-tcl.out
   :language: spec

.. literalinclude:: outputs/basics/find-zlib.out
   :language: spec

We can uninstall packages by spec using the same syntax as install.

.. literalinclude:: outputs/basics/uninstall-zlib.out
   :language: spec

.. literalinclude:: outputs/basics/find-lf-zlib.out
   :language: spec

We can also uninstall packages by referring only to their hash.

We can use either the ``--force`` (or ``-f``) flag or the ``--dependents`` (or ``-R``) flag to remove packages that are required by another installed package.
Use ``--force`` to remove just the specified package, leaving dependents broken.
Use ``--dependents`` to remove the specified package and all of its dependents.

.. literalinclude:: outputs/basics/uninstall-needed.out
   :language: spec

.. literalinclude:: outputs/basics/uninstall-r-needed.out
   :language: spec

Spack will not uninstall packages that are not sufficiently specified (i.e., if the spec is ambiguous and matches multiple installed packages).
The ``--all`` (or ``-a``) flag can be used to uninstall all packages matching an ambiguous spec.

.. literalinclude:: outputs/basics/uninstall-ambiguous.out
   :language: spec

.. literalinclude:: outputs/basics/uninstall-specific.out
   :language: spec

---------------------
Customizing Compilers
---------------------

Spack manages a list of available compilers on the system, detected automatically from the user's ``PATH`` variable.
The ``spack compilers`` command is an alias for ``spack compiler list``.

.. literalinclude:: outputs/basics/compilers.out
   :language: console

These compilers are maintained in a YAML file.
Later in the tutorial we will discuss how to configure external compilers by hand for special cases.
Spack can also use compilers built by Spack to compile later packages.

.. literalinclude:: outputs/basics/install-gcc-16.out
   :language: spec

.. literalinclude:: outputs/basics/compilers-2.out
   :language: spec

Now ``gcc@16`` is immediately available to use.

.. literalinclude:: outputs/basics/spec-zziplib.out
   :language: spec

For the rest of the tutorial we will sometimes use this new compiler, and sometimes we want to demonstrate things without it.
For now, we will uninstall it to avoid using it in the next section.

.. literalinclude:: outputs/basics/compiler-uninstall.out
   :language: spec

.. note::

   The spec syntax may be confusing for new users.
   Spack can provide information about commands you run frequently.
   For instance, see the output of ``spack help --spec``:

   .. literalinclude:: outputs/basics/help-spec.out
      :language: console
