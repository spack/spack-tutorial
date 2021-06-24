.. Copyright 2013-2021 Lawrence Livermore National Security, LLC and other
   Spack Project Developers. See the top-level COPYRIGHT file for details.

   SPDX-License-Identifier: (Apache-2.0 OR MIT)

.. include:: common/setup.rst

.. _environments-tutorial:

=====================
Environments Tutorial
=====================

We've covered how to install, remove, and list packages with Spack using the
commands:

  * - `spack install <https://spack.readthedocs.io/en/latest/basic_usage.html#cmd-spack-install>`_ to install packages;
  * - `spack uninstall <https://spack.readthedocs.io/en/latest/basic_usage.html#cmd-spack-uninstall>`_ to remove them; and
  * - `spack find <https://spack.readthedocs.io/en/latest/basic_usage.html#cmd-spack-find>`_ to look at and query what is installed.

Customizing Spack's installation with configuration files like
`packages.yaml <https://spack.readthedocs.io/en/latest/build_settings.html#build-settings>`_ have also been discussed.

This section of the tutorial introduces **Spack Environments**, which
allow segregating packages installed in one environment from those of
others. The goal is to provide users with *virtual environments* similar
to those of other commonly used tools (e.g., Python) while allowing common
installations to be seamlessly shared.

Administering properly configured software involving lots of packages
and or varying configuration requirements (e.g., different implementations
of ``mpi``) for multiple projects and efforts can be overwhelming. Spack
environments allow you to readily:

  * - establish standard software requirements for your project(s);
  * - set up run environments for users;
  * - support your usual development environment(s);
  * - set up packages for CI/CD;
  * - reproduce builds (approximately or exactly) on other machines; and
  * - much more.

This tutorial introduces the basics of creating and using environments
before delving into expanding, configuring, and building software in
them. We will start with the command line interface then cover editing
the key environment file directly. Distinction between managed and unmanaged
environments will be described before covering reproducible builds.

-------------------
Environment Basics
-------------------

Let's look at the output of ``spack find`` at this point in the tutorial.

.. literalinclude:: outputs/environments/find-no-env-1.out
   :language: console
   :emphasize-lines: 1


This is a complete, but cluttered list of the installed packages and
their dependencies. It contains packages built with both ``openmpi``
and ``mpich``, as well as multiple variants of other packages, like
``hdf5`` and ``zlib``. The query mechanism we learned about with
``spack find`` can help, but it would be nice if we could start from
a clean slate without losing what we've already installed.

^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
Creating and activating environments
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

The ``spack env`` command can help. Let's create a new environment
called ``myproject``:

.. literalinclude:: outputs/environments/env-create-1.out
   :language: console
   :emphasize-lines: 1


An environment is a virtualized ``spack`` instance that you can use to
aggregate package installations for a project or other purpose. The has
an associated *view*, which is a single prefix where all packages from
the environment are linked.

You can see the environments we've created so far using the ``spack env
list`` command:

.. literalinclude:: outputs/environments/env-list-1.out
   :language: console
   :emphasize-lines: 1


Now let's **activate** our environment with the ``spack env activate``
command:

.. literalinclude:: outputs/environments/env-activate-1.out
   :language: console
   :emphasize-lines: 1


.. note::
   If you use the ``-p`` option for ``spack env activate``, Spack
   will prepend the environment name to the prompt. This is a handy
   way to be reminded if and which environment you are in.


Once you activate an environment, ``spack find`` only shows what is
in the current environment. We just created this environment, so we
it does not contain any installed packages.

.. literalinclude:: outputs/environments/find-env-1.out
   :language: console
   :emphasize-lines: 1

The output from ``spack find`` is now *slightly* different. It tells
you that you're in the ``myproject`` environment, so there is no need
to panic when you see that none of the previously installed packages
are available. It also states that there are **no** *root specs*. We'll
get back to what that means later.

