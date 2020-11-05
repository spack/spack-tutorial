.. Copyright 2013-2020 Lawrence Livermore National Security, LLC and other
   Spack Project Developers. See the top-level COPYRIGHT file for details.

   SPDX-License-Identifier: (Apache-2.0 OR MIT)

.. _packaging-tutorial:

=========================
Package Creation Tutorial
=========================

This tutorial will walk you through the steps behind building and 
debugging a new, simple package installation script.
We will use ``mpileaks``, an MPI debugging tool, as our example.
An iterative approach is taken to develop and debug the package
that allows us to gain experience with additional Spack commands.

Installation scripts are essentially recipes for building software.
They define properties and behavior of the build, such as:

- where to find and how to retrieve the software;
- its dependencies;
- options for building it from source; and
- build commands.

This information is coded into a package and provides the flexibility
needed for build portability and variability using Spack.
In other words, once we've specified a package's recipe, we can
ask Spack to build that package on different systems and in many different
ways.

-----------
Assumptions
-----------

This tutorial assumes you have a basic familiarity with some of the Spack
commands, and that you have a working version of Spack installed. If
not, we suggest looking at Spack's
`Getting Started <https://spack.readthedocs.io/en/latest/getting_started.html#getting-started>`_
guide. 

We'll be writing code as part of this tutorial so it is assumed
you have at least a beginner's-level familiarity with Python.
Successive versions of the Python code can be found at
https://github.com/spack/spack-tutorial under ``tutorial/examples``.

Also note that this document is a tutorial. It can help you get started
with packaging, but is not intended to be complete. See Spack's
`Packaging Guide <https://spack.readthedocs.io/en/latest/packaging_guide.html#packaging-guide>`_
for more complete documentation on this topic.

---------------
Getting Started
---------------

Before we get started you need to confirm you have three environment variables
set properly:

- ``SPACK_ROOT``: We'll use this variable to refer to the Spack installation
  location so you should point it at wherever you have Spack installed.
- ``PATH``:  Add ``$SPACK_ROOT/bin`` to your ``PATH`` before you start so
  calls to the ``spack`` command work.
- ``EDITOR``: Ensure this variable is set to your preferred text editor so
  Spack can bring it up to edit the package.

We also want to sandbox the effects of this tutorial from built-in packages
and the other tutorials.
Spack ships with a tutorial repository to avoid breaking built-in packages.
Package repositories allow you to separate sets of packages that take
precedence over one another. 

You need to tell Spack to add the tutorial repository to its list as follows:

.. literalinclude:: outputs/packaging/repo-add.out
   :language: console

-------------------------
Creating the Package File
-------------------------

Now that we have our environment set up for this tutorial, we can create
our package.
Spack comes with a handy command to create a new package, ``spack create``,
that takes the location of the package's source code.
Spack uses the location to fetch the code, create a suitable package
skeleton, and open the file up in your editor of choice.

The mpileaks source code can be found on GitHub in a tar file.
Spack will generate the mpileaks package when we run ``spack create`` on
it.

.. literalinclude:: outputs/packaging/create.out
   :language: console

A text editor should have been spawned for the package.py file with the
following contents:

.. literalinclude:: tutorial/examples/0.package.py
   :caption: mpileaks (tutorial/examples/0.package.py)
   :language: python

with the file being created in the packages subdirectory of the tutorial
repository we added above
``$SPACK_ROOT/var/spack/repos/tutorial/packages/mpileaks/package.py``.

Take a moment to look over the file. There are a few placeholders that
Spack created, which we'll fill as we:

- document some information about this package in the comments;
- fill in the dependencies; and
- fill in some of the configuration arguments needed to build this
  package.

For the moment, let's see what Spack does with the skeleton.
Exit your editor and try to build the package with the ``spack install``
command:

.. literalinclude:: outputs/packaging/install-mpileaks-1.out
   :language: console

This obviously didn't work. We need to fill in package-specific build
information. Specifically, Spack didn't try to build any of mpileaks'
dependencies, nor did it use the proper configure arguments. Let's start
fixing things.

---------------------
Package Documentation
---------------------

We'll take an iterative approach to filling in the skeleton starting with
the documentation.
Bring mpileaks' ``package.py`` file back into your ``$EDITOR`` with the
``spack edit`` command:

.. code-block:: console

   $ spack edit mpileaks

