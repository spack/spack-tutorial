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

We will begin by introducing the ``spack install`` command, highlighting the versatility of Spack's spec syntax and the flexibility it offers users.
Next, we will demonstrate how to use the ``spack find`` command to view installed packages, as well as the ``spack uninstall`` command to remove them.

Additionally, we will discuss how Spack manages compilers, with a particular focus on using Spack-built compilers within the Spack environment.
Throughout the tutorial, we will present complete command outputs; however, we will often emphasize only the most relevant sections or simply confirm successful execution.
All examples and outputs are based on an Ubuntu 26.04 Docker image.

.. _basics-tutorial-install:

----------------
Setting Up Spack
----------------

Spack is ready to use immediately -- there is no separate build or install step.
To get started, we simply clone the Spack repository and check out the latest v1.2 release:

.. literalinclude:: outputs/basics/clone.out
   :language: console

Next, we'll add Spack to our path.
Spack has some nice command line integration tools, so instead of simply prepending to our ``PATH`` variable, we'll source the Spack setup script.

.. code-block:: console

  $ . share/spack/setup-env.sh

And now we're good to go!

.. _basics-tutorial-install-packages:

-------------------
Installing Packages
-------------------

Before installing anything, let's see what Spack has to offer.
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

Once we've found a package, installing it is as simple as typing ``spack install`` followed by its name:

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

.. literalinclude:: outputs/basics/mirror.out
   :language: console

From here on, the same ``spack install`` command will fetch a package from the cache when a matching binary exists and fall back to building from source when it doesn't.

---------------
The Spec Syntax
---------------

So far we've installed packages with their default configuration.
Spack's *spec syntax* is how we request a specific configuration of a package.
A *spec* describes a package together with any constraints we want to place on how it is built: its version, its build options, the compiler it uses, and even the configuration of its dependencies.
Each kind of constraint has its own sigil, which the subsections below introduce one at a time, building up from a bare package name to fully constrained dependency graphs.

^^^^^^^^
Versions
^^^^^^^^

We can install multiple versions of the same package side by side.
Before installing a specific version, let's check which versions of ``zlib-ng`` are available using the ``spack versions`` command.

.. literalinclude:: outputs/basics/versions-zlib.out
   :language: spec

We select one with the ``@`` sigil:

.. literalinclude:: outputs/basics/zlib-2.0.7.out
   :language: spec

The ``@`` sigil also accepts ranges -- such as ``@2.1:`` (2.1 or newer), ``@:2.1`` (up to 2.1), or ``@2.0:2.2`` (anywhere in between 2.0 and 2.2) -- letting Spack pick any version that satisfies the constraint.

^^^^^^^^
Variants
^^^^^^^^

Besides versions, packages expose build options called *variants*.
To see which variants a package defines, along with their defaults, use ``spack info``:

.. literalinclude:: outputs/basics/info-zlib.out
   :language: console

Boolean variants are enabled with the ``+`` sigil and disabled with the ``~`` sigil.
For example, ``zlib-ng`` has an ``ipo`` variant that enables interprocedural optimization, which we can turn on with ``+ipo``:

.. literalinclude:: outputs/basics/zlib-ipo.out
   :language: spec

Not every variant is boolean.
Some take a value, which we assign with ``name=value`` syntax.
Here we build ``zlib-ng`` in debug mode through its ``build_type`` variant.

.. literalinclude:: outputs/basics/zlib-build-type.out
   :language: spec

Some variants are *conditional*: the indented ``when`` lines in the ``spack info`` output mark them.
Here ``build_type``, ``generator``, and ``ipo`` are available only ``when build_system=cmake`` -- that is, when zlib-ng is built with CMake instead of Autotools.
Requesting one of them, as we just did with ``+ipo``, therefore also selects the CMake build system.

.. note::

   The same ``name=value`` syntax also sets compiler flags on a build: Spack accepts ``cflags``, ``cxxflags``, ``cppflags``, ``fflags``, ``ldflags``, and ``ldlibs`` -- written like ``cflags="-O3"`` (quote values containing spaces) -- and its compiler wrappers inject them into the right commands.
   This is an escape hatch, though: a package's variants and build system usually select appropriate options already, so reach for explicit flags only when you genuinely need them.

