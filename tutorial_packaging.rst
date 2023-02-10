.. Copyright 2013-2022 Lawrence Livermore National Security, LLC and other
   Spack Project Developers. See the top-level COPYRIGHT file for details.

   SPDX-License-Identifier: (Apache-2.0 OR MIT)

.. include:: common/setup.rst

.. _packaging-tutorial:

=========================
Package Creation Tutorial
=========================

This tutorial walks you through the steps for creating and
debugging a simple Spack package. We will develop and debug
a package using an iterative approach in order to gain more
experience with additional Spack commands. For consistency,
we will create the package for ``mpileaks``, which is an MPI
debugging tool.

------------------------
What is a Spack Package?
------------------------

Spack packages are installation scripts, which are essentially
recipes for building software.

They define properties and behavior of the build, such as:

* where to find and how to retrieve the software;
* its dependencies;
* options for building from source; and
* build commands.

Once we've specified a package's recipe, users can ask Spack to
build the software with different features on any of the supported
systems.

-------
Caveats
-------

This tutorial assumes you have a working version of Spack installed.
Refer to the `Getting Started
<https://spack.readthedocs.io/en/latest/getting_started.html#getting-started>`_
guide for information on how to install Spack.

We'll be writing code so it is assumed you have at least a
**beginner's-level familiarity with Python**.

Being a tutorial, this document can help you get started with packaging,
but it is not intended to be complete. Links to additional information
are provided at the bottom of this tutorial.
The example code snippets used in this section can be found at
https://github.com/spack/spack-tutorial under ``tutorial/examples/packaging``.

---------------
Getting Started
---------------

Before we get started, you need to confirm you have three environment
variables set as follows:

* ``SPACK_ROOT``: consisting of the path to your Spack installation;
* ``PATH``: including ``$SPACK_ROOT/bin`` (so calls to the ``spack`` command
  work); and
* ``EDITOR``: containing the path of your preferred text editor (so Spack can
  run it when we modify the package).

The first two variables are automatically set by ``setup-env.sh`` so, if they
aren't, run the following command:

.. code-block:: console

   $ . ~/spack/share/spack/setup-env.sh

or the equivalent for your shell (e.g., ``csh``, ``fish``).

In order to avoid modifying your Spack installation with the package we
are creating, add a **package repository** just for this tutorial by
entering the following command:

.. literalinclude:: outputs/packaging/repo-add.out
   :language: console

Doing this ensures changes we make here do not adversely affect other
parts of the tutorial. You can find out more about repositories at
`Package Repositories <https://spack.readthedocs.io/en/latest/repositories.html>`_.

-------------------------
Creating the Package File
-------------------------

Suppose you want to install software that depends on mpileaks but found
Spack did not already have a built-in package for it. This means you are
going to have to create one.

Spack's *create* command builds a new package from a template by taking
the location of the package's source code and using it to:

* fetch the code;
* create a package skeleton; and
* open the file up in your editor of choice.

.. note::

   An example of creating a package from software with more available
   versions can be found at `Creating and Editing Packages
   <https://spack.readthedocs.io/en/latest/packaging_guide.html#creating-editing-packages>`_.

The ``mpileaks`` source code is available in a tarball in the
software's repository (https://github.com/LLNL/mpileaks). Spack
will look at the contents of the tarball and generate a package when we
run ``spack create`` with the URL:

.. literalinclude:: outputs/packaging/create.out
   :language: console
   :emphasize-lines: 1

You should now be in your text editor of choice, with the ``package.py``
file open for editing.

Your ``package.py`` file should reside in the ``tutorial-mpileaks``
subdirectory of your tutorial repository's ``packages`` directory, i.e.,
``$SPACK_ROOT/var/spack/repos/tutorial/packages/tutorial-mpileaks/package.py``

Take a moment to look over the file.

As we can see from the skeleton contents, shown below, the Spack
template:

* provides instructions for how to contribute your package to
  the Spack repository;
* indicates the software is built with ``Autotools``;
* provides a docstring template;
* provides an example homepage URL;
* shows how to specify a list of package maintainers;
* specifies the version directive, with checksum, for the software;
* shows a dependency directive example; and
* provides a skeleton ``configure_args`` method.