If you *only* want to check what environment you are in, you can use
``spack env status``:

.. literalinclude:: outputs/environments/env-status-1.out
   :language: console
   :emphasize-lines: 1


If you want to leave this environment, you can use ``spack env deactivate``.
We also automatically set up the ``despacktivate`` alias for short.

Now we can check the normal environment:

.. literalinclude:: outputs/environments/env-status-2.out
   :language: console
   :emphasize-lines: 1,2,4


Notice that we are no longer in an environment and all of our packages
are still installed.

^^^^^^^^^^^^^^^^^^^
Installing packages
^^^^^^^^^^^^^^^^^^^

Now that we understand how creation and activation work, let's go
back to ``myproject`` and *install* a couple of packages; specifically,
``tcl`` and ``trilinos``.

.. literalinclude:: outputs/environments/env-install-1.out
   :language: console
   :emphasize-lines: 1,2,4

We see that ``tcl`` and all of the dependencies of ``trilinos`` are
already installed. Notice also that our environment's view gets updated.

Now confirm the contents of the environment using ``spack find``:

.. literalinclude:: outputs/environments/find-env-2.out
   :language: console
   :emphasize-lines: 1


We now see that ``tcl`` and ``trilinos`` are **root specs** in
our environment. That is because we explicitly asked for them to
be installed, which makes them the **roots** of the combined graph
of all packages in the environment. The other installed packages
are present because they are dependencies.

^^^^^^^^^^^^^^
Using packages
^^^^^^^^^^^^^^

Environments provide a convenient way for using installed packages.
Running ``spack env activate`` gives you everything in the environment
on your ``PATH``. Otherwise, you would need to ``spack load`` or
``module load`` a package to use it.

When you install packages into an environment, they are linked into
a single prefix, or *view*. Activating the environment with ``spack
env activate`` results in subdirectories from the view being added
to ``PATH``, ``LD_LIBRARY_PATH``, ``CMAKE_PREFIX_PATH`` and other
environment variables. This makes the environment easier to use.

Let's try it out. We just installed ``tcl`` into our ``myproject``
environment. ``Tcl`` includes a shell-like application called ``tclsh``.
You can see the path to ``tclsh`` using ``which``:

.. literalinclude:: outputs/environments/use-tcl-1.out
   :language: console
   :emphasize-lines: 1


Notice its path includes the name of our environment *and* a ``view``
subdirectory.

You can now run ``tclsh`` like you would any other program that is
in your path:

.. code-block:: console

	$ tclsh
	% echo "hello world!"
	hello world!
	% exit

Similarly, you can run Trilinos' programs. Let's see the path for
and run ``algebra``:

.. literalinclude:: outputs/environments/use-trilinos-1.out
   :language: console
   :emphasize-lines: 1,3


Again, we see the executable under our environment's view.

^^^^^^^^^^^^^^^^^^^^^
Uninstalling packages
^^^^^^^^^^^^^^^^^^^^^

We can uninstall packages from an environment without affecting
other environments. This is possible since, while Spack shares
common installations, environments only link to those installations.

Let's demonstrate this feature by creating another environment.
Suppose ``myproject`` requires ``trilinos`` but we have another
project that has it installed but no longer requires it.

Start by creating a ``myproject2`` environment with the installed
packages ``hdf5+hl`` and ``trilinos``:

.. literalinclude:: outputs/environments/env-create-2.out
   :language: console
   :emphasize-lines: 1,6-7,9,11


Notice that root specs display *exactly* as we asked for them on the
command line. In this case, ``hdf5`` shows the ``+hl`` requirement.

Now we have two environments. The ``myproject`` environment has ``tcl``
and ``trilinos`` while the ``myproject2`` environment has ``hdf5 +hl``
and ``trilinos``.

Now let's uninstall ``trilinos`` from ``myproject2`` and review the
contents of the environment:

.. literalinclude:: outputs/environments/env-uninstall-1.out
   :language: console
   :emphasize-lines: 1,10


