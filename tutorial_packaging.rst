.. Copyright 2013-2019 Lawrence Livermore National Security, LLC and other
   Spack Project Developers. See the top-level COPYRIGHT file for details.

   SPDX-License-Identifier: (Apache-2.0 OR MIT)

.. _packaging-tutorial:

=========================
Package Creation Tutorial
=========================

This tutorial will walk you through the steps behind building a simple
package installation script. We'll focus on writing a package for
mpileaks, an MPI debugging tool. By creating a package file we're
essentially giving Spack a recipe for how to build a particular piece of
software. We're describing some of the software's dependencies, where to
find the package, what commands and options are used to build the package
from source, and more. Once we've specified a package's recipe, we can
ask Spack to build that package in many different ways.

This tutorial assumes you have a basic familiarity with some of the Spack
commands, and that you have a working version of Spack installed. If
not, we suggest looking at Spack's
`Getting Started <https://spack.readthedocs.io/en/latest/getting_started.html#getting-started>`_
guide. This tutorial also assumes you have at least a beginner's-level
familiarity with Python.

Also note that this document is a tutorial. It can help you get started
with packaging, but is not intended to be complete. See Spack's
`Packaging Guide <https://spack.readthedocs.io/en/latest/packaging_guide.html#packaging-guide>`_
for more complete documentation on this topic.

---------------
Getting Started
---------------

A few things before we get started:

- We'll refer to the Spack installation location via the environment
  variable ``SPACK_ROOT``. You should point ``SPACK_ROOT`` at wherever
  you have Spack installed.
- Add ``$SPACK_ROOT/bin`` to your ``PATH`` before you start.
- Make sure your ``EDITOR`` environment variable is set to your
  preferred text editor.
- We'll be writing Python code as part of this tutorial. You can find
  successive versions of the Python code at
  https://github.com/spack/spack-tutorial under ``tutorial/examples``.

We will use a separate package repository for the tutorial. Package
repositories allow you to separate sets of packages that take
precedence over one another. We will use the tutorial repo that ships
with Spack to avoid breaking the builtin Spack packages.

.. literalinclude:: outputs/packaging/repo-add.out
   :language: console

-------------------------
Creating the Package File
-------------------------

Spack comes with a handy command to create a new package: ``spack create``.
This command is given the location of a package's source code, downloads
the code, and sets up some basic packaging infrastructure for you. The
mpileaks source code can be found on GitHub, and here's what happens when
we run ``spack create`` on it:

.. literalinclude:: outputs/packaging/create.out
   :language: console

Spack should spawn a text editor with this file:

.. literalinclude:: tutorial/examples/0.package.py
   :caption: tutorial/examples/0.package.py
   :language: python

Spack has created this file in
``$SPACK_ROOT/var/spack/repos/tutorial/packages/mpileaks/package.py``.
Take a moment to look over the file. There are a few placeholders that
Spack has created, which we'll fill in as part of this tutorial:

* We'll document some information about this package in the comments.
* We'll fill in the dependency list for this package.
* We'll fill in some of the configuration arguments needed to build this
  package.

For the moment, exit your editor and let's see what happens when we try
to build this package:

.. literalinclude:: outputs/packaging/install-mpileaks-1.out
   :language: console

This obviously didn't work; we need to fill in the package-specific
information. Specifically, Spack didn't try to build any of mpileaks'
dependencies, nor did it use the proper configure arguments. Let's start
fixing things.

---------------------
Package Documentation
---------------------

We can bring the ``package.py`` file back into our ``$EDITOR`` with the
``spack edit`` command:

.. code-block:: console

   $ spack edit mpileaks

Let's remove some of the ``FIXME`` comments, add a link to the mpileaks
homepage, and document what mpileaks does. Let's also add a maintainer
to the package. The ``maintainers`` field is a comma-separated list of
GitHub accounts of users who want to be notified when a change is made
to a package. This is useful for developers who maintain a Spack package
for their own software, and for users who rely on a piece of software
and want to ensure that the package doesn't break.

I'm also going to cut out the Copyright clause at this point to keep
this tutorial document shorter, but you shouldn't do that normally.
Make these changes to your ``package.py``:

.. literalinclude:: tutorial/examples/1.package.py
   :caption: tutorial/examples/1.package.py
   :lines: 6-
   :language: python