.. literalinclude:: tutorial/examples/packaging/0.package.py
   :caption: tutorial-mpileaks/package.py (from tutorial/examples/packaging/0.package.py)
   :language: python
   :emphasize-lines: 26,27,29-30,33-35,39-40,43-44

.. note::

   The ``maintainers`` field is a comma-separated list of GitHub user
   names for those people who are willing to be notified when a change
   is made to the package. This information is useful for developers who
   maintain a Spack package for their own software and or rely on software
   maintained by other people.

Since we are providing a ``url``, we can confirm the checksum, or ``sha256``
calculation. Exit your editor to return to the command line and use the
``spack checksum`` command:

.. literalinclude:: outputs/packaging/checksum-mpileaks-1.out
   :language: console
   :emphasize-lines: 1,8

Note the entire ``version`` directive is provided for your convenience.

We will now fill in the provided placeholders as we:

* document some information about this package;
* add dependencies; and
* add the configuration arguments needed to build the package.

For the moment, though, let's see what Spack does with the skeleton
by trying to install the package using the ``spack install`` command:

.. literalinclude:: outputs/packaging/install-mpileaks-1.out
   :language: console
   :emphasize-lines: 1,19

It clearly did not build. The error indicates ``configure`` is unable
to find the installation location of a dependency.

So let's start to customize the package to our software.

----------------------------
Adding Package Documentation
----------------------------

First let's fill in the documentation.

Bring mpileaks' ``package.py`` file back into your ``$EDITOR`` with the
``spack edit`` command:

.. code-block:: console

   $ spack edit tutorial-mpileaks

Let's make the following changes:

* remove the instructions between dashed lines at the top;
* replace the first ``FIXME`` comment with a description of ``mpileaks``
  in the docstring;
* replace the homepage property with the correct link; and
* uncomment the ``maintainers`` property and add your GitHub user name.

.. note::

   We will exclude the ``Copyright`` clause in the remainder of
   the package snippets here to reduce the length of the tutorial
   documentation; however, it **is required** for published
   packages.

Now make the changes and additions to your ``package.py`` file.

The resulting package should contain the following information:

.. literalinclude:: tutorial/examples/packaging/1.package.py
   :caption: mpileaks/package.py (from tutorial/examples/packaging/1.package.py)
   :lines: 6-
   :language: python
   :emphasize-lines: 5-6,8,11

At this point we've only updated key documentation within the package.
It won't help us build the software but the information is now available
for review.

Let's enter the ``spack info`` command for the package:

.. literalinclude:: outputs/packaging/info-mpileaks.out
   :language: console

Take a moment to look over the output. You should see the following
information derived from the package:

* it is an ``Autotools`` package;
* it has the description, homepage, and maintainer(s) we provided;
* it is not externally detectable;
* it has the URL we gave the ``spack create`` command;
* the preferred version was derived from the code;
* the default ``Autotools`` package installation phases are listed;
* the ``gnuconfig`` build dependency is inherited from ``AutotoolsPackage``;
* both the link and run dependencies are ``None`` at this point;
* the ``Autotools`` ``check`` method will be called to check the build
  post-``build`` phase (tries to run ``make test`` and ``make check``) ; and
* the ``Autotools`` ``installcheck`` method will be called to check the build
  post-``install`` phase (tries to run ``make installcheck``).

As we fill in more information about the package, the ``spack info``
command will become more informative.

.. note::

   More information on using ``Autotools`` packages is provided in
   `AutotoolsPackage
   <https://spack.readthedocs.io/en/latest/build_systems/autotoolspackage.html#phases>`_.

   The full list of build systems known to Spack can be found at
   `Build Systems
   <https://spack.readthedocs.io/en/latest/build_systems.html>`_.

   More information on the build-time tests can be found at
   `<https://spack.readthedocs.io/en/latest/packaging_guide.html#build-time-tests>`_.

   Refer to the links at the end of this section for more information.

Now we're ready to start filling in the build recipe.