The result is that the environment now has only one root spec, ``hdf5
+hl``, and contains fewer dependencies.

However, we know ``trilinos`` is still needed for the ``myproject``
environment. So let's switch back to confirm that it is still installed
in that environment.

.. literalinclude:: outputs/environments/env-swap-1.out
   :language: console
   :emphasize-lines: 1-3


Phew! We see that ``myproject`` still has ``trilinos`` as a root
spec. Spack uses reference counting to know that ``trilinos`` is
still installed for ``myproject``.

.. note::

   Trilinos would only have been uninstalled by Spack if it were
   no longer needed by any environments.


-------------------------------
Dealing with Many Specs at Once
-------------------------------

So far we have used ``install`` and ``uninstall`` for processing
individual packages. Since environments define sets of packages,
their Specs *can* be added to the environment before they are
installed together. Specs can be added at the command line or
entered directly in the environment configuration file.

Whole environments can be installed at once by adding Specs to
the environment before installing them. Individual packages can
still be added and removed from the environment as it evolves.

There are a couple of advantages of processing all of the Specs
of an environment at once. First, we don't have to write a custom
installation script outside of Spack. Second, we can launch a 
large build of many packages in parallel by taking advantage of
Spack's `install-level build parallelism
<https://spack.readthedocs.io/en/latest/packaging_guide.html#install-level-build-parallelism>`_.

This section focused on two ways to add specs to the environment before
installing them.

^^^^^^^^^^^^^
Adding specs
^^^^^^^^^^^^^

Let's start by *adding* a couple of specs to our ``myproject``
environment:

.. literalinclude:: outputs/environments/add-1.out
   :language: console
   :emphasize-lines: 1-2,5

Now let's take a look at what happened using ``spack find``:

.. literalinclude:: outputs/environments/find-1.out
   :language: console
   :emphasize-lines: 1

Notice the two specs we added, ``hdf5 +hl`` and ``gmp``, are now
listed as **root specs**. They are not actually installed in the
environment yet because ``spack add`` only adds *roots* to the
environment.

*All* of the yet-to-be-installed packages can be installed in an
active environment by simply running ``spack install`` with no
arguments:

.. literalinclude:: outputs/environments/add-2.out
   :language: console
   :emphasize-lines: 1


Spack concretizes the new root specs before ensuring that all of
the associated packages are installed. You can confirm this using
``spack find``:

.. literalinclude:: outputs/environments/add-3.out
   :language: console
   :emphasize-lines: 1


^^^^^^^^^^^^^^^^^
Configuring specs
^^^^^^^^^^^^^^^^^

An environment is more than just a list of root specs. It includes
*configuration* settings that affect the way Spack behaves when the
environment is activated. So far, ``myproject`` relies on configuration
defaults that can be overriden. Here we'll look at how to add specs
and ensure all of the packages depending on ``mpi`` build with ``mpich``.

Running ``spack spec`` shows that concretization looks the same as it
does outside the environment:

.. literalinclude:: outputs/environments/spec-1.out
   :language: console
   :emphasize-lines: 1

We can customize the selection of the ``mpi`` provider using
`concretization preferences
<https://spack.readthedocs.io/en/latest/build_settings.html#concretization-preferences>`_
to change the behavior of the concretizer.

Let's start by looking at the configuration of our environment using
``spack config get``:

.. literalinclude:: outputs/environments/config-get-1.out
   :language: console
   :emphasize-lines: 1

The output shows the special YAML configuration format that Spack
uses to store environment state. Currently, the file is just a 
``spack:`` header and a list of the **root** ``specs``.

Let's edit this file to prefer ``mpich`` as our ``mpi`` provider
using ``spack edit config``.

.. note::

   First make sure your ``EDITOR`` environment variable is set to
   the path of your preferred text editor.

You should now have the above file open in your editor. Change it
to include the ``packages:all:providers:mpi:`` entry below:

.. code-block:: yaml

   # This is a Spack Environment file.
   #
   # It describes a set of packages to be installed, along with
   # configuration settings.
   spack:
     packages:
       all:
         providers:
           mpi: [mpich]

     # add package specs to the `specs` list
     specs: [tcl, trilinos, hdf5, gmp]


Let's see the effects of this change on our package using ``spack spec``:

.. literalinclude:: outputs/environments/spec-2.out
   :language: console
   :emphasize-lines: 1

Notice ``mpich`` is now the ``mpi`` dependency for our concretized
spec.

At this point we only wanted to change the default ``mpi`` provider
for packages that depend on ``mpi``. An environment can contain
many other types of configuration, such as adding custom package
repositories and customizing the installation location, compilers,
and external packages. Workflows for CI and software development
can also be configured. Refer to the :ref:`configuration section
<configs-tutorial>` of the tutorial for more information.

^^^^^^^^^^^^^^^^^^^^^^^^^^^
Rejiggering the environment
^^^^^^^^^^^^^^^^^^^^^^^^^^^

You may need to re-install packages in the environment after making
significant changes to the configuration like changing interface
provider packages. This can be accomplished by forcing Spack to
reconcretize the environment and re-installing the specs.

For example, the packages installed in our ``myproject`` environment
are now out of sync with our new configuration since we already
installed part of the environment with ``openmpi``. Now we want
to install everything in ``myproject`` with ``mpich``.

Let's run ``spack concretize --force`` to make Spack re-concretize
all of the environment's specs:

.. literalinclude:: outputs/environments/concretize-f-1.out
   :language: console
   :emphasize-lines: 1


All the specs are concrete **and** ready to be installed with
``mpich`` as the MPI implementation. You can now re-run ``spack
install`` to finish the process.

------------------------
Building in environments
------------------------

Activated environments allow you to invoke any programs installed
in them. 

Suppose you want to compile some MPI programs. We have an MPI
implementation installed in our ``myproject`` environment, so
``mpicc`` is available in our path. We can confirm this using
``which``:

.. literalinclude:: outputs/environments/show-mpicc-1.out
   :language: console
   :emphasize-lines: 1,3


As mentioned before, activating the environment sets a number of
environment variables. That includes variables like ``CPATH``,
``LIBRARY_PATH``, and ``LD_LIBRARY_PATH``, which allows you to
easily find package headers and libraries installed in the environment.

Let's look specifically at path-related environment variables using
``env | grep PATH``:

.. literalinclude:: outputs/environments/show-paths-1.out
   :language: console
   :emphasize-lines: 1


We can demonstrate this by building a really simple MPI program.
Make a simple test program called ``mpi-hello.c`` that contains
the following statements:

.. code-block:: c

	#include <stdio.h>
	#include <mpi.h>
	#include <zlib.h>

	int main(int argc, char **argv) {
	  int rank;
	  MPI_Init(&argc, &argv);

	  MPI_Comm_rank(MPI_COMM_WORLD, &rank);
	  printf("Hello world from rank %d\n", rank);

	  if (rank == 0) {
	    printf("zlib version: %s\n", ZLIB_VERSION);
	  }

	  MPI_Finalize();
	}

This program includes headers from ``mpi`` and ``zlib``.
It also prints out a message from each MPI rank and the
version of ``zlib``.

Let's build and run it:

.. literalinclude:: outputs/environments/use-mpi-1.out
   :language: console
   :emphasize-lines: 1-2


Notice that we did *not* need to pass any special arguments
to the compiler, such as include paths or libraries. We also
see that ``Hello world`` is output for each of the ranks and
the version of ``zlib`` used to build the program is printed.

We can confirm the version of ``zlib`` is in our environment using
``spack find``:

.. literalinclude:: outputs/environments/myproject-zlib-1.out
   :language: console
   :emphasize-lines: 1

Note that the reported version matches our installation.

