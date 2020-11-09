.. Copyright 2013-2020 Lawrence Livermore National Security, LLC and other
   Spack Project Developers. See the top-level COPYRIGHT file for details.

   SPDX-License-Identifier: (Apache-2.0 OR MIT)

.. include:: common/setup.rst

.. _environments-tutorial:

=====================
Environments Tutorial
=====================

We've shown you how to install and remove packages with Spack.  You can
use `spack install <https://spack.readthedocs.io/en/latest/basic_usage.html#cmd-spack-install>`_ to install packages,
`spack uninstall <https://spack.readthedocs.io/en/latest/basic_usage.html#cmd-spack-uninstall>`_ to remove them,
and `spack find <https://spack.readthedocs.io/en/latest/basic_usage.html#cmd-spack-find>`_ to
look at and query what is installed.  We've also shown you how to
customize Spack's installation with configuration files like
`packages.yaml <https://spack.readthedocs.io/en/latest/build_settings.html#build-settings>`_.

If you build a lot of software, or if you work on multiple projects,
managing everything in one place can be overwhelming. The default ``spack
find`` output may contain many packages, but you may want to *just* focus
on packages for a particular project.  Moreover, you may want to include
special configuration with your package groups, e.g., to build all the
packages in the same group the same way.

Spack **environments** provide a way to handle these problems.

-------------------
Environment Basics
-------------------

Let's look at the output of ``spack find`` at this point in the tutorial.

.. literalinclude:: outputs/environments/find-no-env-1.out
   :language: console


This is a complete, but cluttered view.  There are packages built with
both ``openmpi`` and ``mpich``, as well as multiple variants of other
packages, like ``zlib``.  The query mechanism we learned about in ``spack
find`` can help, but it would be nice if we could start from a clean
slate without losing what we've already done.


^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
Creating and activating environments
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

The ``spack env`` command can help.  Let's create a new environment:

.. literalinclude:: outputs/environments/env-create-1.out
   :language: console


An environment is a virtualized ``spack`` instance that you can use for a
specific purpose.  The environment also has an associated *view*, which
is a single prefix where all packages from the environment are linked.

You can see the environments we've created so far like this:

.. literalinclude:: outputs/environments/env-list-1.out
   :language: console


And you can **activate** an environment with ``spack env activate``:

.. literalinclude:: outputs/environments/env-activate-1.out
   :language: console


Once you enter an environment, ``spack find`` shows only what is in the
current environment.  We just created this environment, so we have a
clean slate -- 0 packages:

.. literalinclude:: outputs/environments/find-env-1.out
   :language: console

The ``spack find`` output is still *slightly* different.  It tells you
that you're in the ``myproject`` environment, so that you don't panic
when you see that there is nothing installed.  It also says that there
are *no root specs*.  We'll get back to what that means later.

If you *only* want to check what environment you are in, you can use
``spack env status``:

.. literalinclude:: outputs/environments/env-status-1.out
   :language: console


If you want to leave this environment and go back to normal Spack,
you can use ``spack env deactivate``.  We like to use the
``despacktivate`` alias (which Spack sets up automatically) for short:

.. literalinclude:: outputs/environments/env-status-2.out
   :language: console


Phew -- all of our packages are still installed.

^^^^^^^^^^^^^^^^^^^
Installing packages
^^^^^^^^^^^^^^^^^^^

Ok, now that we understand how creation and activation work, let's go
back to ``myproject`` and *install* a few packages:

.. literalinclude:: outputs/environments/env-install-1.out
   :language: console


We've installed ``tcl`` and ``trilinos`` in our environment, along with
all of their dependencies.  We call ``tcl`` and ``trilinos`` the
**roots** because we asked for them explicitly.  The other 20 packages
listed under "installed packages" are present because they were needed as
dependencies.  So, these are the roots of the packages' dependency graph.

^^^^^^^^^^^^^^^^^^^^^
Using packages
^^^^^^^^^^^^^^^^^^^^^

When you install packages into an environment, they are linked into a
single prefix, or a *view*.  When you *activate* the environment with
``spack env activate``, Spack adds subdirectories from the view to
``PATH``, ``LD_LIBRARY_PATH``, ``CMAKE_PREFIX_PATH`` and other
environment variables.  This makes the environment easier to use.

Without environments, you need to ``spack load`` or ``module load`` a
package in order to use it.  With environments, you can simply run
``spack env activate`` to get everything in the environment on your
``PATH``.

Let's try it out.  ``myproject`` is still the active environment, and we
just installed ``tcl``.  You can see ``tclsh`` in your ``PATH``
immediately:

.. literalinclude:: outputs/environments/use-tcl-1.out
   :language: console


And you can run it like you would any other program:

.. code-block:: console

	$ tclsh
	% echo "hello world!"
	hello world!
	% exit