We've filled in the comment that describes what this package does and
added a link to its website. That won't help us build yet, but it will
allow Spack to provide some documentation on this package to other users:

.. literalinclude:: outputs/packaging/info-mpileaks.out
   :language: console

As we fill in more information about this package the ``spack info`` command
will become more informative. Now let's start making this package build.

------------
Dependencies
------------

The mpileaks package depends on three other packages: ``mpi``,
``adept-utils``, and ``callpath``. Let's add those via the
``depends_on`` command in our ``package.py``.

.. literalinclude:: tutorial/examples/2.package.py
   :caption: tutorial/examples/2.package.py
   :lines: 6-
   :language: python

Now when we go to build mpileaks, Spack will fetch and build these
dependencies before building mpileaks. Normally, we would also need
to create ``package.py`` recipes for these dependencies as well.
Luckily, all of these dependencies are already in Spack.

Note that the mpi dependency is a different kind of beast than the
adept-utils and callpath dependencies; there is no mpi package
available in Spack. Instead mpi is a *virtual dependency*. Spack may
satisfy that dependency by installing packages such as ``openmpi`` or
``mvapich2``. See the
`Packaging Guide <https://spack.readthedocs.io/en/latest/packaging_guide.html#packaging-guide>`_
for more information on virtual dependencies.

Now when we try to install this package, a lot more happens:

.. literalinclude:: outputs/packaging/install-mpileaks-2.out
   :language: console

Note that this command may take a while to run and produce more output if
you don't have an MPI already installed or configured in Spack.

Now Spack has identified and made sure all of our dependencies have been
built. It found the ``openmpi`` package that will satisfy our ``mpi``
dependency, and the ``callpath`` and ``adept-utils`` package to satisfy our
concrete dependencies.

------------------------
Debugging Package Builds
------------------------

Our ``mpileaks`` package is still not building. For experienced
Autotools developers, the problem and its solution may be obvious.
But let's instead use this opportunity to spend some time debugging.
We have a few options that can tell us about what's going wrong:

As per the error message, Spack has given us a ``spack-build-out.txt`` debug
log:

.. code-block:: console

   ==> Executing phase: 'autoreconf'
   ==> Executing phase: 'configure'
   ==> [2019-11-17-19:25:30.481411] '/tmp/spack/spack-stage/spack-stage-mpileaks-1.0-g4wqm3n33mzlxww6vgs6piu4gm5bvnb2/spack-src/configure' '--prefix=/home/spack/spack/opt/spack/linux-ubuntu18.04-x86_64/gcc-7.4.0/mpileaks-1.0-g4wqm3n33mzlxww6vgs6piu4gm5bvnb2'
   checking metadata... no
   checking installation directory variables... yes
   checking for a BSD-compatible install... /usr/bin/install -c
   checking whether build environment is sane... yes
   checking for a thread-safe mkdir -p... /bin/mkdir -p
   checking for gawk... no
   checking for mawk... mawk
   checking whether make sets $(MAKE)... yes
   checking for gcc... /home/spack/spack/lib/spack/env/gcc/gcc
   checking for C compiler default output file name... a.out
   checking whether the C compiler works... yes
   checking whether we are cross compiling... no
   checking for suffix of executables...
   checking for suffix of object files... o
   checking whether we are using the GNU C compiler... yes
   checking whether /home/spack/spack/lib/spack/env/gcc/gcc accepts -g... yes
   checking for /home/spack/spack/lib/spack/env/gcc/gcc option to accept ISO C89... none needed
   checking for style of include used by make... GNU
   checking dependency style of /home/spack/spack/lib/spack/env/gcc/gcc... gcc3
   checking whether /home/spack/spack/lib/spack/env/gcc/gcc and cc understand -c and -o together... yes
   checking whether we are using the GNU C++ compiler... yes
   checking whether /home/spack/spack/lib/spack/env/gcc/g++ accepts -g... yes
   checking dependency style of /home/spack/spack/lib/spack/env/gcc/g++... gcc3
   checking for /home/spack/spack/opt/spack/linux-ubuntu18.04-x86_64/gcc-7.4.0/openmpi-3.1.4-f6maodnm53tkmchq5woe33nt5wbt2tel/bin/mpicc... /home/spack/spack/opt/spack/linux-ubuntu18.04-x86_64/gcc-7.4.0/openmpi-3.1.4-f6maodnm53tkmchq5woe33nt5wbt2tel/bin/mpicc
   Checking whether /home/spack/spack/opt/spack/linux-ubuntu18.04-x86_64/gcc-7.4.0/openmpi-3.1.4-f6maodnm53tkmchq5woe33nt5wbt2tel/bin/mpicc responds to '-showme:compile'... yes
   configure: error: unable to locate adept-utils installation