This simple example only scratches the surface of what we can do
with environments. Advanced use cases are provided in the
:ref:`developer workflows <developer-workflows-tutorial>` tutorial.

------------------
Reproducing builds
------------------

Spack environments provide users with *virtual environments*
(think Python and Conda), where packages in one environment
are segregated from those of another. These environments can
be managed or unmanaged. In either case, their environment
files can be used to reproduce builds on other machines.

^^^^^^^^^^^^^^^^^
Environment files
^^^^^^^^^^^^^^^^^

There are two key files tracking the contents of environments:
``spack.yaml`` and ``spack.lock``. The former is the environment
configuration file that we previously edited through ``spack
config edit``. The latter is automatically generated during
concretization.

The two files represent two fundamental concepts:

  * - ``spack.yaml`` is the set of *abstract* specs and configuration that
    you want to install; and
  * - ``spack.lock`` is the set of all fully *concrete* specs generated from
    concretizing ``spack.yaml``

In this sense, you can think of environments as generalizations of specs,
but for sets of packages.

Both environment files can be versioned in repositories, shared, and
used to install the same set of software on different machines. The files
are intended to be used by developers and administrators to manage the
environments in a reproducible way. We will cover their re-use later.

^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
Managed versus unmanaged environments
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Environments are either managed or unmanaged. Both types of
environments are defined by their environment files. So far
we have only created managed environments. This section describes
their differences.

*Managed environments* are created using ``spack env create <name>``.
They are automatically created in the ``var/spack/environments``
subdirectory and can be referenced by their names.

*Unmanaged environments* can be created in one of two ways. First,
the Spack's environment file(s) can be placed in any directory
(other than ``var/spack/environments``). Alternatively, you can
use ``spack env create -d <directory>`` to specify the directory
(``<directory>``) in which the files should reside. Unmanaged
environments are not named.

^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
Reviewing a managed environment
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

We created our currently active environment, ``myproject``, earlier
using ``spack env create myproject`` so let's mainly focus on its
environment files in this section.

Earlier, when we changed our environment's configuration using ``spack
config edit``, we were actually editing its ``spack.yaml`` file. We
can change to the directory containing the file using ``spack cd``:

.. literalinclude:: outputs/environments/filenames-1.out
   :language: console
   :emphasize-lines: 1-2,4


Notice ``myproject`` is a subdirectory of ``var/spack/environments``
within the Spack installation making it a *managed* environment.
Consequently, it can be referenced by name. It will also show up
running ``spack env list``:

.. literalinclude:: outputs/environments/env-list-2.out
   :language: console
   :emphasize-lines: 1


You can see that ``myproject`` is active because it is highlighted
in green.

We can also see from the directory listing that the environment
directory contains both of the environment files: ``spack.yaml``
and ``spack.lock``.

If we ``cat`` the ``spack.yaml`` file, we'll see the same contents
shown previously by ``spack config get``:

.. literalinclude:: outputs/environments/cat-config-1.out
   :language: console
   :emphasize-lines: 1


^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
Creating an unmanaged environment
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Environments do not have to be created in a Spack instance; rather,
you can put the environment files in any directory. This can be
helpful for environment-based software releases and CI/CD.

Let's create an *unmanaged* environment from scratch for a simple
project:

.. literalinclude:: outputs/environments/anonymous-create-1.out
   :language: console
   :emphasize-lines: 1-4


Notice the command shows Spack created the environment, updated
the view, and gave the command needed to activate it. Since the
environment is unmanaged, it must be referenced by its directory
path.

Let's see what really happened by listing the directory contents
and looking at the configuration file:

.. literalinclude:: outputs/environments/anonymous-create-2.out
   :language: console
   :emphasize-lines: 1,3


Notice Spack created a ``spack.yaml`` file in the *code* directory.
Also note that the configuration file has an empty spec list (i.e.,
``[]``). That list is intended to contain only the *root specs* of
the environment.

