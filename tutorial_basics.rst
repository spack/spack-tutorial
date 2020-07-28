.. Copyright 2013-2019 Lawrence Livermore National Security, LLC and other
   Spack Project Developers. See the top-level COPYRIGHT file for details.

   SPDX-License-Identifier: (Apache-2.0 OR MIT)

.. _basics-tutorial:

=========================================
Basic Installation Tutorial
=========================================

This tutorial will guide you through the process of installing
software using Spack. We will first cover the `spack install` command,
focusing on the power of the spec syntax and the flexibility it gives
to users. We will also cover the `spack find` command for viewing
installed packages and the `spack uninstall` command. Finally, we will
touch on how Spack manages compilers, especially as it relates to
using Spack-built compilers within Spack. We will include full output
from all of the commands demonstrated, although we will frequently
call attention to only small portions of that output (or merely to the
fact that it succeeded). The provided output is all from an AWS
instance running Ubuntu 18.04

.. _basics-tutorial-install:

----------------
Installing Spack
----------------

Spack works out of the box. Simply clone spack and get going. We will
clone Spack and immediately checkout the most recent release, v0.15.

.. literalinclude:: outputs/basics/clone.out
   :language: console

.. literalinclude:: outputs/basics/checkout.out
   :language: console

Next add Spack to your path. Spack has some nice command line
integration tools, so instead of simply appending to your ``PATH``
variable, source the spack setup script.  Then add Spack to your path.

.. code-block:: console

  $ . share/spack/setup-env.sh

Finally, if you are running in an Amazon Cloud9 instance (which you
likely are for this tutorial), you will need to run one additional setup
script:

.. code-block:: console

  $ . share/spack/setup-tutorial-env.sh

You should see a lot of output. This is important, as it will increase
your available disk space and install some needed system software.

Once you've sourced these scripts, you're good to go!

-----------------
What is in Spack?
-----------------

The ``spack list`` command shows available packages.

.. literalinclude:: outputs/basics/list.out
   :language: console
   :lines: 1-6


The ``spack list`` command can also take a query string. Spack
automatically adds wildcards to both ends of the string. For example,
we can view all available python packages.

.. literalinclude:: outputs/basics/list-py.out
   :language: console
   :lines: 1-6

-------------------
Installing Packages
-------------------

Installing a package with Spack is very simple. To install a piece of
software, simply type ``spack install <package_name>``.

.. literalinclude:: outputs/basics/zlib.out
   :language: console

Spack can install software either from source or from a binary
cache. Packages in the binary cache are signed with GPG for
security. For the tutorial we have prepared a binary cache so you
don't have to wait on slow compilation from source. To be able to
install from the binary cache, we will need to configure Spack with
the location of the binary cache and trust the GPG key that the binary
cache was signed with.

.. literalinclude:: outputs/basics/mirror.out
   :language: console

You'll learn more about configuring Spack later in the tutorial, but
for now you will be able to install the rest of the packages in the
tutorial from a binary cache using the same ``spack install``
command. By default this will install the binary cached version if it
exists and fall back on installing from source.

Spack's spec syntax is the interface by which we can request specific
configurations of the package. The ``%`` sigil is used to specify
compilers.

.. literalinclude:: outputs/basics/zlib-clang.out
   :language: console

Note that this installation is located separately from the previous
one. We will discuss this in more detail later, but this is part of what
allows Spack to support arbitrarily versioned software.

You can check for particular versions before requesting them. We will
use the ``spack versions`` command to see the available versions, and then
install a different version of ``zlib``.

.. literalinclude:: outputs/basics/versions-zlib.out
   :language: console

The ``@`` sigil is used to specify versions, both of packages and of
compilers.

.. literalinclude:: outputs/basics/zlib-1.2.8.out
   :language: console

The spec syntax also includes compiler flags. Spack accepts
``cppflags``, ``cflags``, ``cxxflags``, ``fflags``, ``ldflags``, and
``ldlibs`` parameters.  The values of these fields must be quoted on
the command line if they include spaces. These values are injected
into the compile line automatically by the Spack compiler wrappers.

.. literalinclude:: outputs/basics/zlib-O3.out
   :language: console

The ``spack find`` command is used to query installed packages. Note that
some packages appear identical with the default output. The ``-l`` flag
shows the hash of each package, and the ``-f`` flag shows any non-empty
compiler flags of those packages.

