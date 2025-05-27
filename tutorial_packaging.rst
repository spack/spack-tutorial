.. Copyright 2013-2023 Lawrence Livermore National Security, LLC and other
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
we will create the package for ``mpileaks`` (https://github.com/LLNL/mpileaks),
which is an MPI debugging tool.

------------------------
What is a Spack Package?
------------------------

Spack packages are Python classes that act as recipes for building
and installing software.

They define properties and behavior of the build, such as:

* where to find and how to retrieve the software;
* its dependencies;
* options for building from source; and
* build commands.

They can also define checks of the installed software that can
be performed after the installation.

Once we've specified a package's recipe (the `package.py` file), users can
ask Spack to build the software with different versions, compilers, variants (features),
and dependencies on any Spack-supported system.

---------------
Getting Started
---------------

In order to avoid adding our new test package directly into Spack's built-in
package repository (which is good practice during development and for custom packages),
we first create a new, separate **package repository** just for this tutorial.
Enter the following command to create and register this new repository with Spack:

.. literalinclude:: outputs/packaging/repo-add.out
   :language: console

Doing this ensures that the package we create is isolated and does not
interfere with your main Spack instance or other tutorial sections. You can
find out more about repositories at `Package Repositories <https://spack.readthedocs.io/en/latest/repositories.html>`_.

-------------------------
Creating the Package File
-------------------------

.. note::

   Before proceeding, make sure your ``EDITOR`` environment variable
   is set to the name or path of your preferred text editor.


Suppose you want to install software that depends on `mpileaks`, but you found
that Spack does not already have a built-in package for it. This means you
need to create one.

Spack's `spack create` command helps you start a new package file.
It takes the URL of the package's source code (e.g., a tarball) and uses it to:

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

You should now be in your text editor of choice, with a new file named
``package.py`` open for editing.

Based on the output from `spack create`, this ``package.py`` file for
``tutorial-mpileaks`` will be located in your new repository, typically at a path like:
``$SPACK_ROOT/var/spack/repos/tutorial/packages/tutorial-mpileaks/package.py``
(The exact path to the `tutorial` repository might vary if you changed the default location when running `spack repo add`).

Take a moment to look over the file.

As we can see from the skeleton contents, shown below, the Spack
template:

* provides commented instructions on how to contribute your package to Spack's built-in repository (if desired).
* indicates the detected build system (e.g., Autotools, CMake, etc.) or provides a generic `Package` base class.
* includes a template for the package's docstring (its description).
* provides a placeholder for the software's homepage URL.
* shows how to specify a list of package maintainers (GitHub usernames).
* includes a `version` directive, often with a checksum, for the downloaded source code.
* may show an example `depends_on` directive for dependencies.
* provides a skeleton method relevant to the detected build system (e.g., `configure_args` for Autotools, `cmake_args` for CMake).

.. literalinclude:: tutorial/examples/packaging/0.package.py
   :caption: tutorial-mpileaks/package.py (from tutorial/examples/packaging/0.package.py)
   :language: python
   :emphasize-lines: 26,27,29-30,33-35,37-40,53-54,61-62

.. note::

   The ``maintainers`` field is a comma-separated list of GitHub user
   names for those people who are willing to be notified when a change
   is made to the package. This information is useful for developers who
   maintain a Spack package for their own software and/or rely on software
   maintained by other people.

Since `spack create` usually fills in the `sha256` checksum based on the downloaded tarball,
it should be correct. However, if you needed to manually verify or add a checksum for a new version later,
you would download the tarball and then use the `spack checksum <filename_or_url>` command:

.. literalinclude:: outputs/packaging/checksum-mpileaks-1.out
   :language: console

Note the entire ``version`` directive is provided for your convenience.

We will now fill in the provided placeholders as we:

* document some information about this package;
* add dependencies; and
* add the configuration arguments needed to build the package.

For the moment, though, let's see what Spack does with the skeleton
by trying to install the package using the ``spack install`` command:

.. literalinclude:: outputs/packaging/install-mpileaks-1.out
   :language: console

It clearly did not build. The error indicates ``configure`` is unable
to find the installation location of a dependency.

So let's start customizing the generated `package.py` file for our software.

----------------------------
Adding Package Documentation
----------------------------

First, let's fill in the documentation.

Bring the `tutorial-mpileaks` package file back into your ``$EDITOR`` with the
``spack edit`` command:

.. code-block:: console

   $ spack edit tutorial-mpileaks

Let's make the following changes:

* remove the instructions between dashed lines at the top;
* replace the first ``FIXME`` comment with a description of ``mpileaks``
  in the docstring;
* replace the homepage property with the correct link; and
* uncomment the ``maintainers`` directive and add your GitHub username(s).
* add the `license` string for the project (e.g., `license("BSD-3-Clause")`).

.. note::

   We will exclude the ``Copyright`` clause and license identifier in the
   remainder of the package snippets here to reduce the length of the tutorial
   documentation; however, the copyright **is required** for published packages.

Now make the changes and additions to your ``package.py`` file.

The resulting package should contain the following information:

.. literalinclude:: tutorial/examples/packaging/1.package.py
   :caption: mpileaks/package.py (from tutorial/examples/packaging/1.package.py)
   :lines: 6-
   :language: python
   :emphasize-lines: 5,7,10,12

At this point we've only updated key documentation within the package.
It won't help us build the software but the information is now available
for review.

Let's enter the ``spack info`` command for the package:

.. literalinclude:: outputs/packaging/info-mpileaks.out
   :language: console

Take a moment to look over the output. You should see the following
information derived from the package:

* it is an Autotools package;
* it has the description, homepage, and maintainer(s) we provided;
* it has the URL we gave the ``spack create`` command;
* the preferred version was derived from the code;
* the default Autotools package installation phases are listed;
* the ``gnuconfig`` build dependency is inherited from ``AutotoolsPackage``;
* both the link and run dependencies are ``None`` at this point; and
* it uses the 3-clause BSD license.

As we fill in more information about the package, the ``spack info``
command will become more informative.

.. note::

   More information on using Autotools packages is provided in the documentation for
   `AutotoolsPackage <https://spack.readthedocs.io/en/latest/build_systems/autotoolspackage.html#phases>`_.

   The full list of build systems known to Spack can be found at
   `Build Systems <https://spack.readthedocs.io/en/latest/build_systems.html>`_.

   More information on build-time tests can be found in the Packaging Guide section on
   `Build-time Tests <https://spack.readthedocs.io/en/latest/packaging_guide.html#build-time-tests>`_.

   Refer to the links at the end of this tutorial for more information.

Now we're ready to start filling in the build recipe.

-------------------
Adding Dependencies
-------------------

First, we'll add the dependencies determined by reviewing the `mpileaks`
documentation (e.g., its README or INSTALL files, often found in the source repository: https://github.com/LLNL/mpileaks).
The ``mpileaks`` software relies on three main third-party libraries:

* ``mpi``,
* ``adept-utils``, and
* ``callpath``.

.. note::

   Luckily, all of these dependencies are already packaged in Spack;
   otherwise, we would have to create Spack packages for them first.

Bring the `tutorial-mpileaks` package file back up in your ``$EDITOR`` with
the ``spack edit`` command:

.. code-block:: console

   $ spack edit tutorial-mpileaks

and add the dependencies by specifying them using the ``depends_on``
directive as shown below:

.. literalinclude:: tutorial/examples/packaging/2.package.py
   :caption: tutorial-mpileaks/package.py (from tutorial/examples/packaging/2.package.py)
   :lines: 6-
   :language: python
   :emphasize-lines: 25-27

Adding dependencies tells Spack that it must ensure these packages are
installed *before* it can build our package.

.. note::

  The ``mpi`` dependency is different from the other two in that it is
  a *virtual dependency*. This means that ``mpi`` is an interface, not a
  specific package. Spack must satisfy this dependency with an actual package
  that *provides* the ``mpi`` interface, such as ``openmpi``, ``mpich``,
  or ``mvapich2``. We call these concrete implementation packages **providers**.
  More information on virtual dependencies can be found in the Packaging Guide
  (see the link at the end of this tutorial).

Let's check that dependencies are effectively built when we try to install ``tutorial-mpileaks``:

.. literalinclude:: outputs/packaging/install-mpileaks-2.out
   :language: console

.. note::

   This command may take a while to run and may produce more output if
   you don't already have an MPI installed or configured in Spack.

We see that Spack has now identified and built all of our dependencies.
It found that:

* the ``openmpi`` package will satisfy our ``mpi`` dependency;
* ``adept-utils`` is a concrete dependency; and
* ``callpath`` is a concrete dependency.

**But** we are still not able to build the package.

------------------------
Debugging Package Builds
------------------------

Our ``tutorial-mpileaks`` package is still not building. The error from the
previous `spack install` attempt indicated that the `configure` script for
`tutorial-mpileaks` failed, likely because it couldn't find `adept-utils`.
Experienced Autotools developers might guess the cause and solution.

But let's take this opportunity to use Spack features to investigate
the problem. Our options for proceeding are:

* review the build log; and
* build the package manually.

~~~~~~~~~~~~~~~~~~~~~~~
Reviewing the Build Log
~~~~~~~~~~~~~~~~~~~~~~~

The build log might yield some clues. You can view the log file directly (Spack
prints its location on error) or use the command `spack build-log tutorial-mpileaks`.
Let's assume its contents are similar to:

.. literalinclude:: outputs/packaging/build-output.out
   :language: console

In this case the error conveniently appears on the last line of the
log *and* the output from `spack install`.

Here we also see a number of checks performed by the ``configure`` command.
Most importantly, the last line is very clear: the installation path of the
``adept-utils`` dependency cannot be found.

.. note::

   Spack automatically adds standard include and library directories of
   dependencies to the compiler's search paths (e.g., via `CPATH`, `LIBRARY_PATH`,
   and by passing flags to compiler wrappers). However, it's not uncommon for
   Autotools `configure` scripts or other build systems to not automatically
   pick up these paths for all dependencies, or they might require explicit
   options like `--with-<dependency>=<path>`. Some software, like ``mpileaks``
   in this example, requires the paths to certain dependencies to be explicitly
   provided on the `configure` command line.

So let's investigate further from the staged build directory.

~~~~~~~~~~~~~~~~~
Building Manually
~~~~~~~~~~~~~~~~~

First, let's try to build the package manually within the Spack build
environment to see if we can figure out how to solve the problem.

Let's navigate to the build directory using the ``spack cd --stage tutorial-mpileaks``
command (or `spack cd -s tutorial-mpileaks` to go to the source directory first, then navigate to the build path):

.. code-block:: console

  $ spack cd tutorial-mpileaks

You should now be in the appropriate stage (source) directory for `tutorial-mpileaks`.
Spack performs out-of-source builds for Autotools, so the actual build happens
in a separate directory, usually a sibling to `spack-src` within the stage area.
The `spack build-env` command below will drop you into the correct build directory.

Now let's ensure the environment is properly set up using the
``spack build-env`` command:

.. code-block:: console

  $ spack build-env tutorial-mpileaks bash

This command spawns a new shell (``bash`` in this case, but you can use others)
with the same environment variables (paths, compilers, etc.) that Spack
would use to build the ``tutorial-mpileaks`` package. It also changes the
current directory to the package's build directory.

.. note::

   If you are running using an AWS instance, you'll want to
   substitute your home directory for ``/home/spack`` below.

From here we can manually re-run the build using the ``configure``
command:

.. literalinclude:: outputs/packaging/build-env-configure.out
   :language: console

And we get the same results as before. Unfortunately, the output
does not provide any additional information that can help us with
the build.

Given that this is a simple package built with `configure` and we suspect
that installation directories for dependencies need to be specified, we can
use `configure --help` to see what command-line options are available.

.. literalinclude:: outputs/packaging/configure-help.out
   :language: console
   :emphasize-lines: 80-81

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

Bring the `tutorial-mpileaks` package file back up in your ``$EDITOR`` with
the ``spack edit`` command:

.. code-block:: console

   $ spack edit tutorial-mpileaks

and add the ``--with-adept-utils`` and ``--with-callpath`` arguments
in the ``configure_args`` method as follows:

.. literalinclude:: tutorial/examples/packaging/3.package.py
   :caption: tutorial-mpileaks/package.py (from tutorial/examples/packaging/3.package.py)
   :lines: 6-
   :language: python
   :emphasize-lines: 32-36

Since this is an ``AutotoolsPackage``, the arguments returned from the
method will automatically get passed to ``configure`` during the build.

Now let's try the build again:

.. literalinclude:: outputs/packaging/install-mpileaks-3.out
   :language: console

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

According to the software's documentation (e.g., output from `./configure --help`
or its `README`), the integer values for the ``--with-stack-start-*`` options
represent the number of initial stack frames to exclude from traces for each
language. This can help reduce noise from internal mpileaks library function
calls in generated traces.