-------------------
Adding Dependencies
-------------------

First we'll add the dependencies determined by reviewing documentation
in the software's repository (https://github.com/LLNL/mpileaks). The
``mpileaks`` software relies on three third-party libraries:

* ``mpi``,
* ``adept-utils``, and
* ``callpath``.

.. note::

   Luckily, all of these dependencies are built-in packages in Spack;
   otherwise, we would have to create packages for them as well.

Bring mpileaks' ``package.py`` file back up in your ``$EDITOR`` with
the ``spack edit`` command:

.. code-block:: console

   $ spack edit tutorial-mpileaks

and add the dependencies by specifying them using the ``depends_on``
directive as shown below:

.. literalinclude:: tutorial/examples/packaging/2.package.py
   :caption: tutorial-mpileaks/package.py (from tutorial/examples/packaging/2.package.py)
   :lines: 6-
   :language: python
   :emphasize-lines: 15-17

Adding dependencies tells Spack that it must ensure these packages are
installed *before* it can build our package.

.. note::

  The ``mpi`` dependency is different from the other two in that it is
  a *virtual dependency*. That means Spack must satisfy the dependency
  with a package that *provides* the ``mpi`` interface, such as ``openmpi``
  or ``mvapich2``.

  We call such packages **providers**. More information on virtual dependencies
  can be found in the *Packaging Guide* linked at the bottom of this tutorial.

Now, since we don't want spack to grab the built-in ``mpileaks`` from the build
cache, let's specify the repository we want ``mpileaks`` to be located:

.. literalinclude:: outputs/packaging/install-mpileaks-2.out
   :language: console

.. note::

   This command may take a while to run and may produce more output if
   you don't already have an MPI installed or configured in Spack.

We see that Spack has now identified and built all of our dependencies.
It found that the:

* ``openmpi`` package will satisfy our ``mpi`` dependency;
* ``adept-utils`` is a concrete dependency; and
* ``callpath`` is a concrete dependency.

**But** we are still not able to build the package.

------------------------
Debugging Package Builds
------------------------

Our ``tutorial-mpileaks`` package is still not building due to the
``adept-utils`` package's ``configure`` error. Experienced
``Autotools`` developers will likely already see the problem and
its solution.

But let's take this opportunity to use Spack features to investigate
the problem. Our options for proceeding are:

* review the build log; and
* build the package manually.

~~~~~~~~~~~~~~~~~~~~~~~
Reviewing the Build Log
~~~~~~~~~~~~~~~~~~~~~~~

The build log might yield some clues so let's look at the contents of
the ``spack-build-out.txt`` file at the path recommended above by our
failed installation:

.. literalinclude:: outputs/packaging/build-output.out
   :language: console
   :emphasize-lines: 1,33

In this case the error conveniently appears on the last line of the
log *and* the output from `spack install`.

Here we also see a number of checks performed by the ``configure`` command.
Most importantly, the last line is very clear: the installation path of the
``adept-utils`` dependency cannot be found.

.. note::

   Spack automatically adds standard include and library directories
   to the compiler's search path *but* it is not uncommon for this
   information to not get picked up. Some software, like ``mpileaks``,
   requires the paths to be explicitly provided on the command line.

So let's investigate further from the staged build directory.

~~~~~~~~~~~~~~~~~
Building Manually
~~~~~~~~~~~~~~~~~

First let's try to build the package manually to see if we can
figure out how to solve the problem.

Let's move to the build directory using the ``spack cd`` command:

.. code-block:: console

  $ spack cd tutorial-mpileaks

You should now be in the appropriate stage directory since this
command moves us into the working directory of the last attempted
build. If not, you can ``cd`` into the directory above that contained
the ``spack-build-out.txt`` file then into it's ``spack-src``
subdirectory.

Now let's ensure the environment is properly set up using the
``spack build-env`` command:

.. code-block:: console

  $ spack build-env tutorial-mpileaks bash

This command spawned a new shell containing the same environment
that Spack used to build the ``tutorial-mpileaks`` package. (Feel
free to substitute your favorite shell for ``bash``.)

