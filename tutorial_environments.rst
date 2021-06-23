.. Copyright 2013-2021 Lawrence Livermore National Security, LLC and other
   Spack Project Developers. See the top-level COPYRIGHT file for details.

   SPDX-License-Identifier: (Apache-2.0 OR MIT)

.. include:: common/setup.rst

.. _environments-tutorial:

=====================
Environments Tutorial
=====================

We've shown you how to install, remove, and list packages with Spack using the
commands:

* `spack install <https://spack.readthedocs.io/en/latest/basic_usage.html#cmd-spack-install>`_ to install packages,
* `spack uninstall <https://spack.readthedocs.io/en/latest/basic_usage.html#cmd-spack-uninstall>`_ to remove them, and
* `spack find <https://spack.readthedocs.io/en/latest/basic_usage.html#cmd-spack-find>`_ to look at and query what is installed.

We've also shown you how to customize Spack's installation with configuration
files like
`packages.yaml <https://spack.readthedocs.io/en/latest/build_settings.html#build-settings>`_.

Managing a lot of software in one place can be overwhelming, especially
if you work on multiple projects. The configuration requirements (e.g.,
which implemenation of ``mpi`` should be used) can also vary across package
groups. 

Spack **environments** provide a means of managing groups of software.
They allow you to establish standard software requirements for your
project(s); set up a run environment for users; support your usual
development environment(s); set up packages for CI/CD; and more.

This tutorial introduces the basics of Spack environments before 
delving into their use to install and use the associated software.

-------------------
Environment Basics
-------------------

Let's look at the output of ``spack find`` at this point in the tutorial.

.. literalinclude:: outputs/environments/find-no-env-1.out
   :language: console
   :emphasize-lines: 1


This is a complete, but cluttered list. There are packages built with
both ``openmpi`` and ``mpich``, as well as multiple variants of other
packages, like ``hdf5`` and ``zlib``. The query mechanism we learned
about with ``spack find`` can help, but it would be nice if we could start
from a clean slate without losing what we've already installed.

^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
Creating and activating environments
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

The ``spack env`` command can help. Let's create a new environment:

.. literalinclude:: outputs/environments/env-create-1.out
   :language: console
   :emphasize-lines: 1


An environment is a virtualized ``spack`` instance that you can use for a
specific purpose. The environment also has an associated *view*, which
is a single prefix where all packages from the environment are linked.

You can see the environments we've created so far like this:

.. literalinclude:: outputs/environments/env-list-1.out
   :language: console
   :emphasize-lines: 1


And you can **activate** an environment with ``spack env activate``:

.. literalinclude:: outputs/environments/env-activate-1.out
   :language: console
   :emphasize-lines: 1


Once you enter an environment, ``spack find`` shows only what is in the
current environment. We just created this environment, so we have a
clean slate with no installed packages:

.. literalinclude:: outputs/environments/find-env-1.out
   :language: console
   :emphasize-lines: 1

The ``spack find`` output is still *slightly* different. It tells you
that you're in the ``myproject`` environment, so that you don't panic
when you see that there is nothing installed. It also says that there
are *no root specs*. We'll get back to what that means later.

If you *only* want to check what environment you are in, you can use
``spack env status``:

.. literalinclude:: outputs/environments/env-status-1.out
   :language: console
   :emphasize-lines: 1


If you want to leave this environment and go back to normal Spack,
you can use ``spack env deactivate``. We like to use the
``despacktivate`` alias (which Spack sets up automatically) for short.
Then we can check the environment.

.. literalinclude:: outputs/environments/env-status-2.out
   :language: console
   :emphasize-lines: 1,2,4


Phew. All of our packages are still installed.

^^^^^^^^^^^^^^^^^^^
Installing packages
^^^^^^^^^^^^^^^^^^^

Now that we understand how creation and activation work, let's go
back to ``myproject`` and *install* a couple of packages: ``tcl``
and ``trilinos``.

.. literalinclude:: outputs/environments/env-install-1.out
   :language: console
   :emphasize-lines: 1,2,4


And confirm the contents of the environment:

.. literalinclude:: outputs/environments/find-env-2.out
   :language: console
   :emphasize-lines: 1


So ``tcl`` and ``trilinos`` have been installed in our environment.
We call them **root specs** because we asked for them explicitly.
The other twenty packages listed under "installed packages" are present
because they were needed as dependencies of one or both packages. So,
the two packages are the roots of the combined graph of all packages
in the environment.

^^^^^^^^^^^^^^^^^^^^^
Using packages
^^^^^^^^^^^^^^^^^^^^^

Environments provide a convenient way for you to use the installed
packages. Running ``spack env activate`` gives you everything in the
environment on your ``PATH``. Otherwise, you need to ``spack load``
or ``module load`` a package to use it.