.. literalinclude:: outputs/basics/find.out
   :language: console

Spack generates a hash for each spec. This hash is a function of the full
provenance of the package, so any change to the spec affects the
hash. Spack uses this value to compare specs and to generate unique
installation directories for every combinatorial version. As we move into
more complicated packages with software dependencies, we can see that
Spack reuses existing packages to satisfy a dependency only when the
existing package's hash matches the desired spec.

.. literalinclude:: outputs/basics/tcl.out
   :language: console

Dependencies can be explicitly requested using the ``^`` sigil. Note that
the spec syntax is recursive. Anything we could specify about the
top-level package, we can also specify about a dependency using ``^``.

.. literalinclude:: outputs/basics/tcl-zlib-clang.out
   :language: console

Packages can also be referred to from the command line by their package
hash. Using the ``spack find -lf`` command earlier we saw that the hash
of our optimized installation of zlib (``cppflags="-O3"``) began with
``hmvjty5``. We can now explicitly build with that package without typing
the entire spec, by using the ``/`` sigil to refer to it by hash. As with
other tools like git, you do not need to specify an *entire* hash on the
command line.  You can specify just enough digits to identify a hash
uniquely.  If a hash prefix is ambiguous (i.e., two or more installed
packages share the prefix) then spack will report an error.

.. literalinclude:: outputs/basics/tcl-zlib-hash.out
   :language: console

The ``spack find`` command can also take a ``-d`` flag, which can show
dependency information. Note that each package has a top-level entry,
even if it also appears as a dependency.

.. literalinclude:: outputs/basics/find-ldf.out
   :language: console

Let's move on to slightly more complicated packages. ``HDF5`` is a
good example of a more complicated package, with an MPI dependency. If
we install it "out of the box," it will build with ``openmpi``.

.. literalinclude:: outputs/basics/hdf5.out
   :language: console

Spack packages can also have build options, called variants. Boolean
variants can be specified using the ``+`` and ``~`` or ``-``
sigils. There are two sigils for ``False`` to avoid conflicts with
shell parsing in different situations. Variants (boolean or otherwise)
can also be specified using the same syntax as compiler flags.  Here
we can install HDF5 without MPI support.

.. literalinclude:: outputs/basics/hdf5-no-mpi.out
   :language: console

We might also want to install HDF5 with a different MPI
implementation. While MPI is not a package itself, packages can depend on
abstract interfaces like MPI. Spack handles these through "virtual
dependencies." A package, such as HDF5, can depend on the MPI
interface. Other packages (``openmpi``, ``mpich``, ``mvapich``, etc.)
provide the MPI interface.  Any of these providers can be requested for
an MPI dependency. For example, we can build HDF5 with MPI support
provided by mpich by specifying a dependency on ``mpich``. Spack also
supports versioning of virtual dependencies. A package can depend on the
MPI interface at version 3, and provider packages specify what version of
the interface *they* provide. The partial spec ``^mpi@3`` can be safisfied
by any of several providers.

.. literalinclude:: outputs/basics/hdf5-hl-mpi.out
   :language: console

We'll do a quick check in on what we have installed so far.

.. literalinclude:: outputs/basics/find-ldf-2.out
   :language: console

Spack models the dependencies of packages as a directed acyclic graph
(DAG). The ``spack find -d`` command shows the tree representation of
that graph.  We can also use the ``spack graph`` command to view the entire
DAG as a graph.

.. literalinclude:: outputs/basics/graph-hdf5.out
   :language: console

You may also have noticed that there are some packages shown in the
``spack find -d`` output that we didn't install explicitly. These are
dependencies that were installed implicitly. A few packages installed
implicitly are not shown as dependencies in the ``spack find -d``
output. These are build dependencies. For example, ``libpciaccess`` is a
dependency of openmpi and requires ``m4`` to build. Spack will build ``m4`` as
part of the installation of ``openmpi``, but it does not become a part of
the DAG because it is not linked in at run time. Spack handles build
dependencies differently because of their different (less strict)
consistency requirements. It is entirely possible to have two packages
using different versions of a dependency to build, which obviously cannot
be done with linked dependencies.

``HDF5`` is more complicated than our basic example of zlib and
openssl, but it's still within the realm of software that an experienced
HPC user could reasonably expect to install given a bit of time. Now
let's look at an even more complicated package.

