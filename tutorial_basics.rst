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
Spack has some nice command-line integration tools, so instead of simply prepending to our ``PATH`` variable, we'll source the Spack setup script.

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

Installing a package with Spack is very simple.
To install a software package type,

.. code-block:: console

  $ spack install <package_name>

Let's go ahead and install ``gmake``,

.. literalinclude:: outputs/basics/gmake.out
   :language: console

We see Spack installed ``gmake``, ``gcc-runtime``, and ``glibc``.
The ``glibc`` and ``gcc-runtime`` packages are automatically tracked by Spack to manage consistency requirements among compiler runtimes.
They do not represent separate software builds from source, but are records of the system's compiler runtime components Spack used for the install.
For the rest of this section, we'll ignore these components and focus on the packages explicitly installed.

Spack can install software either from source or from a binary cache.
Packages in the binary cache are signed with GPG for security.
For this tutorial, we've prepared a binary cache so we don't have to wait for slow compilation from source.

To enable installation from the binary cache, we'll need to configure Spack with the location of the cache and trust the GPG key that the cache was signed with.

.. literalinclude:: outputs/basics/mirror.out
   :language: console

We'll learn more about configuring Spack later in the tutorial, but for now we can install the rest of the packages in the tutorial from the cache using the same ```spack install``` command.
By default, this will install the binary cached version if it exists and fall back to installing the package from source if it does not.

Now that we understand how Spack handles installations, let's explore how we can customize what gets installed.
Spack's "spec" syntax is the interface by which we can request specific configurations of a package.
The ``%`` sigil is used to specify direct dependencies like a package's compiler.
For example, we can install zlib (a commonly used compression library), but instead of building it with the GCC compiler as we did for gmake previously, we'll install it with ``%clang`` to build it on top of the clang compiler.

.. literalinclude:: outputs/basics/zlib-clang.out
   :language: console

Notice that this installation is located separately from the previous one.
We'll explore this concept in more detail later, but this separation is fundamental to how Spack supports multiple configurations and versions of software packages simultaneously.

Now that we've seen how Spack handles separate installations, let's explore this capability further by installing multiple versions of the same package.
Before we install additional versions, we can check what versions are available to us using the ```spack versions``` command.
Let's check what versions of zlib-ng are available, and then we'll install a different version to demonstrate Spack's flexibility in managing multiple package versions.

.. literalinclude:: outputs/basics/versions-zlib.out
   :language: console

The ``@`` sigil is used to specify versions, both of packages and of compilers.

.. literalinclude:: outputs/basics/zlib-2.0.7.out
   :language: console

.. literalinclude:: outputs/basics/zlib-gcc-10.out
   :language: console

The spec syntax in Spack also supports compiler flags.
We can specify parameters such as ``cppflags``, ``cflags``, ``cxxflags``, ``fflags``, ``ldflags``, and ``ldlibs``.
If any of these values contain spaces, we'll need to enclose them in quotes on the command line.
Spack’s compiler wrappers will automatically inject these flags into the appropriate compilation commands.

.. literalinclude:: outputs/basics/zlib-O3.out
   :language: console

After installing packages, we can use the ``spack find`` command to query which packages are installed.
Notice that by default, some installed packages appear identical in the output.
To help distinguish between them, we can add the ``-l`` flag to display each package’s unique hash.
Additionally if we include the ``-f`` flag, Spack will show any non-empty compiler flags that were used during installation.

We use the ``spack find`` command to query which packages are installed.
Note that, with the default output, some packages may appear identical. To distinguish between them, we can use the ``-l`` flag to display the hash of each package.
Additionally, if we include the ``-f`` flag, Spack will show any non-empty compiler flags that were used during installation.

.. literalinclude:: outputs/basics/find.out
   :language: console

.. literalinclude:: outputs/basics/find-lf.out
   :language: console

Spack generates a unique hash for each spec we define.
This hash reflects the complete provenance of the package, so any change to the spec—such as compiler version, build options, or dependencies—will result in a different hash.
Spack uses these hashes both to compare specs and to create unique installation directories for every possible configuration.

