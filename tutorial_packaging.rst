.. Copyright 2013-2020 Lawrence Livermore National Security, LLC and other
   Spack Project Developers. See the top-level COPYRIGHT file for details.

   SPDX-License-Identifier: (Apache-2.0 OR MIT)

.. _packaging-tutorial:

=========================
Package Creation Tutorial
=========================

This tutorial walks you through the steps behind building and 
debugging a new, simple package installation script.
We are using ``mpileaks``, an MPI debugging tool, as our example.
An iterative approach is taken to develop and debug the package
to gain more experience with additional Spack commands.

Installation scripts are essentially recipes for building software.
They define properties and behavior of the build, such as:

- where to find and how to retrieve the software;
- its dependencies;
- options for building the software from source; and
- build commands.

This information is coded into a package and provides the flexibility
needed for build portability and feature variability using Spack.
In other words, once we've specified a package's recipe, we can
ask Spack to build that package on different systems and with different
features.

-------
Caveats
-------

This tutorial assumes you have a basic familiarity with some of the
Spack commands and a working version of Spack installed. Refer to the
`Getting Started <https://spack.readthedocs.io/en/latest/getting_started.html#getting-started>`_
guide for information on how to install Spack.

We'll be writing code so it is assumed you have at least a
beginner's-level familiarity with Python.
Successive versions of the Python code examples used here can be found at
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
  location so you should set it to that path;
- ``PATH``:  Add ``$SPACK_ROOT/bin`` to your ``PATH`` before you start so
  calls to the ``spack`` command work; and
- ``EDITOR``: Ensure this variable is set to your preferred text editor so
  Spack can bring it up when we modify the package.

It is important that we sandbox the effects of this tutorial from
built-in packages and the other tutorials.
We can accomplish this with a package repository, which is used to separate
sets of packages with precedence rules.
More information on that topic, including overriding other repositories, can
be found at
`Package Repositories <https://spack.readthedocs.io/en/latest/repositories.html>`_ .

Spack ships with a tutorial repository that we can use to override built-in
packages. Tell Spack to add the tutorial repository to its list by entering
the following:

.. literalinclude:: outputs/packaging/repo-add.out
   :language: console

This command will ensure you are working in the tutorial repository.

-------------------------
Creating the Package File
-------------------------

Now that we have our environment set up for this tutorial, we can create
our package.
Spack comes with a handy command for this purpose, ``spack create``.
The command takes the location of the package's source code and uses it
to fetch the code, create a suitable package skeleton, and open the file
up in your editor of choice.

The ``mpileaks`` source code can be found on GitHub in a tar file.
Spack will look at the contents of the tar file and generate a package
when we run ``spack create`` with its URL.

.. literalinclude:: outputs/packaging/create.out
   :language: console

A text editor should have been spawned for the resulting ``package.py`` file
with the following contents:

.. literalinclude:: tutorial/examples/0.package.py
   :caption: mpileaks/package.py (from tutorial/examples/0.package.py)
   :language: python

The file itself should now reside in the suitably named packages subdirectory
of the tutorial repository we added above, i.e.,
``$SPACK_ROOT/var/spack/repos/tutorial/packages/mpileaks/package.py``

Take a moment to look over the file. Spack created a few placeholders that
we will fill in as we:

- document some information about this package;
- add dependencies; and
- add the configuration arguments needed to build the package.

For the moment, let's see what Spack does with the skeleton.
Exit your editor and try to build the package with the ``spack install``
command:

.. literalinclude:: outputs/packaging/install-mpileaks-1.out
   :language: console

This obviously didn't work. 

We need to fill in package-specific build information. Specifically,
Spack didn't try to build any of mpileaks' dependencies, nor did it
use the proper configure arguments because we haven't provided that
information.

Let's start fixing things.

----------------------------
Adding Package Documentation
----------------------------

We'll take an iterative approach to filling in the skeleton starting with
the documentation.

Bring mpileaks' ``package.py`` file back into your ``$EDITOR`` with the
``spack edit`` command:

.. code-block:: console

   $ spack edit mpileaks

Let's make the following changes:

- remove the instructions at the top and some of the ``FIXME`` comments;
- document what mpileaks does in the docstring;
- replace the homepage property with the correct link;
- uncomment maintainers; and
- add your GitHub user name.

The ``maintainers`` field is a comma-separated list of GitHub user names for
those people who want to be notified when a change is made to the package.
This is useful for developers who maintain a Spack package for their own
software. Users who rely on a piece of software that they want to ensure
doesn't break their build are also typically interested in being included
as maintainers.

You can also cut out the Copyright clause at this point to keep the tutorial
document shorter; however, that is not normally appropriate for a published
package.

Now make the changes and additions to your ``package.py`` file:

.. literalinclude:: tutorial/examples/1.package.py
   :caption: mpileaks/package.py (from tutorial/examples/1.package.py)
   :lines: 6-
   :language: python

At this point we've only updated key documentation within the package.
It won't help us build the software but the information is now available
for others.

Let's see what is reported by entering the ``spack info`` command:

.. literalinclude:: outputs/packaging/info-mpileaks.out
   :language: console

Take a moment to look over the output. You should see the following
information derived from the package:

- it is an Autotools package;
- it has the description, homepage, and maintainer(s) we provided;
- it has the URL we gave the ``spack create`` command;
- there is a version and full hash Spack derived from the code; and
- the default Autotools package installation phases are listed.

There are also entries for the different types of dependencies.
We don't currently have any specified so they are each reported
as ``None``.

As we fill in more information about the package, the ``spack info``
command will become more informative.

Now let's start adding important build information.

-------------------
Adding Dependencies
-------------------

First we'll add the dependencies.
The ``mpileaks`` software requires three packages:

- ``mpi``,
- ``adept-utils``, and
- ``callpath``. 

Luckily, all of these dependencies are already built-in packages in Spack;
otherwise, we would have to create packages for them as well.

Let's add those dependencies to our ``package.py`` file using the
``depends_on`` directive:

.. literalinclude:: tutorial/examples/2.package.py
   :caption: mpileaks/package.py (from tutorial/examples/2.package.py)
   :lines: 6-
   :language: python

Adding dependencies tells Spack that it must ensure these packages are
installed *before* it can build our package.

It is worth noting that ``mpi`` is different than the other two dependencies.
Specifically, there is no mpi package available in Spack since mpi is
a *virtual dependency*. That means Spack must satisfy the dependency with
a concrete package that provides ``mpi`` functionality, such as ``openmpi``
or ``mvapich2``. See the
`Packaging Guide <https://spack.readthedocs.io/en/latest/packaging_guide.html#packaging-guide>`_
for more information on virtual dependencies.

We now get a lot further in the build process when we try to install the 
package again:

.. literalinclude:: outputs/packaging/install-mpileaks-2.out
   :language: console

Note that this command may take a while to run. It may also produce more
output if you don't already have an MPI installed or configured in Spack.

We see that Spack has now identified and made sure all of our dependencies
have been built. It found that the ``openmpi`` package will satisfy our ``mpi``
dependency. It also determined that the ``callpath`` and ``adept-utils``
packages satisfy our concrete dependencies.

But we are still not able to build the package.

------------------------
Debugging Package Builds
------------------------

Our ``mpileaks`` package is still not building due to the configure
error related to the ``adept-utils`` package. Experienced Autotools
developers will likely already see the problem and its solution.

But let's take this opportunity use Spack features for debugging package
builds. We have a couple of options for investigating the problem:

- review the build log; and
- build the package manually.

~~~~~~~~~~~~~~~~~~~~~~~
Reviewing the Build Log
~~~~~~~~~~~~~~~~~~~~~~~

The build log might yield some clues so let's look at the contents of
the ``spack-build-out.txt`` file at the path recommended above by our
failed installation:

.. literalinclude:: outputs/packaging/build-output.out
   :language: console

Here we see a number of checks performed by the configure command. And,
at the very bottom, the same error reported during the installation
attempt. Specifically, configure cannot find the installation of its
``adept-utils`` dependency. 

Spack automatically adds the include and library directories to the
compiler's search path but that information is not getting picked up
for this package. This is not an uncommon occurrence. Some packages
want options like paths spelled out on the command line.

So let's investigate further from the staged build directory.

~~~~~~~~~~~~~~~~~
Building Manually
~~~~~~~~~~~~~~~~~

First let's try to build the package manually to see if we can
figure out how to solve the problem. Spack provides some useful
commands for this purpose.

Use the following commands to move to the build directory and set up
the environment:

.. code-block:: console

  $ spack cd mpileaks
  $ spack build-env mpileaks bash

The ``spack cd`` command changed our working directory to the last
attempted build for mpileaks.
The ``spack build-env`` command spawned a new shell containing the
same environment that Spack used to build the mpileaks package.
(Feel free to substitute your favorite shell for ``bash``.)

From here we can manually re-run the build using the ``configure``
command:

.. literalinclude:: outputs/packaging/build-env-configure.out
   :language: console

Unfortunately, all we see is the same error.

Given this is a simple package built with configure and we know
the installation directories need to be specified, we can see what
options are available for us to provide the paths by getting configure
help as follows:

.. code-block:: console

  $ ./configure --help

Note that you can specify configure path options for a dependency by
prefacing the dependency name with ``--with-``.

Leave the spawned shell and return to the Spack repository directory:

.. code-block:: console

  $ exit
  $ cd $SPACK_ROOT