For simplicity, we'll use one variant to supply the value for both arguments.

Supporting this optional feature in our Spack package will require two changes to the `package.py` file:

* add a ``variant`` directive; and
* change the configure options to use the value.

Let's add the variant to expect an `int` value with a default of `0`.
Defaulting to `0` effectively means the feature is off or uses the software's
own default behavior if the configure flags are omitted. We will also modify
`configure_args` to retrieve the variant's value and add the corresponding
configure arguments only when a non-zero value is provided by the user.

Bring the `tutorial-mpileaks` package file back up in your ``$EDITOR`` with
the ``spack edit`` command:

.. code-block:: console

   $ spack edit tutorial-mpileaks

and add the ``variant`` directive and associated arguments as follows:

.. literalinclude:: tutorial/examples/packaging/4.package.py
   :caption: tutorial-mpileaks/package.py (from tutorial/examples/packaging/4.package.py)
   :lines: 6-
   :language: python
   :emphasize-lines: 16-21,45-52

Notice that the `variant` directive results in an entry in the `self.spec.variants`
dictionary-like object. The value specified by the user (or the default) is
accessed using `self.spec.variants['stackstart'].value`.

Now run the installation again with the ``--verbose`` install option -- to
get more output during the build -- and the new ``stackstart`` package option:

.. literalinclude:: outputs/packaging/install-mpileaks-4.out
   :language: console

Notice the addition of the two stack start arguments in the configure
command that appears at the end of the highlighted line after mpileaks'
``Executing phase: 'configure'``.

------------
Adding Tests
------------

The simplest tests we can add are sanity checks, which can be used to
ensure the directories and files we expect to be installed for all
versions of the package actually exist. If we look at a successful
installation, we can see that the following directories will be installed:

* bin
* lib
* share

So let's add a simple sanity check to ensure they are present, BUT let's
enter a typo to see what happens:

.. literalinclude:: tutorial/examples/packaging/5.package.py
   :caption: tutorial-mpileaks/package.py (from tutorial/examples/packaging/5.package.py)
   :lines: 6-
   :language: python
   :emphasize-lines: 14

We'll need to uninstall the package so we can re-run it with tests enabled:

.. literalinclude:: outputs/packaging/install-mpileaks-5.out
   :language: console

Notice the installation fails due to the missing directory.

Now let's fix the error and try again:

.. literalinclude:: tutorial/examples/packaging/6.package.py
   :caption: tutorial-mpileaks/package.py (from tutorial/examples/packaging/6.package.py)
   :lines: 6-
   :language: python
   :emphasize-lines: 14

Installing again we can see we've fixed the problem.