Let's remove the instructions at the top and some of the ``FIXME`` comments;
document what mpileaks does in the docstring; replace the homepage property
with the correct link; uncomment maintainers; and add your user name.
The ``maintainers`` field is a comma-separated list of GitHub user names of
users who want to be notified when a change is made to the package.
This is useful for developers who maintain a Spack package for their own
software, and for users who rely on a piece of software that they want to
ensure doesn't break their build.
You can also cut out the Copyright clause at this point to keep
the tutorial document shorter, but you shouldn't do that normally.

Make the changes and additions to your ``package.py``:

.. literalinclude:: tutorial/examples/1.package.py
   :caption: mpileaks (tutorial/examples/1.package.py)
   :lines: 6-
   :language: python

At this point we've only updated key documentation within the package,
which won't help us to build it. However, that information does allow
Spack to provide some documentation on this package to other users by
way of the ``spack info`` command:

.. literalinclude:: outputs/packaging/info-mpileaks.out
   :language: console

Here we see the following information from the package:

- it is an Autotools package;
- the description, homepage, and maintainer(s) we entered;
- the URL we gave the ``spack create`` command;
- a version and full hash Spack derived from the code; and
- the default Autotools package installation phases.

There are also entries for the different types of dependencies 
if they appear in the package.

As we fill in more information about the ``spack info`` command
will become more informative. Now let's start making this package build.

------------
Dependencies
------------

Let's add the dependencies for mpileaks.
The software requires three other packages: ``mpi``,
``adept-utils``, and ``callpath``. Let's add those via the
``depends_on`` directive in our ``package.py``.

.. literalinclude:: tutorial/examples/2.package.py
   :caption: mpileaks (tutorial/examples/2.package.py)
   :lines: 6-
   :language: python

By adding these dependencies to the package, we are telling Spack
that it must ensure these packages are installed *before* building
mpileaks. 
Luckily, all of these dependencies are already in Spack; otherwise,
we would have to define them as well.

Note that the mpi dependency is a different kind of beast than the
adept-utils and callpath dependencies. There is no mpi package
available in Spack since mpi is a *virtual dependency*. That means Spack may
satisfy the dependency with a concrete package such as ``openmpi`` or
``mvapich2``. See the
`Packaging Guide <https://spack.readthedocs.io/en/latest/packaging_guide.html#packaging-guide>`_
for more information on virtual dependencies.

Now when we try to install this package, a lot more happens:

.. literalinclude:: outputs/packaging/install-mpileaks-2.out
   :language: console

Note that this command may take a while to run.  It may also produce more
output if you don't have an MPI already installed or configured in Spack.

Now Spack has identified and made sure all of our dependencies have been
built. It found the ``openmpi`` package that will satisfy our ``mpi``
dependency, and the ``callpath`` and ``adept-utils`` packages to satisfy the
concrete dependencies.

------------------------
Debugging Package Builds
------------------------

Our ``mpileaks`` package is still not building. For experienced
Autotools developers, the problem and its solution may be obvious.
But let's instead use this opportunity to spend some time using
Spack features for debugging.
We have a few options that can tell us about what's going wrong:

As per the error message, Spack has given us a ``spack-build-out.txt`` debug
log that we can look at:

.. literalinclude:: outputs/packaging/build-output.out
   :language: console

This gives us the output from the build, including the configure error
stating mpileaks isn't finding its ``adept-utils`` dependency. 

Spack has automatically added the include and library directories of
``adept-utils`` to the compiler's search path, but some packages like
mpileaks can sometimes be picky and still want things spelled out on the
command line.  So let's explore some other debugging paths.

Spack provides a command that allows us to set up the environment for
manual builds, which we can perform after entering the build area:

.. code-block:: console

  $ spack cd mpileaks
  $ spack build-env mpileaks bash

The ``spack cd`` command changed our working directory to the last
attempted build for mpileaks.
The ``spack build-env`` command spawns a new shell that contains the
same environment that Spack used to build the mpileaks package (you
can substitute bash for your favorite shell). 

From here we can manually re-run the build using the ``configure`` command:

.. literalinclude:: outputs/packaging/build-env-configure.out
   :language: console

We're seeing the same error, but now we're in a shell where we can run
the command ourselves and debug as needed. We could, for example, run
``./configure --help`` to see what options we can use to specify
dependencies.

Use the ``exit`` command to leave the shell spawned by ``spack build-env``
and ``cd`` to return to the Spack repository directory:

.. code-block:: console

  $ exit
  $ cd $SPACK_ROOT


------------------------------
Specifying Configure Arguments
------------------------------