Now we know what arguments to provide to configure we can add them.

------------------------------
Specifying Configure Arguments
------------------------------

Let's add the arguments to the ``package.py`` file to specify the
installation paths for the two concrete dependencies.

We know what options we want to use, but how do we know where to find
the installation paths for the dependencies?

We can get that information by querying the package's Spec instance.
The ``self.spec`` field holds the package's directed acyclic graph (DAG)
of its dependencies. Each dependency's Spec, accessed using its name,
has a ``prefix`` property with that information.

So let's add the configuration arguments for specifying the paths to
the two concrete dependencies in the ``configure_args`` method of our
package:

.. literalinclude:: tutorial/examples/3.package.py
   :caption: mpileaks/package.py (from tutorial/examples/3.package.py)
   :lines: 6-
   :language: python

Now let's try the build again:

.. literalinclude:: outputs/packaging/install-mpileaks-3.out
   :language: console

Success!

All we needed to do was add those path arguments for configure to
perform a simple, no frills build.

But is that all we can do for this package?

---------------
Adding Variants
---------------

What if we want to allow users to take advantage of a package's optional
features? 

This is where variants come in. Like many packages, mpileaks has features
that can be added at build time. Specifically, ``mpileaks`` has build-time
options to truncate stack traces. This option is used to reduce the noise
of internal mpileaks library function calls in stack traces.

From https://github.com/LLNL/mpileaks we know there are separate configure
options for C and FORTRAN:

- ``--with-stack-start-c``
- ``--with-stack-start-fortran``

These options take non-negative integer values representing the numbers
of calls to shave off of the top of stack traces for each language.
For simplicity, we'll use one variant to supply the value for both options.

Supporting this optional feature will require two changes to the package:

- add a variant directive; and
- change the configure options to use the value.

Let's add the variant to expect an ``int`` value with a default of
``0``. Also change ``configure_args`` to retrieve the value and add
the corresponding arguments when a non-zero value is provided by the user.

.. literalinclude:: tutorial/examples/4.package.py
   :caption: mpileaks/package.py (from tutorial/examples/4.package.py)
   :lines: 6-
   :language: python

Notice the variant directive is retained as a ``variants`` dictionary
in ``self.spec``. Also note the value provided by the user is accessed
by the entry's ``value`` property.

Now run the installation again with the ``--verbose`` install option -- to
get more output during the build -- and the ``stackstart`` package option
we added above:

.. literalinclude:: outputs/packaging/install-mpileaks-4.out
   :language: console

Notice the addition of the two stack start options in the command that
appears in the line after mpileaks' ``Executing phase: 'configure'``.

At this point we've covered how to create a package; update its
documentation; add dependencies; and add variants for optional features.

What if you need to customize the build to reflect feature changes?

------------------------
Querying the Spec Object
------------------------

As packages evolve and are ported to different systems, the builds 
often have to reflect those changes. This is where the package's Spec
comes in.

So far we've looked at getting the paths for dependencies and values from
variants from the Spec but there is more. The package's Spec, ``self.spec``,
field allows you to query information about the package being built. The
information includes:

- how a package's dependencies were built;
- what compiler was being used;
- what version of a package is being installed; and
- what variants were specified.

Full documentation can be found in the
`Packaging Guide <https://spack.readthedocs.io/en/latest/packaging_guide.html#packaging-guide>`_,
but examples of common queries are provided below.

~~~~~~~~~~~~~~~~~~~~~~
Querying Spec Versions
~~~~~~~~~~~~~~~~~~~~~~

You can customize the build based on the version of the package, compiler,
and dependencies. Examples of each are:

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

~~~~~~~~~~~~~~~~~~~
Querying Spec Names
~~~~~~~~~~~~~~~~~~~

If the build has to be customized to the concrete version of an abstract
Spec you can use the Spec's ``name`` property. For example:

- Is ``openmpi`` the MPI I'm building with?

.. code-block:: python

   if self.spec['mpi'].name == 'openmpi':
       # Do openmpi things

~~~~~~~~~~~~~~~~~
Querying Variants
~~~~~~~~~~~~~~~~~

Adjusting build options based on enabled variants can be made by querying
the Spec itself, such as:

- Am I building with the ``debug`` variant:

.. code-block:: python

   if '+debug' in self.spec:
       # Add -g option to configure flags


These are just a few examples of Spec queries. Spack has thousands of
built-in packages that can serve as examples to guide the development
of your package. You can find these packages in 
``$SPACK_ROOT/var/spack/repos/builtin/packages``.

Good Luck!

-----------
Cleaning Up
-----------

Before leaving this tutorial, let's ensure that future sections run
properly. You'll want to undo the work we've done here by entering
the following commands:

.. literalinclude:: outputs/packaging/cleanup.out
   :language: console