.. literalinclude:: outputs/packaging/install-mpileaks-6.out
   :language: console

This is just scratching the surface of testing an installation. We could
leverage the examples from this package (if it has any) to add more comprehensive
post-install phase tests (e.g., by overriding `check()`) or build-time tests.
Refer to the links at the bottom of this tutorial for more information on
checking an installation.


------------------------
Querying the Spec Object
------------------------

As packages evolve and are ported to different systems, build recipes
often need to change as well. This is where the package's ``Spec`` comes
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

* Is the current package version `1.1` or greater?

.. code-block:: python

   if self.spec.satisfies("@1.1:"):
       # Do things needed for version 1.1 or newer

* Is the current compiler `gcc` with a version up to `5.0`?

.. code-block:: python

   if self.spec.satisfies("%gcc@:5.0"):
       # Add arguments specific to gcc's up to 5.0

* Is the `dyninst` dependency (if present) at least version `8.0`?

.. code-block:: python

   if self.spec["dyninst"].satisfies("@8.0:"):
       # Use newest dyninst options

~~~~~~~~~~~~~~~~~~~
Querying Spec Names
~~~~~~~~~~~~~~~~~~~

If the build has to be customized to the concrete version of an abstract
``Spec`` you can use its ``name`` property. For example:

* Is `openmpi` the concrete provider for the virtual `mpi` dependency?