.. note::

   If you are running using an AWS instance, you'll want to
   substitute your home directory for ``/home/spack`` below.

From here we can manually re-run the build using the ``configure``
command:

.. literalinclude:: outputs/packaging/build-env-configure.out
   :language: console
   :emphasize-lines: 1,52

And we get the same results as before. Unfortunately, the output
does not provide any additional information that can help us with
the build.

Given that this is a simple package built with ``configure`` and we know
that installation directories need to be specified, we can use its
help to see what command line options are available for the software.

.. literalinclude:: outputs/packaging/configure-help.out
   :language: console
   :emphasize-lines: 1,80-81

Note that you can specify the paths for the two concrete dependencies
with the following options:

* ``--with-adept-utils=PATH``
* ``--with-callpath=PATH``

So let's leave the spawned shell and return to the Spack repository
directory:

.. code-block:: console

  $ exit
  $ cd $SPACK_ROOT

Now that we know what arguments to provide, we can update the recipe.

------------------------------
Specifying Configure Arguments
------------------------------

We now know which options we need to pass to ``configure``, but how do we
know where to find the installation paths for the package's dependencies
from within the ``package.py`` file?

Fortunately, we can query the package's concrete ``Spec`` instance.
The ``self.spec`` property holds the package's directed acyclic graph
(DAG) of its dependencies. Each dependency's ``Spec``, accessed by name,
has a ``prefix`` property containing its installation path.

So let's add the configuration arguments for specifying the paths to
the two concrete dependencies in the ``configure_args`` method of our
package.

Bring mpileaks' ``package.py`` file back up in your ``$EDITOR`` with
the ``spack edit`` command:

.. code-block:: console

   $ spack edit tutorial-mpileaks

and add the ``--with-adept-utils`` and ``--with-callpath`` arguments
in the ``configure_args`` method as follows:

.. literalinclude:: tutorial/examples/packaging/3.package.py
   :caption: tutorial-mpileaks/package.py (from tutorial/examples/packaging/3.package.py)
   :lines: 6-
   :language: python
   :emphasize-lines: 20-23

Since this is an ``AutotoolsPackage``, the arguments returned from the
method will automatically get passed to ``configure`` during the build.

Now let's try the build again, remembering to use the ``tutorial`` namespace:

.. literalinclude:: outputs/packaging/install-mpileaks-3.out
   :language: console
   :emphasize-lines: 1,84,86

Success!

All we needed to do was add the path arguments for the two concrete
packages for configure to perform a simple, no frills build.

But is that all we can do to help other users build our software?

---------------
Adding Variants
---------------

What if we want to expose the software's optional features in the package?
We can do this by adding build-time options using package *variants*.

Recall from configure's help output for ``tutorial-mpileaks`` that the
software has several optional features and packages that we could support
in Spack. Two stand out for tutorial purposes because they both take integers,
as opposed to simply allowing them to be enabled or disabled.

.. literalinclude:: outputs/packaging/configure-build-options.out
   :language: console
   :emphasize-lines: 18-23

According to the software's documentation (https://github.com/LLNL/mpileaks),
the integer values for the ``--with-stack-start-*`` options represent the
numbers of calls to shave off of the top of the stack traces for each
language, effectively reducing the noise of internal mpileaks library function
calls in generated traces.

For simplicity, we'll use one variant to supply the value for both arguments.

Supporting this optional feature will require two changes to the package:

* add a ``variant`` directive; and
* change the configure options to use the value.

Let's add the variant to expect an ``int`` value with a default of
``0``. Defaulting to ``0`` effectively disables the option. Also change
``configure_args`` to retrieve the value and add the corresponding
configure arguments when a non-zero value is provided by the user.

Bring mpileaks' ``package.py`` file back up in your ``$EDITOR`` with
the ``spack edit`` command:

.. code-block:: console

   $ spack edit tutorial-mpileaks

and add the ``variant`` directive and associated arguments as follows:

.. literalinclude:: tutorial/examples/packaging/4.package.py
   :caption: tutorial-mpileaks/package.py (from tutorial/examples/packaging/4.package.py)
   :lines: 6-
   :language: python
   :emphasize-lines: 15-16,28-33