Likewise, we installed Trilinos, and you can run some of its sub-programs
as well:

.. literalinclude:: outputs/environments/use-trilinos-1.out
   :language: console


^^^^^^^^^^^^^^^^^^^^^
Uninstalling packages
^^^^^^^^^^^^^^^^^^^^^

Now let's create *another* project.  We'll call this one ``myproject2``:

.. literalinclude:: outputs/environments/env-create-2.out
   :language: console


Now we have two environments: one with ``tcl`` and ``trilinos``, and
another with ``hdf5 +hl`` and ``trilinos``.  Notice that the roots display *exactly* as
we asked for them on the command line -- the ``hdf5`` for this environemnt has an
``+hl`` requirement.

We can uninstall trilinos from ``myproject2`` as you would expect:

.. literalinclude:: outputs/environments/env-uninstall-1.out
   :language: console


Now there is only one root spec, ``hdf5 +hl``, which requires fewer
additional dependencies.

However, we still needed ``trilinos`` for the ``myproject`` environment!
What happened to it?  Let's switch back and see.

.. literalinclude:: outputs/environments/env-swap-1.out
   :language: console


Spack is smart enough to realize that ``trilinos`` is still present in
the other environment.  Trilinos won't *actually* be uninstalled unless
it is no longer needed by any environments or packages.  If it is still
needed, it is only removed from the environment.

-------------------------------
Dealing with Many Specs at Once
-------------------------------

In the above examples, we just used ``install`` and ``uninstall``.  There
are other ways to deal with groups of packages, as well.

^^^^^^^^^^^^^
Adding specs
^^^^^^^^^^^^^

While we're still in ``myproject``, let's *add* a few specs instead of installing them:

.. literalinclude:: outputs/environments/add-1.out
   :language: console

Let's take a close look at what happened.  The two requirements we added,
``hdf5 +hl`` and ``gmp``, are present, but they're not installed in the
environment yet.  ``spack add`` just adds *roots* to the environment, but
it does not automatically install them.

We can install *all* the as-yet uninstalled packages in an environment by
simply running ``spack install`` with no arguments:

.. literalinclude:: outputs/environments/add-2.out
   :language: console


Spack will concretize the new roots, and install everything you added to
the environment.  Now we can see the installed roots in the output of
``spack find``:

.. literalinclude:: outputs/environments/add-3.out
   :language: console


We can build whole environments this way, by adding specs and installing
all at once, or we can install them with the usual ``install`` and
``uninstall`` portions.  The advantage to doing them all at once is that
we don't have to write a script outside of Spack to automate this, and we
can kick off a large build of many packages easily.

^^^^^^^^^^^^^
Configuration
^^^^^^^^^^^^^

So far, ``myproject`` does not have any special configuration associated
with it.  The specs concretize using Spack's defaults:

.. literalinclude:: outputs/environments/spec-1.out
   :language: console


You may want to add extra configuration to your environment.  You can see
how your environment is configured using ``spack config get``:

.. literalinclude:: outputs/environments/config-get-1.out
   :language: console


It turns out that this is a special configuration format where Spack
stores the state for the environment. Currently, the file is just a
``spack:`` header and a list of ``specs``.  These are the roots.

You can edit this file to add your own custom configuration.  Spack
provides a shortcut to do that:

.. code-block:: console

   spack config edit

You should now see the same file, and edit it to look like this:

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

Now if we run ``spack spec`` again in the environment, specs will concretize with ``mpich`` as the MPI implementation:

.. literalinclude:: outputs/environments/spec-2.out
   :language: console


In addition to the ``specs`` section, an environment's configuration can
contain any of the configuration options from Spack's various config
sections. You can add custom repositories, a custom install location,
custom compilers, or custom external packages, in addition to the ``package``
preferences we show here.

But now we have a problem.  We already installed part of this environment
with openmpi, but now we want to install it with ``mpich``.

You can run ``spack concretize`` inside of an environment to concretize
all of its specs.  We can run it here:

.. literalinclude:: outputs/environments/concretize-f-1.out
   :language: console


Now, all the specs in the environment are concrete and ready to be
installed with ``mpich`` as the MPI implementation.

Normally, we could just run ``spack config edit``, edit the environment
configuration, ``spack add`` some specs, and ``spack install``.

But, when we already have installed packages in the environment, we have
to force everything in the environment to be re-concretized using ``spack
concretize -f``.  *Then* we can re-run ``spack install``.


---------------------------------
Building in environments
---------------------------------

You've already learned about ``spack dev-build`` as a way to build a project
you've already checked out.  You can also use environments to set up a
development environment.  As mentioned, you can use any of the binaries in
the environment's view:

.. literalinclude:: outputs/environments/show-mpicc-1.out
   :language: console


Spack also sets variables like ``CPATH``, ``LIBRARY_PATH``,
and ``LD_LIBRARY_PATH`` so that you can easily find headers and libraries in
environemnts.