When you install packages into an environment, they are linked into a
single prefix, or a *view*. When you *activate* the environment with
``spack env activate``, Spack adds subdirectories from the view to
``PATH``, ``LD_LIBRARY_PATH``, ``CMAKE_PREFIX_PATH`` and other
environment variables. This makes the environment easier to use.

Let's try it out. We just installed ``tcl`` into our ``myproject``
environment, which includes a shell-like application called ``tclsh``.
You can see ``tclsh`` in your ``PATH`` immediately:

.. literalinclude:: outputs/environments/use-tcl-1.out
   :language: console
   :emphasize-lines: 1


Notice the path includes the name of our environment *and* a ``view``
subdirectory.

You can run ``tclsh`` like you would any other program that is in your
path:

.. code-block:: console

	$ tclsh
	% echo "hello world!"
	hello world!
	% exit

Similarly, you can run some of Trilinos' programs, such as ``algebra``:

.. literalinclude:: outputs/environments/use-trilinos-1.out
   :language: console
   :emphasize-lines: 1,3


^^^^^^^^^^^^^^^^^^^^^
Uninstalling packages
^^^^^^^^^^^^^^^^^^^^^

We can also uninstall a package from an environment without affecting
other environments because Spack shares common installations. To
demonstrate this, suppose ``myproject`` requires ``trilinos`` but
we have another project that has it installed but no longer requires it.

Let's set up the environment for that second project by creating
an environment with installed packages that we'll call ``myproject2``:

.. literalinclude:: outputs/environments/env-create-2.out
   :language: console
   :emphasize-lines: 1,6-7,9,11


Notice that root specs display *exactly* as we asked for them on the
command line. In this case, ``hdf5`` shows the ``+hl`` requirement.

Now we have two environments. The ``myproject`` environment has ``tcl``
and ``trilinos`` while the ``myproject2`` environment has ``hdf5 +hl``
and ``trilinos``.

Now let's uninstall ``trilinos`` from ``myproject2``:

.. literalinclude:: outputs/environments/env-uninstall-1.out
   :language: console
   :emphasize-lines: 1,10


The result is that the environment has only one root spec, ``hdf5 +hl``,
and it requires fewer dependencies.

However, we know ``trilinos`` is still needed for the ``myproject``
environment. So let's switch back to confirm that it is still installed
in that environment.

.. literalinclude:: outputs/environments/env-swap-1.out
   :language: console
   :emphasize-lines: 1-3


Phew! Spack uses reference counting so knows that ``trilinos`` is
still installed in ``myproject``.

.. note::

   Trilinos would only have been uninstalled by Spack if it were no
   longer needed by any environments *or* packages.

-------------------------------
Dealing with Many Specs at Once
-------------------------------

In the above examples, we just used ``install`` and ``uninstall``. There
are other ways to deal with groups of packages, as well.

^^^^^^^^^^^^^
Adding specs
^^^^^^^^^^^^^

While we're still in ``myproject``, let's *add* a few specs instead of installing them:

.. literalinclude:: outputs/environments/add-1.out
   :language: console

Let's take a close look at what happened. The two requirements we added,
``hdf5 +hl`` and ``gmp``, are present, but they're not installed in the
environment yet. ``spack add`` just adds *roots* to the environment, but
it does not automatically install them.

We can install *all* the as-yet uninstalled packages in an environment by
simply running ``spack install`` with no arguments:

.. literalinclude:: outputs/environments/add-2.out
   :language: console


Spack will concretize the new roots, and install everything you added to
the environment. Now we can see the installed roots in the output of
``spack find``:

.. literalinclude:: outputs/environments/add-3.out
   :language: console


We can build whole environments this way, by adding specs and installing
all at once, or we can install them with the usual ``install`` and
``uninstall`` portions. The advantage to doing them all at once is that
we don't have to write a script outside of Spack to automate this, and we
can kick off a large build of many packages easily.

^^^^^^^^^^^^^
Configuration
^^^^^^^^^^^^^

An environment is more than just a list of root specs. It includes
*configuration* settings that affect the way Spack behaves when the
environment is activated. So far, ``myproject`` relies on configuration
defaults that can be overriden.

If you run ``spack spec``, you can see that concretization
looks the same as it does outside the environment:

.. literalinclude:: outputs/environments/spec-1.out
   :language: console

We can customize this using `concretization preferences
<https://spack.readthedocs.io/en/latest/build_settings.html#concretization-preferences>`_
-- special configuration that changes the behavior of the concretizer.

Let's start by looking at the configuration of your environment. You can see
how your environment is configured using ``spack config get``:

.. literalinclude:: outputs/environments/config-get-1.out
   :language: console
   :emphasize-lines: 1

The output shows the special YAML configuration format that Spack uses to store
the state of your environment. Currently, the file is just a ``spack:`` header
and a list of ``specs``. These are the roots.

You can edit this file to add your own custom configuration. Spack
provides a shortcut to do that:

.. code-block:: console

   spack config edit

You should now see the same file in your editor. Change it to look like this:

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


We will learn much more in the :ref:`configuration section <configs-tutorial>`,
but for now, all you need to know is that this changes the default ``mpi``
provider. That is, if a package depends on ``mpi``, Spack will now satisfy that
dependency with ``mpich`` instead of the default ``openmpi``.

To see what this looks like, run ``spack spec`` again in the environment. You
can see that the spec concretizes with ``mpich`` as the MPI implementation:

.. literalinclude:: outputs/environments/spec-2.out
   :language: console


In addition to the ``packages`` section, an environment can contain many other
types of configuration. You can add custom package repositories, a custom
install location, custom compilers, custom external packages, and more. There
are also ways to build workflows for CI and for software development using
environment configuration, which we'll learn later in the tutorial.

Right now, though, we have a problem. We already installed part of this
environment with openmpi, but now we want to install everything with ``mpich``.

You can run ``spack concretize --force`` inside of an environment to concretize
all of its specs. We can run it here:

.. literalinclude:: outputs/environments/concretize-f-1.out
   :language: console


Now, all the specs in the environment are concrete and ready to be
installed with ``mpich`` as the MPI implementation.

Normally, we could just run ``spack config edit``, edit the environment
configuration, ``spack add`` some specs, and ``spack install``.

But, when we already have installed packages in the environment, we have
to force everything in the environment to be re-concretized using ``spack
concretize --force``. *Then* we can re-run ``spack install``.

---------------------------------
Building in environments
---------------------------------

You can use environments to set up a development environment. With
the environment activated, you can invoke any programs installed in
the environment. Suppose you wanted to compile some MPI programs. This
environment happens to have ``mpicc`` installed:

.. literalinclude:: outputs/environments/show-mpicc-1.out
   :language: console


In addition, activating the environment has set variables like ``CPATH``,
``LIBRARY_PATH``, and ``LD_LIBRARY_PATH``, so that you can easily find headers
and libraries from programs in the environment.

.. literalinclude:: outputs/environments/show-paths-1.out
   :language: console


Let's use this to build a really simple MPI program. Make a simple test program
like this one. Call it ``mpi-hello.c``.

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

This program includes a header from zlib, and prints out a message from each
MPI rank. It also prints the zlib version.

All you need to do is build and run it:

.. literalinclude:: outputs/environments/use-mpi-1.out
   :language: console


Notice that we did not need to pass any special arguments to the
compiler; just the source file. We also see that ``Hello world``
is output for each of the ranks and the version of ``zlib`` used
to build the program. 

We can confirm the version of ``zlib`` is in our environment using
``spack find``:

.. literalinclude:: outputs/environments/myproject-zlib-1.out
   :language: console
   :emphasize-lines: 1

Notice that the reported versions match.

This simple example only scratches the surface of what we can do
with environments. We will present some advanced use cases in the
:ref:`developer workflows <developer-workflows-tutorial>` tutorial.


-----------------
Environment Files
-----------------

Spack environments provide users with *virtual environments* (think 
python and conda), where packages in one environment can be segregated
from those of another. The command line interface we have been using
so far allows packages to be installed and uninstalled in one environment
without interfering with the environments of other projects but it is
not the only way to interface with environments. Environments are
defined by two key files: ``spack.yaml`` and ``spack.lock``, which
can be accessed directly.

Environments are either managed or unmanaged. *Managed environments* are
created using ``spack env create <name>``, as we've done so far. They
are automatically created in the ``var/spack/environments`` subdirectory
and can be referenced by their names. *Unmanaged environments* can be
created in any directory by putting the environment configuration files
in it or by using ``spack env create -d <directory>`` to specify the
directory in which the files should reside. These environments are not named.

Both types of environments are defined by their environment files.
The ``spack.yaml`` file contains the abstract configuration for an
environment in that it lists the required package specs and associated
configuration. It can be edited to further customize the environment.
The ``spack.lock`` file is the full set of concrete specs generated
by Spack when it concretizes the ``spack.yaml`` file.

Both environment files can be versioned in repositories, shared, and
use to install the same set of software on different machines. The files
are intended to be used by developers and administrators to manage the
environments in a reproducible way.

^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
Reviewing a managed environment
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

We created our currently active environment -- ``myproject`` --
earlier using ``spack env create myproject`` so let's mainly focus
on its environment files in this section.