Notice that the ``variant`` directive is translated into a ``variants`` dictionary
in ``self.spec``. Also note that the value provided by the user is accessed
by the entry's ``value`` property.

Now run the installation again with the ``--verbose`` install option -- to
get more output during the build -- and the new ``stackstart`` package option:

.. literalinclude:: outputs/packaging/install-mpileaks-4.out
   :language: console
   :emphasize-lines: 1

Notice the addition of the two stack start arguments in the configure
command that appears at the end of the highlighted line after mpileaks'
``Executing phase: 'configure'``.

At this point we've covered how to create a package; update its
documentation; add dependencies; and add variants to support
builds with optional features.

What if you need to customize the build to reflect feature changes?

------------------------
Querying the Spec Object
------------------------

As packages evolve and are ported to different systems, the builds
often need to be changed. This is where the package's ``Spec`` comes
in.

So far we've looked at getting the paths for dependencies and values of
variants from the ``Spec`` but there is more. The package's ``self.spec``,
property allows you to query information about the package build, such as:

* how a package's dependencies were built;
* what compiler was being used;
* what version of a package is being installed; and
* what variants were specified (implicitly or explicitly).

Examples of common queries are provided below.

~~~~~~~~~~~~~~~~~~~~~~
Querying Spec Versions
~~~~~~~~~~~~~~~~~~~~~~

You can customize the build based on the version of the package, compiler,
and dependencies. Examples of each are:

* Am I building my package with version ``1.1`` or greater?

.. code-block:: python

   if self.spec.satisfies('@1.1:'):
       # Do things needed for version 1.1 or newer

* Am I building with a ``gcc`` version up to ``5.0``?

.. code-block:: python

   if self.spec.satisfies('%gcc@:5.0'):
       # Add arguments specific to gcc's up to 5.0

* Is my ``dyninst`` dependency at least version ``8.0``?

.. code-block:: python

   if self.spec['dyninst'].satisfies('@8.0:'):
       # Use newest dyninst options

~~~~~~~~~~~~~~~~~~~
Querying Spec Names
~~~~~~~~~~~~~~~~~~~

If the build has to be customized to the concrete version of an abstract
``Spec`` you can use its ``name`` property. For example:

* Is ``openmpi`` the MPI I'm building with?

.. code-block:: python

   if self.spec['mpi'].name == 'openmpi':
       # Do openmpi things

~~~~~~~~~~~~~~~~~
Querying Variants
~~~~~~~~~~~~~~~~~

Adjusting build options based on enabled variants can be done by querying
the ``Spec`` itself, such as:

* Am I building with the ``debug`` variant?

.. code-block:: python

   if '+debug' in self.spec:
       # Add -g option to configure flags


These are just a few examples of ``Spec`` queries. Spack has thousands of
built-in packages that can serve as examples to guide the development
of your package. You can find these packages in
``$SPACK_ROOT/var/spack/repos/builtin/packages``.

----------------------
Multiple Build Systems
----------------------

There are cases where software actively supports two build systems, or changes
build systems as it evolves, or needs different build systems on different platforms.
Spack allows you to write a single, neat recipe for these cases too. It will only
require a slight change in the recipe's structure compared to what we have seen
so far.

Let's take ``uncrustify``, a source code beautifier, as an example. This software
used to build with ``autotools`` until version 0.63, and then switched build systems
to ``cmake`` at version 0.64.

Compared to previous recipes in this tutorial, in this case we need ``Uncrustify`` to
inherit from both ``CMakePackage`` and ``AutotoolsPackage``. We also need to explicitly
specify the ``build_system`` directive, and add conditional dependencies based on
build system:

.. code-block:: python

   class Uncrustify(CMakePackage, AutotoolsPackage):
       """Source Code Beautifier for C, C++, C#, ObjectiveC, Java, and others."""

       homepage = "http://uncrustify.sourceforge.net/"
       git = "https://github.com/uncrustify/uncrustify"

       version("0.64", commit="1d7d97")
       version("0.63", commit="44ce0f")

       build_system(
           conditional("cmake", when="@0.64:"),
           conditional("autotools", when="@:0.63"),
           default="cmake",
       )

       with when("build_system=cmake"):
           depends_on("cmake@3.18:", type="build")

