.. Copyright Spack Project Developers. See COPYRIGHT file for details.

   SPDX-License-Identifier: (Apache-2.0 OR MIT)

.. _basics-tutorial:

=========================================
Basic Installation Tutorial
=========================================

This tutorial will provide a step-by-step guide for installing software with Spack.
We will begin by introducing the ``spack install`` command, highlighting the versatility of Spack’s spec syntax and the flexibility it offers users.
Next, we will demonstrate how to use the ``spack find`` command to view installed packages, as well as the ``spack uninstall`` command to remove them.

Additionally, we will discuss how Spack manages compilers, with a particular focus on using Spack-built compilers within the Spack environment.
Throughout the tutorial, we will present complete command outputs; however, we will often emphasize only the most relevant sections or simply confirm successful execution.
All examples and outputs are based on an Ubuntu 22.04 Docker image.

.. _basics-tutorial-install:

----------------
Installing Spack
----------------

Spack is ready to use immediately after installation.
To get started, we simply clone the Spack repository and check out the latest release, v1.0.

.. literalinclude:: outputs/basics/clone.out
   :language: console

Next, we'll add Spack to our path.
Spack has some nice command line integration tools, so instead of simply prepending to our ``PATH`` variable, we'll source the Spack setup script.

.. code-block:: console

  $ . share/spack/setup-env.sh

For this tutorial we'll also pin the packages repository to ``2025.07.0`` to make use of the binary caches later on by running:

.. literalinclude:: outputs/basics/repo.out
   :language: console

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

Installing a package with Spack is very simple.
To install a software package, type:

.. code-block:: console

  $ spack install <package_name>

Let's go ahead and install ``gmake``,

.. literalinclude:: outputs/basics/gmake.out
   :language: spec

You will see Spack installed ``gmake``, ``gcc``, ``gcc-runtime``, and ``glibc``.
The ``glibc`` and ``gcc-runtime`` packages are automatically tracked by Spack to manage consistency requirements among compiler runtimes.
These do not represent separate software builds from source, but are records of the compiler runtime components Spack used for the install.
For the rest of this section, we'll ignore these components and focus on the packages explicitly installed and their listed dependencies.

The ``gcc`` package was found on the system and Spack used it because ``gmake`` requires a compiler to build from source.
Compilers are handled somewhat specially in Spack; Spack searches the ``PATH`` environment variable for compilers automatically.
We can run ``spack compiler list`` or simply ``spack compilers`` to show all the compilers Spack found.

.. literalinclude:: outputs/basics/compiler-list.out
   :language: console

All compilers that Spack found will be configured as external packages -- we'll talk more about externals in the "Spack Concepts" slides and in :ref:`Configuration Tutorial <configs-tutorial>` later on.

Spack can install software either from source or from a binary cache.
Packages in the binary cache are signed with GPG for security.
For this tutorial we have prepared a binary cache so we don't have to wait for slow compilation from source.
To enable installation from the binary cache, we'll need to configure Spack with the location of the cache and trust the GPG key that the binaries were signed with.

.. literalinclude:: outputs/basics/mirror.out
   :language: console

We'll learn more about configuring Spack later in the tutorial, but for now we can install the rest of the packages in the tutorial from the cache using the same ``spack install`` command.
By default, this will install the binary cached version if it exists and fall back to installing the package from source if it does not.

Now that we understand how Spack handles installations, let's explore how we can customize what gets installed.
Spack's "spec" syntax is the interface by which we can request specific configurations of a package.
The ``%`` sigil is used to specify direct dependencies like a package's compiler.
For example, we can install zlib (a commonly used compression library), but instead of building it with the GCC compiler as we did for gmake previously, we'll install it with ``%clang`` to build it with the clang compiler.

.. literalinclude:: outputs/basics/zlib-clang.out
   :language: spec

Notice that this installation is located separately from the previous one.
We'll explore this concept in more detail later, but this separation is fundamental to how Spack supports multiple configurations and versions of software packages simultaneously.

Now that we've seen how Spack handles separate installations, let's explore this capability by installing multiple versions of the same package.
Before we install additional versions, we can check the versions available to us using the ``spack versions`` command.
Let's check what versions of zlib-ng are available, and then we'll install a different version to demonstrate Spack's flexibility in managing multiple package versions.

.. literalinclude:: outputs/basics/versions-zlib.out
   :language: spec

The ``@`` sigil is used to specify versions.

.. literalinclude:: outputs/basics/zlib-2.0.7.out
   :language: spec

The spec syntax is recursive -- any syntax we can specify for the "root" package (``zlib-ng``) we can also use for a dependency.

.. literalinclude:: outputs/basics/zlib-gcc-10.out
   :language: spec

The spec syntax in Spack also supports compiler flags.
We can specify parameters such as ``cppflags``, ``cflags``, ``cxxflags``, ``fflags``, ``ldflags``, and ``ldlibs``.
If any of these values contain spaces, we'll need to enclose them in quotes on the command line.
Spack’s compiler wrappers will automatically inject these flags into the appropriate compilation commands.

.. literalinclude:: outputs/basics/zlib-O3.out
   :language: spec

After installing packages, we can use the ``spack find`` command to query which packages are installed.
Notice that by default, some installed packages appear identical in the output.
To help distinguish between them, we can add the ``-l`` flag to display each package’s unique hash.
Additionally, if we include the ``-f`` flag, Spack will show any non-empty compiler flags that were used during installation.