This gives us the output from the build, and mpileaks isn't finding
its ``adept-utils`` dependency. Spack has automatically added the
include and library directories of ``adept-utils`` to the compiler's
search path, but some packages like mpileaks can sometimes be picky
and still want things spelled out on the command line. But let's
continue to pretend we're not experienced developers, and explore
some other debugging paths.

We can also enter the build area and try to manually run the build:

.. code-block:: console

  $ spack cd mpileaks
  $ spack build-env mpileaks bash

The ``spack build-env`` command spawns a new shell that contains the
same environment that Spack used to build the mpileaks package (you
can substitute bash for your favorite shell). The ``spack cd`` command
changed our working directory to the last attempted build for mpileaks.
From here we can manually re-run the build:

.. literalinclude:: outputs/packaging/build-env-configure.out
   :language: console

We're seeing the same error, but now we're in a shell where we can run
the command ourselves and debug as needed. We could, for example, run
``./configure --help`` to see what options we can use to specify
dependencies.

We can use the ``exit`` command to leave the shell spawned by ``spack
build-env``.

------------------------------
Specifying Configure Arguments
------------------------------

Let's add the configure arguments to the mpileaks' ``package.py``.

.. literalinclude:: tutorial/examples/3.package.py
   :caption: tutorial/examples/3.package.py
   :lines: 6-
   :language: python

This is all we need for a working mpileaks package! If we install now we'll see:

.. literalinclude:: outputs/packaging/install-mpileaks-3.out
   :language: console

--------
Variants
--------

We have a successful mpileaks build, but let's take some time to improve
it. ``mpileaks`` has a build-time option to truncate parts of the stack
that it walks. Let's add a variant to allow users to set this when they
build mpileaks with Spack.

To do this, we'll add a variant to our package, as per the following:

.. literalinclude:: tutorial/examples/4.package.py
   :caption: tutorial/examples/4.package.py
   :lines: 6-
   :language: python

We've added the variant ``stackstart``, and given it a default value of
``0``. If we install now we can see the stackstart variant added to the
configure line (output truncated for length):


.. literalinclude:: outputs/packaging/install-mpileaks-4.out
   :language: console

---------------
The Spec Object
---------------

This tutorial has glossed over a few important features, which weren't
too relevant for mpileaks but may be useful for other packages. There
were several places we reference the ``self.spec`` object. This is a
powerful class for querying information about what we're building. For
example, you could use the spec to query information about how a
package's dependencies were built, or what compiler was being used, or
what version of a package is being installed. Full documentation can be
found in the
`Packaging Guide <https://spack.readthedocs.io/en/latest/packaging_guide.html#packaging-guide>`_,
but here's some quick snippets with common queries:

- Am I building ``mpileaks`` version ``1.1`` or greater?

.. code-block:: python

   if self.spec.satisfies('@1.1:'):
       # Do things needed for 1.1+

- Is ``openmpi`` the MPI I'm building with?

.. code-block:: python

   if self.spec['mpi'].name == 'openmpi':
       # Do openmpi things

- Am I building with ``gcc`` version less than ``5.0.0``:

.. code-block:: python

   if self.spec.satisfies('%gcc@:5.0.0'):
       # Add arguments specific to gcc's earlier than 5.0.0

- Am I building with the ``debug`` variant:

.. code-block:: python

   if '+debug' in self.spec:
       # Add -g option to configure flags

- Is my ``dyninst`` dependency greater than version ``8.0``?

.. code-block:: python

   if self.spec['dyninst'].satisfies('@8.0:'):
       # Use newest dyninst options

More examples can be found in the thousands of packages already added to
Spack in ``$SPACK_ROOT/var/spack/repos/builtin/packages``.

Good Luck!

-----------
Cleaning Up
-----------

To ensure that future sections of the tutorial run properly, please
uninstall mpileaks and remove the tutorial repo from your
configuration.

.. literalinclude:: outputs/packaging/cleanup.out
   :language: console