.. code-block:: python

   if self.spec["mpi"].name == "openmpi":
       # Do openmpi things

~~~~~~~~~~~~~~~~~
Querying Variants
~~~~~~~~~~~~~~~~~

Adjusting build options based on enabled variants can be done by querying
the ``Spec`` itself, such as:

* Is the `debug` variant enabled for the current package?

.. code-block:: python

   if "+debug" in self.spec:
       # Add -g option to configure flags


These are just a few examples of ``Spec`` queries. Spack has thousands of
built-in packages that can serve as examples to guide the development
of your package. You can find these packages in
``$SPACK_ROOT/var/spack/repos/builtin/packages``.

----------------------
Multiple Build Systems
----------------------

There are cases where software actively supports two build systems, changes
build systems as it evolves, or needs different build systems on different
platforms. Spack allows you to write a single, clean package recipe for these
scenarios. This typically requires inheriting from multiple build system base
classes and using conditional logic based on the spec.

Let's take ``uncrustify``, a source code beautifier, as an example. This software
used to build with Autotools until version 0.63, and then switched build systems
to CMake at version 0.64.

Compared to previous recipes in this tutorial, for a package like `Uncrustify`
that supports multiple build systems, the class would inherit from all applicable
build system base classes (e.g., `CMakePackage`, `AutotoolsPackage`).
We also need to explicitly specify the allowed values for the built-in `build_system`
variant and usually provide a default. Conditional dependencies can then be added
based on the selected `build_system` variant:

.. code-block:: python

   class Uncrustify(CMakePackage, AutotoolsPackage):
       """Source Code Beautifier for C, C++, C#, ObjectiveC, Java, and others."""

       homepage = "http://uncrustify.sourceforge.net/"
       git = "https://github.com/uncrustify/uncrustify"

       version("0.64", commit="1d7d97")
       version("0.63", commit="44ce0f")

       # Declare supported build systems and when they apply
       build_system("cmake", "autotools", default="cmake")

       # Conditional logic based on version for selecting the build system
       # This logic usually goes into the package's __init__ or a helper method
       # if more complex, or can be implicitly handled if versions only support one.
       # For simplicity, Spack's 'build_system' variant itself can be conditional
       # or one might use 'conflicts' for unsupported combinations.
       # A more direct way for this version-based switch is often handled by
       # having different methods or conditional logic within shared methods.
       # The 'build_system' variant itself is how users can *choose*, if multiple are valid for a spec.

       # Example of conditional dependency based on the chosen build system:
       with when("build_system=cmake"):
           depends_on("cmake@3.18:", type="build")
       # No specific build dependency for autotools shown here, but could be added.