.. literalinclude:: outputs/basics/find.out
   :language: spec

.. literalinclude:: outputs/basics/find-lf.out
   :language: spec

Spack generates a unique hash for each spec.
This hash reflects the complete provenance of the package, so any change to the spec—such as compiler version, build options, or dependencies—will result in a different hash.
Spack uses these hashes both to compare specs and to create unique installation directories for every possible configuration.

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

We can also refer to packages from the command line by their package hash.
Earlier, when we used the ``spack find -lf`` command, we saw that the hash for our optimized installation of zlib-ng (with ``cflags="-O3"``) began with ``umrbkwv``.
Instead of typing out the entire spec, we can now build explicitly with that package by using the ``/`` sigil followed by its hash.

Similar to tools like Git, we do not need to enter the entire hash on the command line—just enough digits to uniquely identify the package.
If the prefix we provide matches more than one installed package, Spack will report an error and prompt us to be more specific.

.. literalinclude:: outputs/basics/tcl-zlib-hash.out
   :language: spec

The ``spack find`` command can also take a ``-d`` flag, which can show dependency information.
Note that each package has a top-level entry, even if it also appears as a dependency.

.. literalinclude:: outputs/basics/find-ldf.out
   :language: spec

Spack models the dependencies of packages as a directed acyclic graph (DAG).
The ``spack find -d`` command shows the tree representation of that graph, which loses some dependency relationship information.
We can also use the ``spack graph`` command to view the entire DAG as a graph.

.. literalinclude:: outputs/basics/graph-tcl.out
   :language: spec

Let's move on to slightly more complicated packages.
HDF5 is a good example of a more complicated package, with an MPI dependency.
If we install it with default settings it will build with OpenMPI.
We can check the install plan in advance to ensure it's what we want to install using the ``spack spec`` command.
The ``spack spec`` command accepts the same spec syntax.

.. literalinclude:: outputs/basics/hdf5-spec.out
   :language: spec

Assuming we're happy with that configuration, we will now install it.

.. literalinclude:: outputs/basics/hdf5.out
   :language: spec

Spack packages can also have build options, called variants.
Boolean variants can be specified using the ``+`` (enable) and ``~`` or ``-``
(disable) sigils. There are two sigils for "disable" to avoid conflicts
with shell parsing in different situations.
Variants (boolean or otherwise) can also be specified using the same syntax as compiler flags.
Here we can install HDF5 without MPI support.

.. literalinclude:: outputs/basics/hdf5-no-mpi.out
   :language: spec

We might also want to install HDF5 with a different MPI implementation.
While ``mpi`` itself is a virtual package representing an interface, other packages can depend on such abstract interfaces.
Spack handles these through "virtual dependencies." A package, such as HDF5, can depend on the ``mpi`` virtual package (the interface).
Actual MPI implementation packages (like ``openmpi``, ``mpich``, ``mvapich2``, etc.) provide the MPI interface.
Any of these providers can be requested to satisfy an MPI dependency.
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

   It is frequently sufficient to specify ``%gcc`` even for packages
   that use multiple languages, because Spack prefers to minimize the
   number of packages needed for a build. Later on we will discuss
   more complex compiler requests, and how and when they are useful.

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

-----------------------------
Advanced ``spack find`` Usage
-----------------------------

We will go over some additional uses for the ``spack find`` command not already covered in the :ref:`basics-tutorial-install` and
:ref:`basics-tutorial-uninstall` sections.

The ``spack find`` command can accept what we call "anonymous specs." These are expressions in spec syntax that do not contain a package name.
For example, ``spack find ^mpich`` will return every installed package that depends on MPICH, and ``spack find cflags="-O3"`` will return every package which was built with ``cflags="-O3"``.

.. literalinclude:: outputs/basics/find-dep-mpich.out
   :language: spec

.. literalinclude:: outputs/basics/find-O3.out
   :language: spec

The ``find`` command can also show which packages were installed explicitly (rather than pulled in as a dependency) using the lowercase ``-x`` flag.
The uppercase ``-X`` flag shows implicit installs only.
The ``find`` command can also show the path to which a Spack package was installed using the ``-p`` flag.

.. literalinclude:: outputs/basics/find-px.out
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

.. literalinclude:: outputs/basics/install-gcc-12.1.0.out
   :language: spec

.. literalinclude:: outputs/basics/compilers-2.out
   :language: spec

Because this compiler is a newer version than the external compilers Spack knows about, it will be the new default compiler.
We will discuss changing these defaults in a later section.
We can check that this compiler is preferred by looking at the install plan for a package that isn't being reused from binary.

.. literalinclude:: outputs/basics/spec-zziplib.out
   :language: spec

For the rest of the tutorial we will sometimes use this new compiler, and sometimes we want to demonstrate things without it. For now, we will uninstall it to avoid using it in the next section.

.. literalinclude:: outputs/basics/compiler-uninstall.out
   :language: spec

.. note::

   The spec syntax may be confusing for new users.
   Spack can provide information about commands you run frequently.
   For instance, see the output of ``spack help --spec``:

   .. literalinclude:: outputs/basics/help-spec.out
      :language: console