Now that we know we need to specify configure arguments, let's add them
to the ``package.py`` for the two concrete dependencies.
The arguments require the path for each dependency.
This information can be obtained by querying the package's Spec instance,
``self.spec``, which holds the dependency's directed acyclic graph (DAG).
Each dependency's Spec has a ``prefix`` property that holds the path.

.. literalinclude:: tutorial/examples/3.package.py
   :caption: mpileaks (tutorial/examples/3.package.py)
   :lines: 6-
   :language: python


Once we add the arguments, let's try the build again:

.. literalinclude:: outputs/packaging/install-mpileaks-3.out
   :language: console

The build succeeds since all we needed to do was add the path
arguments to configure.
But this is a simple, no frills build that doesn't take advantage
of optional build features.

--------
Variants
--------

What if we want to allow users to take advantage of a package's optional
features? This is where variants come in. 
Like many packages, mpileaks has features that can be added at build time.  
So let's take some time to improve our package. 

The ``mpileaks`` software has a build-time option to truncate its stack
trace.  We're specifically looking at the stack start option that was
added to skip the function calls in the stack trace that are internal
to the mpileaks library to emphasize the application code calls.

Let's add a variant to the package to allow users to set this when they
build mpileaks with Spack.  The option takes a non-negative integer
value to represent the number of calls to shave off the top of the
stack trace.

Add the variant ``stackstart`` with a default value of ``0`` to your
package.  You'll also need to change the configure arguments to use the
value when it is provided.

.. literalinclude:: tutorial/examples/4.package.py
   :caption: mpileaks (tutorial/examples/4.package.py)
   :lines: 6-
   :language: python

Now run the installation again with the ``--verbose`` install option and 
``stackstart`` package option:

.. literalinclude:: outputs/packaging/install-mpileaks-4.out
   :language: console

Specifying the verbose option to Spack allows us to see the package option
added to the configure command in the ``configure`` installation phase of
the package.

---------------
The Spec Object
---------------

At this point we've covered how to create a package; update its
documentation; add dependencies; and add variants for optional features.  
But how do we handle build differences as the package evolves or is ported
to different systems?  This is where the package's Spec comes in.

So far we've looked at getting the paths for dependencies from the Spec
but we can get more build information from it than that.

The package's Spec, ``self.spec``, allows you to query information
about the package being built. It contains information including:

- how a package's dependencies were built;
- what compiler was being used;
- what version of a package is being installed; and
- what variants were specified.

Full documentation can be found in the
`Packaging Guide <https://spack.readthedocs.io/en/latest/packaging_guide.html#packaging-guide>`_,
but examples of common queries appear below.

~~~~~~~~~~~~~~~
Version Queries
~~~~~~~~~~~~~~~

You can customize the build based on the version of associated software:

- Am I building ``mpileaks`` version ``1.1`` or greater?

.. code-block:: python

   if self.spec.satisfies('@1.1:'):
       # Do things needed for 1.1+

- Am I building with a ``gcc`` version less than ``5.0.0``:

.. code-block:: python

   if self.spec.satisfies('%gcc@:5.0.0'):
       # Add arguments specific to gcc's earlier than 5.0.0

- Is my ``dyninst`` dependency greater than version ``8.0``?

.. code-block:: python

   if self.spec['dyninst'].satisfies('@8.0:'):
       # Use newest dyninst options

~~~~~~~~~~~~
Spec Queries
~~~~~~~~~~~~

If the build has to be customized to the concrete version of an abstract
Spec you can use the Spec's ``name`` property.

- Is ``openmpi`` the MPI I'm building with?

.. code-block:: python

   if self.spec['mpi'].name == 'openmpi':
       # Do openmpi things

~~~~~~~~~~~~~~~
Variant Queries
~~~~~~~~~~~~~~~

Adjusting build options based on enabled variants can be made by querying
the Spec itself, such as:

- Am I building with the ``debug`` variant:

.. code-block:: python

   if '+debug' in self.spec:
       # Add -g option to configure flags


These are just a few Spec query examples.  Spack has thousands of built-in
packages that can serve as examples to guide the development of your 
package.  You can find these packages in 
``$SPACK_ROOT/var/spack/repos/builtin/packages``.

Good Luck!

-----------
Cleaning Up
-----------

To ensure that future sections of the tutorial run properly, please
uninstall mpileaks and remove the tutorial repo from your
configuration.

.. literalinclude:: outputs/packaging/cleanup.out
   :language: console