^^^^^^^^^^^^^^^^^^^
Direct Dependencies
^^^^^^^^^^^^^^^^^^^

The ``%`` sigil specifies a direct dependency of the package we're installing.
The most common direct dependency is a compiler -- every package built from source needs one -- so that is what we will use ``%`` for here.
So far we've let Spack choose the compiler, building ``zlib-ng`` with GCC just as we did for gmake.
This time we'll build it with Clang instead, using ``%clang``:

.. literalinclude:: outputs/basics/zlib-clang.out
   :language: spec

This installation is located separately from the previous one.
As described in the overview, this separation is fundamental to how Spack supports multiple configurations and versions of software packages simultaneously.

**The spec syntax is recursive** -- any syntax we can specify for the "root" package we can also use for a dependency.
For example, since a compiler is just another dependency, we can pin its version with ``@``, just as we did for ``zlib-ng``:

.. literalinclude:: outputs/basics/zlib-gcc-14.out
   :language: spec

^^^^^^^^^^^^^^^^^^^^^^^
Transitive Dependencies
^^^^^^^^^^^^^^^^^^^^^^^

The ``^`` sigil can constrain any dependency of a root spec, whether direct or transitive.

We need a package with dependencies to try it on.
The ``tcl`` package depends on ``zlib-ng``, so let's preview how Spack would build ``tcl`` with constraints on its ``zlib-ng`` dependency using ``spack spec``; the ``-l`` flag adds each node's hash:

.. literalinclude:: outputs/basics/spec-tcl-zlib-clang.out
   :language: spec

This is the *concretized* spec: Spack has filled in every dependency, along with its version, variants, and compiler.
In the output, ``[+]`` marks specs already installed, ``[e]`` those provided externally by the system, and ``[b]`` those available in a cache but not yet installed.
Notice also that ``%`` binds to the spec it follows.
Because ``%clang`` comes after ``^zlib-ng@2.0.7``, only ``zlib-ng`` is built with Clang, while ``tcl`` keeps the default compiler.

Now let's install it:

.. literalinclude:: outputs/basics/tcl-zlib-clang.out
   :language: spec

By default, Spack installs from a binary cache when it can, rather than building from source.
The build-only dependencies a source build needs (such as ``gmake``) are skipped for a prebuilt binary.

Each build has a unique hash, shown in the ``-l`` output above, reflecting its complete provenance.
Any change to the spec (version, build options, compiler, or a dependency) produces a different hash and its own installation directory.
We can refer to a build directly by its hash with the ``/`` sigil, instead of retyping its full spec.
For example, rather than writing ``^zlib-ng@2.0.7 %clang`` again, we can point ``tcl`` at that exact build by its hash:

.. literalinclude:: outputs/basics/spec-tcl-zlib-hash.out
   :language: spec

As with Git, we only need enough leading digits to identify the build uniquely; if the prefix matches more than one installed package, Spack reports an error and asks us to be more specific.

The ``spack spec`` output above lists these dependencies as a tree, but Spack actually models them as a directed acyclic graph (DAG).
A package can be shared by several dependents, which a tree can't show.
The ``spack graph`` command renders that full graph:

.. literalinclude:: outputs/basics/graph-tcl.out
   :language: spec

For more complex packages, ``spack graph`` can also emit Graphviz output (``--dot``) to render as an SVG, and ``--color`` draws build-only dependencies in a different color from link and run dependencies.

^^^^^^^^^^^^^^^^^^^^
Virtual Dependencies
^^^^^^^^^^^^^^^^^^^^

Let's move on to a more complicated package.
``hdf5`` is a good example: it depends on ``mpi``, but ``mpi`` is not an ordinary package.
It is a *virtual package* -- an interface that several real packages provide -- and Spack handles dependencies on such interfaces through "virtual dependencies".

By default ``hdf5`` builds against ``openmpi``:

.. literalinclude:: outputs/basics/hdf5.out
   :language: spec

but we might want to build it against a *different* ``mpi`` implementation.
To see which packages provide the ``mpi`` interface, ask Spack with ``spack providers``:

.. literalinclude:: outputs/basics/providers-mpi.out
   :language: console

Any of these providers can be requested to satisfy an MPI dependency.
For example, we can build ``hdf5`` with MPI support provided by MPICH by specifying a dependency on ``mpich``:

.. literalinclude:: outputs/basics/hdf5-mpich.out
   :language: spec

We've actually already been using virtual packages when we changed compilers earlier.
Compilers are providers for virtual packages like ``c``, ``cxx``, and ``fortran``.
Because these are often provided by the same package but we might want to use C and C++ from one compiler and Fortran from another, we need a syntax to specify which virtual a package provides.
We call this "virtual assignment", which can be specified with ``%virtual=provider`` or ``^virtual=provider``.

For example, we can ask Spack for an ``hdf5`` that uses Clang for the C and C++ components but GCC for Fortran:

.. literalinclude:: outputs/basics/spec-hdf5-compilers.out
   :language: spec
   :lines: 1-2

The same syntax works for ``mpi``: we could have written ``hdf5 ^mpi=mpich`` instead of ``hdf5 ^mpich``.
There's no need, though, because the only way for ``hdf5`` to depend on ``mpich`` is for ``mpich`` to provide ``mpi``.
This is also why we didn't have to specify which virtuals ``gcc`` and ``clang`` provided earlier when building simpler packages.

^^^^^^^^^^^^^^^^^^^^^
Spec Syntax Reference
^^^^^^^^^^^^^^^^^^^^^

We have now seen every piece of the spec syntax.
Taken together, the sigils let us constrain any part of a build:

* ``@`` selects a version or a version range.
* ``+`` and ``~`` toggle boolean variants, and ``name=value`` sets the others.
* ``%`` constrains a direct dependency, such as a compiler.
* ``^`` constrains any dependency in the graph, whether direct or transitive.
* ``/`` refers to an already-installed build by its hash.
* ``%virtual=provider`` and ``^virtual=provider`` pick which package provides a virtual.

Because the syntax is recursive, each of these can be applied to a dependency just as it is to the root package.
There is no need to memorize all of this: ``spack help --spec`` prints a concise summary you can return to whenever you need it.

.. literalinclude:: outputs/basics/help-spec.out
   :language: console

.. _basics-tutorial-query:

----------------------
Querying Installations
----------------------

Now that we have installed a variety of packages, we can use the ``spack find`` command to query which packages are installed.

.. literalinclude:: outputs/basics/find.out
   :language: spec

Spack groups the output by architecture and by the compiler used to build each package.
Notice that by default, some installed packages appear identical in the output.
To help distinguish between them, we can add the ``-l`` flag to display each package's unique hash.

.. literalinclude:: outputs/basics/find-l.out
   :language: spec

As we saw when referring to builds by hash, every installed package has a distinct hash, so configurations that look alike in the default output still occupy separate installations.

``spack find`` can also show what each installed package depends on with the ``-d`` flag.
For example, here is the ``tcl`` we installed, shown with its dependency tree:

.. literalinclude:: outputs/basics/find-d-tcl.out
   :language: spec

The ``spack find`` command can also accept what we call "anonymous specs": expressions in spec syntax that do not contain a package name.
For example, ``spack find ^mpich`` will return every installed package that depends on MPICH.

.. literalinclude:: outputs/basics/find-dep-mpich.out
   :language: spec

The ``find`` command can show which packages were installed explicitly (rather than pulled in as a dependency) using the lowercase ``-x`` flag; the uppercase ``-X`` flag shows implicit installs only.
It can also show the path to which a package was installed using the ``-p`` flag.

.. literalinclude:: outputs/basics/find-px.out
   :language: spec

.. _basics-tutorial-trilinos:

-------------------
A Realistic Example
-------------------

Now that we know the spec syntax and how to query installations, let's put them to work on a realistic package.