Spack has a built-in `build_system` variant (values like `autotools`, `cmake`, etc.).
If a package class inherits from only one build system base class (e.g., `AutotoolsPackage`),
this variant typically has only one allowed value.
When a package supports multiple build systems (by inheriting from multiple such base classes),
you must declare the allowed values for the `build_system` variant in your `package.py`
(e.g., `build_system("cmake", "autotools", default="cmake")`).
You can then use `when="version@X:"` or other context in `conflicts` directives or
conditional logic in methods to guide or restrict the choice of build system based on version
or other properties. For instance, `uncrustify` versions `@0.64:` might only support `cmake`,
while versions `@:0.63` only support `autotools`.

The `build_system` variant choice also dictates which `Builder` internal class Spack uses.
The installation logic specific to each build system (like arguments to `cmake` or `configure`)
will live in methods within these corresponding `Builder` classes (e.g., `CMakeBuilder`, `AutotoolsBuilder`).
Spack automatically selects the correct `Builder` based on the resolved `build_system` variant.
You define these `Builder` classes as inner classes in your `package.py`:

.. code-block:: python

   class CMakeBuilder(spack.build_systems.cmake.CMakeBuilder):
      def cmake_args(self):
          pass

   class AutotoolsBuilder(spack.build_systems.autotools.AutotoolsBuilder):
      def configure_args(self):
          pass

Depending on the resolved spec (specifically the value of its `build_system` variant),
an instance of the corresponding `Builder` inner class will be used to drive the build process.

-----------
Cleaning Up
-----------

Before leaving this tutorial, let's ensure what we have done does not
interfere with your Spack instance or future sections of the tutorial.
Undo the work we've done here by entering the following commands:

.. literalinclude:: outputs/packaging/cleanup.out
   :language: console

--------------------
More information
--------------------

This tutorial module only scratches the surface of defining Spack package
recipes. The `Packaging Guide
<https://spack.readthedocs.io/en/latest/packaging_guide.html#>`_ more
thoroughly covers packaging topics.

Additional information on key topics can be found at the links below:

**Testing an installation**

* `Checking an installation <https://spack.readthedocs.io/en/latest/packaging_guide.html#checking-an-installation>`_:
  For more information on adding tests that run at build-time and against an installation.

**Customizing package-related environments**

* `Retrieving Library Information <https://spack-tutorial.readthedocs.io/en/latest/tutorial_advanced_packaging.html#retrieving-library-information>`_:
  For supporting unique configuration options needed to locate libraries.
* `Modifying a Package's Build Environment <https://spack-tutorial.readthedocs.io/en/latest/tutorial_advanced_packaging.html#modifying-a-package-s-build-environment>`_:
  For customizing package and dependency build and run environments.

**Using other build systems**

* `Build Systems <https://spack.readthedocs.io/en/latest/build_systems.html>`_:
  For the full list of built-in build systems.
* `Spack Package Build Systems tutorial <https://spack-tutorial.readthedocs.io/en/latest/tutorial_buildsystems.html>`_:
  For tutorials on common build systems.
* `Multiple Build Systems <https://spack.readthedocs.io/en/latest/packaging_guide.html#multiple-build-systems>`_:
  For a reference on writing packages with multiple build systems.
* `Package Class Architecture <https://spack.readthedocs.io/en/latest/packaging_guide.html#package-class-architecture>`_:
  For more insight on the inner workings of ``Package`` and ``Builder`` classes.
* `The GDAL Package <https://github.com/spack/spack/blob/develop/var/spack/repos/builtin/packages/gdal/package.py>`_:
  For an example of a complex package which extends Python and supports two build systems.

**Making a package externally detectable**

* `Making a package externally discoverable <https://spack.readthedocs.io/en/latest/packaging_guide.html#making-a-package-discoverable-with-spack-external-find>`_:
  For making a package discoverable using the ``spack external find`` command.