Earlier, when we changed our environment's configuration using ``spack
config edit``, we were actually editing its ``spack.yaml`` file. We
can change to the directory containing the file using ``spack cd``:

.. literalinclude:: outputs/environments/filenames-1.out
   :language: console
   :emphasize-lines: 1-2,4


Notice ``myproject`` is a subdirectory of ``var/spack/environments``
within the Spack installation making it a *managed* environment.
Consequently, it can be referenced by name. For example, it will
show up when running ``spack env list``:

.. literalinclude:: outputs/environments/env-list-2.out
   :language: console
   :emphasize-lines: 1

You can see that ``myproject`` is active because it is highlighted in
green.

We can also see from the directory listing that environment directory
contains both of the key environment files: ``spack.yaml`` and ``spack.lock``.

If we look at the ``spack.yaml`` file, we'll see the same contents shown
previously by ``spack config get``:

.. literalinclude:: outputs/environments/cat-config-1.out
   :language: console
   :emphasize-lines: 1


^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
Creating an unmanaged environment
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Environments do not have to be created in a Spack instance; rather,
you can put the environment files in any directory. Let's create
an *unmanaged* environment for a simple project from scratch:

.. literalinclude:: outputs/environments/anonymous-create-1.out
   :language: console
   :emphasize-lines: 1-4


Notice the command shows Spack created the environment, updated
the view, and gave the command needed to activate it. Since the
environment is unmanaged, it must be referenced by its directory
path.

What really happened?

.. literalinclude:: outputs/environments/anonymous-create-2.out
   :language: console
   :emphasize-lines: 1,3


Spack created a ``spack.yaml`` file in the *code* directory with an
empty list (i.e., ``[]``) of root specs in the spec list.

We can confirm that it is not a managed environment by running
``spack env list``:

.. literalinclude:: outputs/environments/env-list-2.out
   :language: console
   :emphasize-lines: 1

and noting that the path does not appear in the output.

Now let's add some specs to the environment. Suppose your project
depends on ``boost``, ``trilinos``, and ``openmpi``. Add these 
packages to the spec list using your favorite text editor. Using
the dash syntax for a list, your package should now contain the
following:

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

Now we can activate the environment and install the packages:

.. literalinclude:: outputs/environments/install-anonymous-1.out
   :language: console
   :emphasize-lines: 1-2


Spack concretized the package specs, installed the packages and
their dependencies, and updated the environment's view. Since we
already installed all of these packages outside of the environment,
their links were added to our environment.

We can add and remove specs using the command line interface as before.
For example, lets add ``hdf5`` and look at our file:

.. literalinclude:: outputs/environments/add-anonymous-1.out
   :language: console
   :emphasize-lines: 1,4


Notice ``spack add`` added the package to our active environment and
it appears in the spec list.

Now use ``spack remove`` to remove it from the environment:

.. literalinclude:: outputs/environments/remove-anonymous-1.out
   :language: console
   :emphasize-lines: 1,4

and we see the spec was removed from the spec list.


^^^^^^^^^^^^^^^^^^^^^^^^
Reviewing ``spack.lock``
^^^^^^^^^^^^^^^^^^^^^^^^

Now let's turn our attention from the abstract to the concrete.
Our focus so far has been on the abstract environment configuration,
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


While it is still readable, it contains a lot more detail. There
are nearly 2000 lines in the file.

^^^^^^^^^^^^^^^^^^^^^^^^^^
Re-creating an environment
^^^^^^^^^^^^^^^^^^^^^^^^^^

Both of environment files -- ``spack.yaml`` and ``spack.lock`` -- can
be used to create a new environment from an old one. The two files
represent two fundamental concepts:

  * ``spack.yaml`` is the set of *abstract* specs and configuration that
    you want to install.
  * ``spack.lock`` is the set of all fully *concrete* specs generated from
    concretizing ``spack.yaml``

In this sense, you can think of environments as generalizations of specs,
but for sets of packages.

You to recreate an environment that someone else built by passing either
as an argument to ``spack env create``:

.. literalinclude:: outputs/environments/create-from-file-1.out
   :language: console
   :emphasize-lines: 1,6


Which file you use to recreate the environment depends on your needs:

1. ``abstract``: copying the ``spack.yaml`` file allows someone else to build
   your *requirements*, potentially a different way.

2. ``concrete``: copying the ``spack.lock`` file allows someone else to rebuild
   your *installation* exactly as you built it.

The first use case can *re-concretize* the same specs on new platforms in order
to build, but it will preserve the abstract requirements. The second use case
(currently) requires you to be on the same type of machine, but it retains all
decisions made during concretization and is faithful to a prior install.