.. literalinclude:: outputs/basics/trilinos.out
   :language: spec

Now we're starting to see the power of Spack.
Depending on the spec, Trilinos can have over 30 direct dependencies, many of which have dependencies of their own.
Only a handful are new here, though: the rest of that large graph was already installed earlier in the tutorial, so Spack reuses those builds instead of repeating them.
Installing a package this complex by hand can take an experienced user days or weeks.
Although we've done a binary installation for the tutorial, a source installation of Trilinos using Spack takes about 3 hours (depending on the system), but only 20 seconds of programmer time.

Spack manages the consistency of the entire DAG: every package that depends on MPI is satisfied by the same MPI.
Let's install Trilinos again, this time reusing the HDF5 we built with MPICH:

.. literalinclude:: outputs/basics/trilinos-hdf5.out
   :language: spec

Only ``trilinos`` itself was installed -- the rest of the graph, including our MPICH-based ``hdf5``, was already present and reused.
We can confirm that the whole graph uses MPICH with the anonymous spec ``spack find ^mpich``:

.. literalinclude:: outputs/basics/trilinos-find-mpich.out
   :language: spec

A dependency graph this large is unreadable as ASCII art.
We can instead render it as an image with ``spack graph --dot``:

.. code-block:: console

  $ spack graph --dot trilinos | dot -Tsvg > trilinos_graph.svg

.. _basics-tutorial-uninstall:

---------------------
Uninstalling Packages
---------------------

Earlier we installed several configurations of ``zlib-ng``.
Now we will go through and uninstall some of those packages that we didn't really need.

.. literalinclude:: outputs/basics/find-zlib.out
   :language: spec

We can uninstall packages by spec using the same syntax as install.

.. literalinclude:: outputs/basics/uninstall-zlib.out
   :language: spec

.. literalinclude:: outputs/basics/find-lf-zlib.out
   :language: spec

We can also refer to a package by its hash instead of a full spec.
But Spack won't remove a package that another installed package still needs:

.. literalinclude:: outputs/basics/uninstall-needed.out
   :language: spec

To remove it anyway, use ``--force`` (or ``-f``) to delete just that package and leave its dependents broken, or ``--dependents`` (or ``-R``) to remove it together with everything that depends on it:

.. literalinclude:: outputs/basics/uninstall-r-needed.out
   :language: spec

Spack refuses to uninstall a package when the spec is ambiguous -- when it matches more than one installed package:

.. literalinclude:: outputs/basics/uninstall-ambiguous.out
   :language: spec

As the error suggests, we can disambiguate with a more specific spec, refer to the exact build by its hash, or pass ``--all`` (or ``-a``) to remove every match.
Here we remove one of the two Trilinos builds by its hash:

.. literalinclude:: outputs/basics/uninstall-specific.out
   :language: spec

---------------------
Customizing Compilers
---------------------

In the :ref:`Installing Packages <basics-tutorial-install-packages>` section, we saw that Spack detects the compilers already on your ``PATH`` and configures them as external packages.
Spack can also install a compiler itself and then use it to compile other packages.

.. literalinclude:: outputs/basics/install-gcc-16.out
   :language: spec

Once installed, it appears with a ``[+]`` in the list of available compilers:

.. literalinclude:: outputs/basics/compilers-2.out
   :language: console

The ``gcc@16`` compiler is immediately available to use:

.. literalinclude:: outputs/basics/spec-zziplib.out
   :language: spec
   :lines: 1-2

We won't need this compiler in the next chapter, so we'll uninstall it for now.

.. literalinclude:: outputs/basics/compiler-uninstall.out
   :language: spec

----------
Next Steps
----------

You can now install packages from source or from a binary cache, request specific configurations with the spec syntax, query what is installed, uninstall what you no longer need, and have Spack build and use its own compilers.
These commands work one package at a time, which is enough to get started but quickly becomes unwieldy for a whole software stack.

The :ref:`Environments Tutorial <environments-tutorial>` is the natural next step: it shows how to group specs into a documented, reproducible collection that you can install, share, and rebuild as a unit.