.. literalinclude:: outputs/basics/trilinos.out
   :language: console

Now we're starting to see the power of Spack. Trilinos in its default
configuration has 23 top level dependencies, many of which have
dependencies of their own. Installing more complex packages can take
days or weeks even for an experienced user. Although we've done a
binary installation for the tutorial, a source installation of
trilinos using Spack takes about 3 hours (depending on the system),
but only 20 seconds of programmer time.

Spack manages consistency of the entire DAG. Every MPI dependency will
be satisfied by the same configuration of MPI, etc. If we install
``trilinos`` again specifying a dependency on our previous HDF5 built
with ``mpich``:

.. literalinclude:: outputs/basics/trilinos-hdf5.out
   :language: console

We see that every package in the trilinos DAG that depends on MPI now
uses ``mpich``.

.. literalinclude:: outputs/basics/find-d-trilinos.out
   :language: console

As we discussed before, the ``spack find -d`` command shows the
dependency information as a tree. While that is often sufficient, many
complicated packages, including trilinos, have dependencies that
cannot be fully represented as a tree. Again, the ``spack graph``
command shows the full DAG of the dependency information.

.. literalinclude:: outputs/basics/graph-trilinos.out
   :language: console

You can control how the output is displayed with a number of options.

The ASCII output from ``spack graph`` can be difficult to parse for
complicated packages. The output can be changed to the ``graphviz``
``.dot`` format using the ``--dot`` flag.

.. code-block:: console

  $ spack graph --dot trilinos | dot -Tpdf > trilinos_graph.pdf

.. _basics-tutorial-uninstall:

---------------------
Uninstalling Packages
---------------------

Earlier we installed many configurations each of zlib and tcl. Now we
will go through and uninstall some of those packages that we didn't
really need.

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

We can use either ``-f`` (force) or ``-R`` (remove dependents as well) to
remove packages that are required by another installed package.

.. literalinclude:: outputs/basics/uninstall-needed.out
   :language: console

.. literalinclude:: outputs/basics/uninstall-r-needed.out
   :language: console

Spack will not uninstall packages that are not sufficiently
specified. The ``-a`` (all) flag can be used to uninstall multiple
packages at once.

.. literalinclude:: outputs/basics/uninstall-ambiguous.out
   :language: console

.. literalinclude:: outputs/basics/uninstall-specific.out
   :language: console

-----------------------------
Advanced ``spack find`` Usage
-----------------------------

We will go over some additional uses for the ``spack find`` command not
already covered in the :ref:`basics-tutorial-install` and
:ref:`basics-tutorial-uninstall` sections.

The ``spack find`` command can accept what we call "anonymous specs."
These are expressions in spec syntax that do not contain a package
name. For example, ``spack find ^mpich`` will return every installed
package that depends on mpich, and ``spack find cppflags="-O3"`` will
return every package which was built with ``cppflags="-O3"``.

.. literalinclude:: outputs/basics/find-dep-mpich.out
   :language: console

.. literalinclude:: outputs/basics/find-O3.out
   :language: console

The ``find`` command can also show which packages were installed
explicitly (rather than pulled in as a dependency) using the ``-x``
flag. The ``-X`` flag shows implicit installs only. The ``find`` command can
also show the path to which a spack package was installed using the ``-p``
command.

.. literalinclude:: outputs/basics/find-px.out
   :language: console

---------------------
Customizing Compilers
---------------------

Spack manages a list of available compilers on the system, detected
automatically from from the user's ``PATH`` variable. The ``spack
compilers`` command is an alias for the command ``spack compiler list``.

.. literalinclude:: outputs/basics/compilers.out
   :language: console

The compilers are maintained in a YAML file. Later in the tutorial you
will learn how to configure compilers by hand for special cases. Spack
also has tools to add compilers, and compilers built with Spack can be
added to the configuration.

.. literalinclude:: outputs/basics/install-gcc-8.3.0.out
   :language: console

.. literalinclude:: outputs/basics/find-p-gcc.out
   :language: console

We can add gcc to Spack as an available compiler using the ``spack
compiler add`` command. This will allow future packages to build with
gcc @8.3.0.

.. literalinclude:: outputs/basics/compiler-add-location.out
   :language: console

We can also remove compilers from our configuration using ``spack compiler remove <compiler_spec>``

.. literalinclude:: outputs/basics/compiler-remove.out
   :language: console