.. literalinclude:: outputs/environments/show-paths-1.out
   :language: console


We can use this to easily build programs.  Let's build a really simple MPI program
using this environment.  Make a simple test program like this one.  Call it ``mpi-hello.c``.

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

This program includes a header from zlib, and prints out a message from each MPI rank.
It also prints the zlib version.

All you need to do is build and run it:

.. literalinclude:: outputs/environments/use-mpi-1.out
   :language: console


Note that we did not need to pass any special arguments to the compiler; just
the source file.  This simple example only scratches the surface, but you
can use environments to set up dependencies for a project, set up a run
environment for a user, support your usual development environment, and
many other use cases.


---------------------------------
``spack.yaml`` and ``spack.lock``
---------------------------------

So far we've shown you how to interact with environments from the command
line, but they also have a file-based interface that can be used by
developers and admins to manage workflows for projects.

In this section we'll dive a little deeper to see how environments are
implemented, and how you could use this in your day-to-day development.

^^^^^^^^^^^^^^
``spack.yaml``
^^^^^^^^^^^^^^

Earlier, we changed an environment's configuration using ``spack config
edit``.  We were actually editing a special file called ``spack.yaml``.
Let's take a look.

We can get directly to the current environment's location using ``spack cd``:

.. literalinclude:: outputs/environments/filenames-1.out
   :language: console


We notice two things here.  First, the environment is just a directory
inside of ``var/spack/environments`` within the Spack installation.
Second, it contains two important files: ``spack.yaml`` and
``spack.lock``.

``spack.yaml`` is the configuration file for environments that we've
already seen, but it does not *have* to live inside Spack.  If you create
an environment using ``spack env create``, it is *managed* by
Spack in the ``var/spack/environments`` directory, and you can refer to
it by name.

You can actually put a ``spack.yaml`` file *anywhere*, and you can use it
to bundle an environment, or a list of dependencies to install, with your
project.  Let's make a simple project:

.. literalinclude:: outputs/environments/anonymous-create-1.out
   :language: console


Here, we made a new directory called *code*, and we used the ``-d``
option to create an environment in it.

What really happened?

.. literalinclude:: outputs/environments/anonymous-create-2.out
   :language: console


Spack just created a ``spack.yaml`` file in the code directory, with an
empty list of root specs.  Now we have a Spack environment, *in a
directory*, that we can use to manage dependencies.  Suppose your project
depends on ``boost``, ``trilinos``, and ``openmpi``.  You can add these
to your spec list:

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

And now *anyone* who uses the *code* repository can use this format to
install the project's dependencies.  They need only clone the repository,
``cd`` into it, and type ``spack install``:

.. literalinclude:: outputs/environments/install-anonymous-1.out
   :language: console


Spack concretizes the specs in the ``spack.yaml`` file and installs them.

So, from ``~/code``, we can actually manipulate ``spack.yaml`` using
``spack add`` and ``spack remove`` (just like managed environments):

.. literalinclude:: outputs/environments/add-anonymous-1.out
   :language: console


^^^^^^^^^^^^^^
``spack.lock``
^^^^^^^^^^^^^^

Okay, we've covered managed environments, environments in directories, and
the last thing we'll cover is ``spack.lock``. You may remember that when
we ran ``spack install``, Spack concretized all the specs in the
``spack.yaml`` file and installed them.

Whenever we concretize Specs in an environment, all concrete specs in the
environment are written out to a ``spack.lock`` file *alongside*
``spack.yaml``.  The ``spack.lock`` file is not really human-readable
like the ``spack.yaml`` file.  It is a ``json`` format that contains all
the information that we need to *reproduce* the build of an
environment:

.. literalinclude:: outputs/environments/lockfile-1.out
   :language: console


``spack.yaml`` and ``spack.lock`` correspond to two fundamental concepts
in Spack, but for environments:

  * ``spack.yaml`` is the set of *abstract* specs and configuration that
    you want to install.
  * ``spack.lock`` is the set of all fully *concretized* specs generated
    from concretizing ``spack.yaml``

Using either of these, you can recreate an environment that someone else
built.  ``spack env create`` takes an extra optional argument, which can
be either a ``spack.yaml`` or a ``spack.lock`` file:

.. literalinclude:: outputs/environments/create-from-file-1.out
   :language: console


Both of these create a new environment from the old one, but which one
you choose to use depends on your needs:

#. ``abstract``: copying the yaml file allows someone else to build your
   *requirements*, potentially a different way.

#. ``concrete``: copying the lock file allows someone else to rebuild
   your *installation* exactly as you built it.

The first use case can *re-concretize* the same specs on new platforms in
order to build, but it will preserve the abstract requirements.  The
second use case (currently) requires you to be on the same machine, but
it retains all decisions made during concretization and is faithful to a
prior install.