We can confirm that it is not a managed environment by running
``spack env list``:

.. literalinclude:: outputs/environments/env-list-2.out
   :language: console
   :emphasize-lines: 1

and noting that the path does not appear in the output.

Now let's add some specs to the environment. Suppose your project
depends on ``boost``, ``trilinos``, and ``openmpi``. Add these 
packages to the spec list using your favorite text editor. The
dash syntax for a yaml list is used in our example. Your package
should now contain the following entries:

.. code-block:: yaml

   # This is a Spack Environment file.
   #
   # It describes a set of packages to be installed, along with
   # configuration settings.
   spack:
     # add package specs to the `specs` list
     specs:
     - boost
     - trilinos
     - openmpi

Now activate the environment and install the packages:

.. literalinclude:: outputs/environments/install-anonymous-1.out
   :language: console
   :emphasize-lines: 1-2


Notice Spack concretized the the specs before installing them and
their dependencies. It also updated the environment's view. Since
we already installed all of these packages outside of the environment,
their links were added to our environment.

^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
Updating an installed environment
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Spack supports tweaking an environment even after the initial specs
are installed. You are free to add and remove specs just as you would
outside of the environment using the command line interface as before.

For example, lets add ``hdf5`` and look at our file:

.. literalinclude:: outputs/environments/add-anonymous-1.out
   :language: console
   :emphasize-lines: 1,4


Notice ``spack add`` added the package to our active environment and
it appears in the configuration file's spec list.

Now use ``spack remove`` to remove it from the environment:

.. literalinclude:: outputs/environments/remove-anonymous-1.out
   :language: console
   :emphasize-lines: 1,4

and we see the spec was removed from our environment and the spec list.


^^^^^^^^^^^^^^^^^^^^^^^^
Reviewing ``spack.lock``
^^^^^^^^^^^^^^^^^^^^^^^^

Now let's turn our attention from the abstract to the concrete.
Our focus so far has been on the abstract environment configuration
represented by the ``spack.yaml`` file. Once that file is concretized,
Spack *generates* a corresponding ``spack.lock`` file representing
the full concretized state of the environment.

This file is intended to be a machine-readable representation of the
information needed to *reproduce* the build of an environment. As such,
it is written in ``json``, which is less readable than ``yaml``.

Let's look at the top 30 lines of our current environment:

.. literalinclude:: outputs/environments/lockfile-1.out
   :language: console
   :emphasize-lines: 1


While it is still readable, it consists of nearly 2000 lines of
of information representing the actual configurations for each
of the environment's packages.

^^^^^^^^^^^^^^^^^^^^^^^^^^
Reproducing an environment
^^^^^^^^^^^^^^^^^^^^^^^^^^

You can recreate an environment that someone else built by passing either
of the environment files to ``spack env create``. The file you choose
depends on whether you want to approximate the build using the abstract
specs or an *exact* build based on the concrete specs.

An approximate build is created using the ``spack.yaml`` file. This
approach is relevant when we want to build the same specs on a new
platform. It allows you to reproduce the environment by preserving
the abstract requirements in the file. However, the software may
actually build differently in part because the concretizer may choose
different dependencies.

Let's use ``spack env create`` to create an abstract environment from
the file that we'll call ``abstract``:

.. literalinclude:: outputs/environments/create-from-file-1.out
   :language: console
   :emphasize-lines: 1

Here we see that Spack created a managed environment with the name
we provided.

The ``spack.lock`` file is used for an exact reproduction of the
original build because it contains the information for all of the
decisions made during concretization. 

Now let's create a concrete environment, called ``concrete`` from
the file:

.. literalinclude:: outputs/environments/create-from-file-1.out
   :language: console
   :emphasize-lines: 1

Here we see that Spack again created a managed environment with the
provided name.

.. note::

   Use of ``spack.lock`` to reproduce a build (currently) requires you
   to be on the same type of machine.