We didn't mention it so far, but each spec has a ``build_system`` variant that specifies
the build system it uses. In most cases that variant has a single allowed value, inherited from the
corresponding base package - so, usually, you don't have to think about it.

When your package supports more than one build system though, you have to explicitly declare which ones are
allowed and under which conditions. In the example above it's ``cmake`` for version 0.64 and higher and
``autotools`` for version 0.63 and lower.

The ``build_system`` variant can also be used to declare other properties which are conditional on the build
system being selected. For instance, above we declare that when using ``cmake``, CMake 3.18+ is required.

The other relevant difference, compared to the previous recipes we have seen so far, is that the code prescribing
the installation procedure will live into two separate classes:

.. code-block:: python

   class CMakeBuilder(spack.build_systems.cmake.CMakeBuilder):
      def cmake_args(self):
          pass

   class AutotoolsBuilder(spack.build_systems.autotools.AutotoolsBuilder):
      def configure_args(self):
          pass

Depending on the ``spec``, and more specifically on the value of the ``build_system`` directive, a ``builder``
object will be instantiated from one of the two classes when an installation is requested from a user.

-----------
Cleaning Up
-----------

Before leaving this tutorial, let's ensure what we have done does not
interfere with your Spack instance or future sections of the tutorial.
Undo the work we've done here by entering the following commands:

.. literalinclude:: outputs/packaging/cleanup.out
   :language: console
   :emphasize-lines: 1,4,6

--------------------
More information
--------------------

This tutorial module only scratches the surface of defining Spack package
recipes. The `Packaging Guide
<https://spack.readthedocs.io/en/latest/packaging_guide.html#>`_ more
thoroughly covers packaging topics.

Additional information on key topics can be found at the links below.

~~~~~~~~~~~~~~~~~~~~~~~
Testing an installation
~~~~~~~~~~~~~~~~~~~~~~~

* `Checking an installation
  <https://spack.readthedocs.io/en/latest/packaging_guide.html#checking-an-installation>`_:
  for more information on adding tests that run at build-time and against an installation

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Customizing package-related environments
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

* `Retrieving Library Information
  <https://spack-tutorial.readthedocs.io/en/latest/tutorial_advanced_packaging.html#retrieving-library-information>`_:
  for supporting unique configuration options needed to locate libraries
* `Modifying a Package's Build Environment
  <https://spack-tutorial.readthedocs.io/en/latest/tutorial_advanced_packaging.html#modifying-a-package-s-build-environment>`_:
  for customizing package and dependency build and run environments

~~~~~~~~~~~~~~~~~~~~~~~~~
Using other build systems
~~~~~~~~~~~~~~~~~~~~~~~~~

* `Build Systems
  <https://spack.readthedocs.io/en/latest/build_systems.html>`_:
  for the full list of built-in build systems
* `Spack Package Build Systems tutorial
  <https://spack-tutorial.readthedocs.io/en/latest/tutorial_buildsystems.html>`_:
  for tutorials on common build systems
* `Multiple Build Systems
  <https://spack.readthedocs.io/en/latest/packaging_guide.html#multiple-build-systems>`_:
  for a reference on writing packages with multiple build systems
* `Package Class Architecture
  <https://spack.readthedocs.io/en/latest/packaging_guide.html#package-class-architecture>`_:
  for more insight on the inner workings of ``Package`` and ``Builder`` classes.
* `The GDAL Package
  <https://github.com/spack/spack/blob/develop/var/spack/repos/builtin/packages/gdal/package.py>`_:
  for an example of a complex package which extends Python and supports two build systems.

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Making a package externally detectable
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

* `Making a package externally discoverable
  <https://spack.readthedocs.io/en/latest/packaging_guide.html#making-a-package-discoverable-with-spack-external-find>`_:
  for making a package discoverable using the ``spack external find`` command