As we work with more complex packages that have multiple software dependencies, we will see that Spack efficiently reuses existing packages to satisfy dependency requirements.
By default, Spack prioritizes reusing installations that already exist, whether they are stored locally or available from configured remote binary caches.
This approach helps us avoid unnecessary rebuilds of common dependencies, which is especially valuable if we update Spack frequently.

.. literalinclude:: outputs/basics/tcl.out
   :language: console

When we need to specify dependencies explicitly, we use the ``^`` sigil in the spec syntax. The syntax is recursive, meaning that anything we can specify for the top-level package can also be specified for a dependency using ``^``. This allows us to precisely control the configuration of both packages and their dependencies.

.. literalinclude:: outputs/basics/tcl-zlib-clang.out
   :language: console

We can also refer to packages from the command line by their package hash.
Earlier, when we used the ``spack find -lf`` command, we saw that the hash for our optimized installation of zlib-ng (with ``cflags="-O3"``) began with ``umrbkwv``.
Instead of typing out the entire spec, we can now build explicitly with that package by using the ``/`` sigil followed by its hash.

Similar to tools like Git, we do not need to enter the entire hash on the command line—just enough digits to uniquely identify the package.
If the prefix we provide matches more than one installed package, Spack will report an error and prompt us to be more specific.

.. literalinclude:: outputs/basics/tcl-zlib-hash.out
   :language: console

The ``spack find`` command can also take a ``-d`` flag, which can show dependency information.
Note that each package has a top-level entry, even if it also appears as a dependency.

.. literalinclude:: outputs/basics/find-ldf.out
   :language: console

Let's move on to slightly more complicated packages.
HDF5 is a good example of a more complicated package, with an MPI dependency.
If we install it with default settings it will build with OpenMPI.

.. literalinclude:: outputs/basics/hdf5.out
   :language: console

Spack packages can also have build options, called variants.
Boolean variants can be specified using the ``+`` (enable) and ``~`` or ``-``
(disable) sigils. There are two sigils for "disable" to avoid conflicts
with shell parsing in different situations.
Variants (boolean or otherwise) can also be specified using the same syntax as compiler flags.
Here we can install HDF5 without MPI support.

.. literalinclude:: outputs/basics/hdf5-no-mpi.out
   :language: console

We might also want to install HDF5 with a different MPI implementation.
While ``mpi`` itself is a virtual package representing an interface, other packages can depend on such abstract interfaces.
Spack handles these through "virtual dependencies." A package, such as HDF5, can depend on the ``mpi`` virtual package (the interface).
Actual MPI implementation packages (like ``openmpi``, ``mpich``, ``mvapich2``, etc.) provide the MPI interface.
Any of these providers can be requested to satisfy an MPI dependency.
For example, we can build HDF5 with MPI support provided by MPICH by specifying a dependency on ``mpich`` (e.g., ``hdf5 ^mpich``).
Spack also supports versioning of virtual dependencies.
A package can depend on the MPI interface at version 3 (e.g., ``hdf5 ^mpi@3``), and provider packages specify what version of the interface *they* provide.
The partial spec ``^mpi@3`` can be satisfied by any of several MPI implementation packages that provide MPI version 3.

.. literalinclude:: outputs/basics/hdf5-hl-mpi.out
   :language: console

We'll do a quick check in on what we have installed so far.

.. literalinclude:: outputs/basics/find-ldf-2.out
   :language: console

Spack models the dependencies of packages as a directed acyclic graph (DAG).
The ``spack find -d`` command shows the tree representation of that graph.
We can also use the ``spack graph`` command to view the entire DAG as a graph.

.. literalinclude:: outputs/basics/graph-hdf5.out
   :language: console

HDF5 is more complicated than our basic example of zlib-ng and Tcl, but it's still within the realm of software that an experienced HPC user could reasonably expect to manually install given a bit of time.
Now let's look at an even more complicated package.

.. literalinclude:: outputs/basics/trilinos.out
   :language: console

Now we're starting to see the power of Spack.
Trilinos in its default configuration has 23 direct dependencies, many of which have dependencies of their own.
Installing more complex packages can take days or weeks even for an experienced user.
Although we've done a binary installation for the tutorial, a source installation of Trilinos using Spack takes about 3 hours (depending on the system), but only 20 seconds of programmer time.

Spack manages consistency of the entire DAG.
Every MPI dependency will be satisfied by the same configuration of MPI, etc.
If we install Trilinos again specifying a dependency on our previous HDF5 built with MPICH:

.. literalinclude:: outputs/basics/trilinos-hdf5.out
   :language: console

We see that every package in the Trilinos DAG that depends on MPI now uses MPICH.

.. literalinclude:: outputs/basics/find-d-trilinos.out
   :language: console

As we discussed before, the ``spack find -d`` command shows the dependency information as a tree.
While that is often sufficient, many complicated packages, including Trilinos, have dependencies that cannot be fully represented as a tree.
Again, the ``spack graph`` command shows the full DAG of the dependency information.

.. literalinclude:: outputs/basics/graph-trilinos.out
   :language: console

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
   :language: console

.. literalinclude:: outputs/basics/find-zlib.out
   :language: console

We can uninstall packages by spec using the same syntax as install.

.. literalinclude:: outputs/basics/uninstall-zlib.out
   :language: console

.. literalinclude:: outputs/basics/find-lf-zlib.out
   :language: console

We can also uninstall packages by referring only to their hash.

We can use either the ``--force`` (or ``-f``) flag or the ``--dependents`` (or ``-R``) flag to remove packages that are required by another installed package.
Use ``--force`` to remove just the specified package, leaving dependents broken.
Use ``--dependents`` to remove the specified package and all of its dependents.

.. literalinclude:: outputs/basics/uninstall-needed.out
   :language: console

.. literalinclude:: outputs/basics/uninstall-r-needed.out
   :language: console

Spack will not uninstall packages that are not sufficiently specified (i.e., if the spec is ambiguous and matches multiple installed packages).
The ``--all`` (or ``-a``) flag can be used to uninstall all packages matching an ambiguous spec.

.. literalinclude:: outputs/basics/uninstall-ambiguous.out
   :language: console

.. literalinclude:: outputs/basics/uninstall-specific.out
   :language: console

-----------------------------
Advanced ``spack find`` Usage
-----------------------------

We will go over some additional uses for the ``spack find`` command not already covered in the :ref:`basics-tutorial-install` and
:ref:`basics-tutorial-uninstall` sections.

The ``spack find`` command can accept what we call "anonymous specs." These are expressions in spec syntax that do not contain a package name.
For example, ``spack find ^mpich`` will return every installed package that depends on MPICH, and ``spack find cflags="-O3"`` will return every package which was built with ``cflags="-O3"``.

.. literalinclude:: outputs/basics/find-dep-mpich.out
   :language: console

.. literalinclude:: outputs/basics/find-O3.out
   :language: console

The ``find`` command can also show which packages were installed explicitly (rather than pulled in as a dependency) using the lowercase ``-x`` flag.
The uppercase ``-X`` flag shows implicit installs only.
The ``find`` command can also show the path to which a Spack package was installed using the ``-p`` flag.

.. literalinclude:: outputs/basics/find-px.out
   :language: console

---------------------
Customizing Compilers
---------------------

Spack manages a list of available compilers on the system, detected automatically from the user's ``PATH`` variable.
The ``spack compilers`` command is an alias for ``spack compiler list``.

.. literalinclude:: outputs/basics/compilers.out
   :language: console

The compilers are maintained in a YAML file (``compilers.yaml``).
Later in the tutorial, you will learn how to configure compilers by hand for special cases.
Spack also has tools to add compilers, and compilers built with Spack can be added to the configuration.

.. literalinclude:: outputs/basics/install-gcc-12.1.0.out
   :language: console

.. literalinclude:: outputs/basics/find-p-gcc.out
   :language: console

We can add GCC to Spack as an available compiler using the ``spack compiler add`` command.
This will allow future packages to build with ``gcc@12.3.0``.
To avoid having to copy and paste GCC's path, we can use ``spack location -i`` to get the installation prefix.

.. literalinclude:: outputs/basics/compiler-add-location.out
   :language: console

We can also remove compilers from our configuration using ``spack compiler remove <compiler_spec>``

.. literalinclude:: outputs/basics/compiler-remove.out
   :language: console

.. note::

   The spec syntax may be confusing for new users.
   Spack can provide information about commands you run frequently.
   For instance, see the output of ``spack help --spec``:

   .. literalinclude:: outputs/basics/help-spec.out
      :language: console
