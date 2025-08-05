.. Copyright Spack Project Developers. See COPYRIGHT file for details.

   SPDX-License-Identifier: (Apache-2.0 OR MIT)

.. include:: common/setup.rst

.. _packaging-tutorial:

=========================
Package Creation Tutorial
=========================

This tutorial walks you through the steps for creating and debugging a simple Spack package.
We will develop and debug a package using an iterative approach to gain more experience with additional Spack commands.
For consistency, we will create a package for ``mpileaks`` (https://github.com/LLNL/mpileaks), an MPI debugging tool.

------------------------
What is a Spack Package?
------------------------

Spack packages are installation scripts, which are essentially recipes for building (and testing) software.

They define properties and behavior of the build, such as:

* where to find and how to `retrieve the software <https://spack.readthedocs.io/en/latest/packaging_guide_creation.html#fetching-from-code-repositories>`_;
* its `dependencies <https://spack.readthedocs.io/en/latest/packaging_guide_creation.html#dependencies>`_;
* options (`variants <https://spack.readthedocs.io/en/latest/packaging_guide_creation.html#variants>`_) for building from source;
* known build constraints (`conflicts <https://spack.readthedocs.io/en/latest/packaging_guide_creation.html#conflicts>`_);
* known requirements (`requires <https://spack.readthedocs.io/en/latest/packaging_guide_creation.html#requires>`_); and
* `build commands <https://spack.readthedocs.io/en/latest/packaging_guide_build.html>`_.

They can also define `checks <https://spack.readthedocs.io/en/latest/packaging_guide_testing.html>`_ of the installed software that can be performed after the installation.

Once we've specified a package's recipe, users can ask Spack to build the software with different features on any of the supported systems.

---------------
Getting Started
---------------

In order to avoid modifying your Spack installation with the package we are creating, let's create and add a **package repository** just for this tutorial using the following commands:

.. literalinclude:: outputs/packaging/repo-add.out
   :language: console

Doing this ensures changes we make here do not adversely affect other parts of the tutorial.
You can find out more about repositories at `Package Repositories <https://spack.readthedocs.io/en/latest/repositories.html>`_ and the command at `spack repo <https://spack.readthedocs.io/en/latest/repositories.html#cmd-spack-repo>`_.


-------------------------
Creating the Package File
-------------------------

.. note::

   Before proceeding, make sure your ``SPACK_EDITOR``, ``VISUAL``, or ``EDITOR`` environment variable is set to the name or path of your preferred text editor.
   Details can be found at `<https://spack.readthedocs.io/en/latest/packaging_guide_creation.html#controlling-the-editor>`_.


Suppose you want to install software that depends on mpileaks but found Spack did not already have a built-in package for it.
This means you are going to have to create one.

Spack's *create* command builds a new package from a template by taking the location of the package's source code and using it to:

* `fetch the code <https://spack.readthedocs.io/en/latest/packaging_guide_creation.html#fetching-from-code-repositories>`_;
* create a package skeleton; and
* open the file in your `editor of choice <https://spack.readthedocs.io/en/latest/packaging_guide_creation.html#controlling-the-editor>`_.

The ``mpileaks`` source code is available in a tarball in the software's repository (https://github.com/LLNL/mpileaks).
Spack will look at the contents of the tarball and generate a package when we run ``spack create`` with the URL:

.. literalinclude:: outputs/packaging/create.out
   :language: console

You should now be in your text editor of choice, with the ``package.py`` file open for editing.

Your ``package.py`` file should reside in the ``tutorial-mpileaks`` subdirectory of your tutorial repository's ``packages`` directory, i.e., ``/home/spack/repos/spack_repo/tutorial/packages/tutorial_mpileaks/package.py``.

Take a moment to look over the file.

As we can see from the skeleton contents, the Spack template:

* provides the required Spack copyright and license;
* provides information on the commands for installing and editing the package;
* imports and inherits from the inferred `build system package <https://spack.readthedocs.io/en/latest/build_systems.html>`_;
* provides a docstring template;
* provides an example homepage URL;
* shows how to specify a list of package `maintainers <https://spack.readthedocs.io/en/latest/packaging_guide_creation.html#maintainers>`_;
* provides a template for the `license <https://spack.readthedocs.io/en/latest/packaging_guide_creation.html#license-information>`_;
* specifies the `version directive <https://spack.readthedocs.io/en/latest/packaging_guide_creation.html#versions-and-urls>`_ with the `checksum <https://spack.readthedocs.io/en/latest/packaging_guide_creation.html#checksum-verification>`_;
* lists the inferred language and other build `dependencies <https://spack.readthedocs.io/en/latest/packaging_guide_creation.html#dependencies>`_;
* provides a skeleton for another dependency;
* provides a preliminary implementation of the `autoreconf method <https://spack.readthedocs.io/en/latest/build_systems/autotoolspackage.html#using-a-custom-autoreconf-phase>`_; and
* provides a skeleton `configure_args method <https://spack.readthedocs.io/en/latest/build_systems/autotoolspackage.html#adding-flags-to-configure>`_.

The areas we need to modify are highlighted in the figure below.

.. literalinclude:: tutorial/examples/packaging/0.package.py
   :caption: tutorial-mpileaks/package.py (from tutorial/examples/packaging/0.package.py)
   :language: python
   :emphasize-lines: 5-20,27,29-30,33-35,37-40,53-54,57,61-64

.. note::

   The `maintainers directive <https://spack.readthedocs.io/en/latest/packaging_guide_creation.html#maintainers>`_ holds a comma-separated list of **GitHub user name**s for those accounts willing to be notified when a change is made to the package.
   They will be given an opportunity to review the changes.
   This information is useful for developers who maintain a Spack package for their own software and/or rely on software maintained by others.

Since we are providing a ``url``, we can `confirm the checksum <https://spack.readthedocs.io/en/latest/packaging_guide_creation.html#checksum-verification>`_, or ``sha256`` calculation.
Exit your editor to return to the command line and use the `spack checksum <https://spack.readthedocs.io/en/latest/packaging_guide_creation.html#spack-checksum>`_ command:

.. literalinclude:: outputs/packaging/checksum-mpileaks-1.out
   :language: console

where the entire ``version`` directive is provided for your convenience.

Before proceeding with changes, let's see what Spack does with the skeleton by trying to install the package using the ``spack install`` command:

.. literalinclude:: outputs/packaging/install-mpileaks-1.out
   :language: console

The build was unsuccessful.
The error indicates ``configure`` is unable to find the installation location of a dependency.

We will now fill in the provided placeholders and customize the package for the software as we:

* document some information about this package;
* add dependencies; and
* add the configuration arguments needed to build the package.

----------------------------
Adding Package Documentation
----------------------------

First, let's fill in the documentation.

Bring ``tutorial-mpileaks``' ``package.py`` file back up in your editor with the ``spack edit`` command:

.. code-block:: console

   $ spack edit tutorial-mpileaks

Let's make the following changes:

* remove the boilerplate between dashed lines at the top;
* replace the first ``FIXME`` comment with a description of ``mpileaks``
  in the docstring;
* replace the ``homepage`` property with the correct link;
* uncomment the ``maintainers`` directive and add your GitHub user name; and
* replace the ``license`` of the project with the correct name and the placeholder with your GitHub user name.

.. tip::

   It helps to have the `mpileaks <https://github.com/LLNL/mpileaks>`_ repository up in your browser since you can copy-and-paste some of the values from it.

.. note::

   We will exclude the ``Copyright`` clause and license identifier in the remainder of the package snippets here to reduce the length of the tutorial documentation; however, the copyright **is required** for packages contributed back to Spack.

Now make the changes and additions to your ``package.py`` file.

The resulting package should contain -- sans the copyright and license -- the following information:

.. literalinclude:: tutorial/examples/packaging/1.package.py
   :caption: tutorial-mpileaks/package.py (from tutorial/examples/packaging/1.package.py)
   :lines: 5-
   :language: python
   :emphasize-lines: 6,8,11,13

At this point we've only updated key documentation within the package.
It won't help us build the software; however, the information is now available for review.

.. _info_mpileaks:

Let's enter the `spack info <https://spack.readthedocs.io/en/latest/package_fundamentals.html#cmd-spack-info>`_ command for the package:

.. literalinclude:: outputs/packaging/info-mpileaks.out
   :language: console

Take a moment to look over the output.
You should see the information derived from the package now includes the description, homepage, maintainer, and license we provided.

Also notice it shows:

* the preferred version derived from the code;
* the default ``Autotools`` package `installation phases <https://spack.readthedocs.io/en/latest/build_systems/autotoolspackage.html#phases>`_;
* the `gmake <https://github.com/spack/spack-packages/blob/c27b98c74c41e6b1000215d4fc5661aa6841694d/repos/spack_repo/builtin/build_systems/autotools.py#L62>`_ and `gnuconfig <https://github.com/spack/spack-packages/blob/c27b98c74c41e6b1000215d4fc5661aa6841694d/repos/spack_repo/builtin/build_systems/autotools.py#L60>`_ build dependencies inherited from ``AutotoolsPackage``; and
* both the link and run dependencies are currently ``None``.

As we fill in more information about the package, the ``spack info`` command will become more informative.

.. note::

   More information on using Autotools packages is provided in `AutotoolsPackage <https://spack.readthedocs.io/en/latest/build_systems/autotoolspackage.html#phases>`_.

   The full list of build systems known to Spack can be found at `Build Systems <https://spack.readthedocs.io/en/latest/build_systems.html>`_.

   Refer to the links at the end of this section for more information.

Now we're ready to start filling in the build recipe.

.. note::

   Refer to the `style guide <https://spack.readthedocs.io/en/latest/packaging_guide_creation.html#style-guidelines-for-packages>`_ for more information.

-------------------
Adding Dependencies
-------------------

First we'll add the dependencies determined by reviewing documentation in the software's repository (https://github.com/LLNL/mpileaks).
The ``mpileaks`` software relies on three third-party libraries:

* ``mpi``,
* ``adept-utils``, and
* ``callpath``.

.. note::

   Fortunately, all of these dependencies are built-in packages in Spack; otherwise, we would have to create packages for them as well.

Bring ``tutorial-mpileaks``' ``package.py`` file back up with the ``spack edit`` command:

.. code-block:: console

   $ spack edit tutorial-mpileaks

and add the dependencies by specifying them using the ``depends_on`` directive as shown below:

.. literalinclude:: tutorial/examples/packaging/2.package.py
   :caption: tutorial-mpileaks/package.py (from tutorial/examples/packaging/2.package.py)
   :lines: 6-
   :language: python
   :emphasize-lines: 25-27

Adding dependencies tells Spack that it must ensure those packages are installed *before* it can build our package.

.. note::

  The ``mpi`` dependency is different from the other two in that it is a `virtual dependency <https://spack.readthedocs.io/en/latest/packaging_guide_creation.html#virtual-dependencies>`_.
  That means Spack must satisfy the dependency with a package that *provides* the ``mpi`` interface, such as ``openmpi`` or ``mvapich2``.
  We call such packages **providers** since they implement the virtual dependency's interface.

Let's check that dependencies are effectively built when we try to install ``tutorial-mpileaks``:

.. literalinclude:: outputs/packaging/install-mpileaks-2.out
   :language: console

.. note::

   This command may take a while to run and may produce more output if
   you don't already have an MPI installed or configured in Spack.

While Spack was unable to install our package, we do see that it identified and built all of our dependencies.
It found that:

* the ``openmpi`` package will satisfy our ``mpi`` dependency;
* ``adept-utils`` is a concrete dependency; and
* ``callpath`` is a concrete dependency.

At this point we need to debug the build problem to determine why Spack cannot install the software.

------------------------
Debugging Package Builds
------------------------

Our ``tutorial-mpileaks`` package is still not building due to the ``adept-utils`` package's ``configure`` error.
Experienced Autotools developers will likely already see the problem and its solution.

Let's take this opportunity to use Spack features to investigate the problem.
Our options for proceeding are:

* review the build log; and
* build the package manually.

~~~~~~~~~~~~~~~~~~~~~~~
Reviewing the Build Log
~~~~~~~~~~~~~~~~~~~~~~~

The build log might yield some clues so let's look at the contents of the ``spack-build-out.txt`` file at the path recommended above by our failed installation:

.. literalinclude:: outputs/packaging/build-output.out
   :language: console

In this case the error conveniently appears on the last line of the log *and* the output from `spack install`.

Here we also see a number of checks performed by the ``configure`` command.
Most importantly, the last line is very clear: ``configure: error: unable to locate adept-utils installation``.
In other words, the installation path of the ``adept-utils`` dependency cannot be found.

.. note::

   Spack automatically adds standard include and library directories to the compiler's search path *but* it is not uncommon for this information to not get picked up.
   Some software, like ``mpileaks``, requires the paths to be **explicitly** provided on the command line.

Let's investigate further from the staged build directory.

~~~~~~~~~~~~~~~~~
Building Manually
~~~~~~~~~~~~~~~~~

First let's try to build the package manually to see if we can figure out how to solve the problem.

Let's move to the build directory using the ``spack cd`` command:

.. code-block:: console

  $ spack cd tutorial-mpileaks

You should now be in the appropriate stage directory since this command moves us into the working directory of the last attempted build.
If not, you can ``cd`` into the directory above that contained the ``spack-build-out.txt`` file then into its ``spack-src`` subdirectory.

Now let's ensure the environment is properly set up using the ``spack build-env`` command:

.. code-block:: console

  $ spack build-env tutorial-mpileaks bash

This command spawned a new shell containing the same environment that Spack used to build the ``tutorial-mpileaks`` package. (Feel free to substitute your favorite shell for ``bash``.)

.. note::

   If you are running using an AWS instance, you'll want to substitute your home directory for ``/home/spack`` below.

From here we can manually re-run the build using the ``configure`` command with the ``--prefix`` option that Spack passed in the failed build.
If you aren't sure, check the appropriate line under ``Executing phase: 'configure'`` in the build log in :ref:`Reviewing the Build Log`.

.. literalinclude:: outputs/packaging/build-env-configure.out
   :language: console

Unfortunately we get the same results as before and the output does not provide any additional information that can help us with the build.

Given that this is a simple package built with ``configure`` and we know that installation directories need to be specified, we can use the command's ``--help`` to see what options are available for the software.

.. _mpileaks_configure_help:

.. literalinclude:: outputs/packaging/configure-help.out
   :language: console
   :emphasize-lines: 80-81

The output shows that you can specify the paths for the two concrete dependencies with the following options:

* ``--with-adept-utils=PATH``
* ``--with-callpath=PATH``

Let's leave the spawned shell and return to the Spack repository directory:

.. code-block:: console

  $ exit
  $ cd $SPACK_ROOT

Now that we know what arguments to provide, we can update the recipe.

------------------------------
Specifying Configure Arguments
------------------------------

We now know which options we need to pass to ``configure``, but how do we know where to find the installation paths for the package's dependencies from within the ``package.py`` file?

Fortunately, we can query the package's concrete ``Spec`` instance.
The ``self.spec`` property holds the package's directed acyclic graph
(DAG) of its dependencies. Each dependency's ``Spec``, accessed by name,
has a ``prefix`` property containing its installation path.

So let's add the `configuration arguments <https://spack.readthedocs.io/en/latest/build_systems/autotoolspackage.html#adding-flags-to-configure>`_ for specifying the paths to the two concrete dependencies in the ``configure_args`` method of our package.

Bring ``tutorial-mpileaks``' ``package.py`` file back up with the ``spack edit`` command:

.. code-block:: console

   $ spack edit tutorial-mpileaks

and add the ``--with-adept-utils`` and ``--with-callpath`` arguments in the ``configure_args`` method as follows:

.. literalinclude:: tutorial/examples/packaging/3.package.py
   :caption: tutorial-mpileaks/package.py (from tutorial/examples/packaging/3.package.py)
   :lines: 6-
   :language: python
   :emphasize-lines: 32-36

Since this is an ``AutotoolsPackage``, the arguments returned from the method will automatically get passed to ``configure`` during the build.

Now let's try the build again:

.. literalinclude:: outputs/packaging/install-mpileaks-3.out
   :language: console

Success!

All we needed to do was add the path arguments for the two concrete packages for configure to perform a simple build.

Is that all we can do to help other users build our software?

---------------
Adding Variants
---------------

Suppose we want to expose the software's optional features in the package?
We can do this by adding build-time options using package `variants <https://spack.readthedocs.io/en/latest/packaging_guide_creation.html#variants>`_).

Recall from :ref:`configure's help output <mpileaks_configure_help>` for ``tutorial-mpileaks`` that the software has several optional features and packages that we could support in Spack.
Two stand out for tutorial purposes because they both take integers, as opposed to allowing them to be enabled or disabled.

.. literalinclude:: outputs/packaging/configure-build-options.out
   :language: console
   :emphasize-lines: 18-23

According to the software's documentation (https://github.com/LLNL/mpileaks), the integer values for the ``--with-stack-start-*`` options represent the numbers of calls to shave off of the top of the stack traces for each language, effectively reducing the noise of internal mpileaks library function calls in generated traces.

For simplicity, we'll use one variant to supply the value for both arguments.

Supporting this optional feature will require two changes to the package:

* add a `variant directive <https://spack.readthedocs.io/en/latest/packaging_guide_creation.html#variants>`_; and
* change the configure options to use the value.

Let's add the variant to expect an ``int`` value with a default of ``0``.
Setting the default to ``0`` effectively disables the option.
Change ``configure_args`` to retrieve the value and add the corresponding configure arguments when a non-zero value is provided by the user.

Bring ``tutorial-mpileaks``' ``package.py`` file back up with the ``spack edit`` command:

.. code-block:: console

   $ spack edit tutorial-mpileaks

and add the ``variant`` directive and associated arguments as follows:

.. literalinclude:: tutorial/examples/packaging/4.package.py
   :caption: tutorial-mpileaks/package.py (from tutorial/examples/packaging/4.package.py)
   :lines: 6-
   :language: python
   :emphasize-lines: 16-21,45-52

Notice that the ``variant`` directive is translated into a ``variants`` dictionary in ``self.spec``.
Also note that the value provided by the user is accessed by the entry's ``value`` property.

Now run the installation again with the ``--verbose`` install option -- to get more output during the build -- and the new ``stackstart`` package option:

.. literalinclude:: outputs/packaging/install-mpileaks-4.out
   :language: console

Notice the addition of the two stack start arguments in the configure command that appears at the end of the highlighted line after ``tutorial-mpileaks``' ``Executing phase: 'configure'``.

.. note::

   ``Autotools`` is one of several packages that implement `helper functions <https://spack.readthedocs.io/en/latest/build_systems/autotoolspackage.html#helper-functions>`_ to simplify setting options tied to variants.

Now that we have a package we can build, it's time to consider adding tests that can be used to gain confidence that the software works.

------------
Adding Tests
------------

The simplest tests we can add are `sanity checks <https://spack.readthedocs.io/en/latest/packaging_guide_testing.html#adding-sanity-checks>`_, which can be used to ensure the directories and files we expect to be installed for all versions of the package actually exist.

If we look at a successful installation, we can see that the following directories are installed:

* bin
* lib
* share

So let's add a simple sanity check to ensure they are present, **but** let's enter a typo to see what happens.

Bring ``tutorial-mpileaks``' ``package.py`` file back up with the ``spack edit`` command and add the following ``sanity_check_is_dir`` list:

.. literalinclude:: tutorial/examples/packaging/5.package.py
   :caption: tutorial-mpileaks/package.py (from tutorial/examples/packaging/5.package.py)
   :lines: 6-
   :language: python
   :emphasize-lines: 14

Since these are `build-time tests <https://spack.readthedocs.io/en/latest/packaging_guide_testing.html#build-time-tests>`_, we'll need to uninstall the package so we can re-run it with tests enabled:

.. literalinclude:: outputs/packaging/install-mpileaks-5.out
   :language: console

Notice the installation fails due to the missing directory with the error: ``Error: InstallError: Install failed for tutorial-mpileaks. No such directory in prefix: shar``.

Now let's fix the error and try again:

.. literalinclude:: tutorial/examples/packaging/6.package.py
   :caption: tutorial-mpileaks/package.py (from tutorial/examples/packaging/6.package.py)
   :lines: 6-
   :language: python
   :emphasize-lines: 14

Installing again we can see we fixed the problem.

.. literalinclude:: outputs/packaging/install-mpileaks-6.out
   :language: console

This only scratches the surface of testing an installation.
We could leverage the examples from this package to add `post-install phase tests <https://spack.readthedocs.io/en/latest/packaging_guide_testing.html#adding-installation-phase-tests>`_ and/or `stand-alone tests <https://spack.readthedocs.io/en/latest/packaging_guide_testing.html#stand-alone-tests>`_.


------------------------
Querying the Spec Object
------------------------

As packages evolve and are ported to different systems, build recipes often need to change as well.
This is where the package's ``Spec`` comes in.

Previously, we've looked at getting the paths for dependencies and values of variants from the ``Spec``; however, there is more to consider.
The package's ``self.spec`` property allows you to query information about the package build, such as:

* how a package's dependencies were built;
* what compiler was used;
* what version of a package is being installed; and
* what variants were specified (implicitly or explicitly).

Examples of common queries are provided below.

~~~~~~~~~~~~~~~~~~~~~~
Querying Spec Versions
~~~~~~~~~~~~~~~~~~~~~~

You can customize the build based on the version of the package, compiler, and dependencies using `version constraints <https://spack.readthedocs.io/en/latest/packaging_guide_creation.html#specifying-version-constraints>`_.
Examples of each customization are:

* Am I building my package with version ``1.1`` or greater?

.. code-block:: python

   if self.spec.satisfies("@1.1:"):
       # Do things needed for version 1.1 or newer

* Am I building with a ``gcc`` version up to ``5.0``?

.. code-block:: python

   if self.spec.satisfies("%gcc@:5.0"):
       # Add arguments specific to gcc's up to 5.0

* Is my ``dyninst`` dependency at least version ``8.0``?

.. code-block:: python

   if self.spec["dyninst"].satisfies("@8.0:"):
       # Use newest dyninst options

~~~~~~~~~~~~~~~~~~~
Querying Spec Names
~~~~~~~~~~~~~~~~~~~

If the build has to be customized to the concrete version of a virtual dependency, you can use the ``name`` property of the ``Spec``.
For example:

* Is ``openmpi`` the MPI implementation I'm building with?

.. code-block:: python

   if self.spec["mpi"].name == "openmpi":
       # Do openmpi things

~~~~~~~~~~~~~~~~~
Querying Variants
~~~~~~~~~~~~~~~~~

Adjusting build options based on enabled variants can be done by querying the ``Spec`` itself, such as:

* Am I building with the ``debug`` variant?

.. code-block:: python

   if "+debug" in self.spec:
       # Add -g option to configure flags


These are just a few examples of ``Spec`` queries.
Spack has thousands of built-in packages that can serve as examples to guide the development of your package.

.. tip::

   You can find these packages in the ``spack/spack-packages`` repository's ``repos/spack_repo/builtin/packages`` directory.

   Or use `spack pkg grep <https://spack.readthedocs.io/en/latest/command_index.html#spack-pkg>`_ to perform a query.
   For example, to find the paths to all builtin ``AutotoolsPackage`` packages, you can enter ``spack pkg grep AutotoolsPackage | sed "s/:.*##g" | sort -u``, which will search the packages in all of your configured repositories.

----------------------
Multiple Build Systems
----------------------

There are cases where software actively supports two build systems; changes build systems as it evolves; or needs different build systems on different platforms.
Spack allows you to write a single, concise recipe for these cases that generally require minor changes to the package structure.

Let's take a simplified look at ``uncrustify``, a source code beautifier, as an example.
This software builds with ``Autotools`` up through version 0.63 but switches to ``CMake`` at version 0.64.

Therefore ``Uncrustify`` needs to inherit from **both** ``CMakePackage`` and ``AutotoolsPackage``.
We also need to explicitly specify the ``build_system`` directive, and add conditional dependencies accordingly:

.. code-block:: python
   :emphasize-lines: 1,17-21,23-26

   class Uncrustify(CMakePackage, AutotoolsPackage):
       """Source Code Beautifier for C, C++, C#, ObjectiveC, Java, and others."""

       homepage = "http://uncrustify.sourceforge.net/"
       git = "https://github.com/uncrustify/uncrustify"
       url = "https://sourceforge.net/projects/uncrustify/files/uncrustify/uncrustify-0.69/uncrustify-0.69.tar.gz"

       license("GPL-2.0-or-later")

       version("0.69", commit="a7a8fb35d653e0b49e1c86f2eb8a2970025d5989")
       version("0.64", commit="1d7d97fb637dcb05ebc5fe57ee1020e2a659210d")
       version("0.63", commit="44ce0f156396b79ddf3ed9242023a14e9665b76f")

       depends_on("c", type="build")
       depends_on("cxx", type="build")

       build_system(
           conditional("cmake", when="@0.64:"),
           conditional("autotools", when="@:0.63"),
           default="cmake",
       )

       with when("build_system=autotools"):
           depends_on("automake", type="build")
           depends_on("autoconf", type="build")
           depends_on("libtools", type="build")

As we saw with `tutorial-mpileaks <info_mpileaks>`, each spec has a ``build_system`` variant that specifies the build system it uses.
In most cases that variant has a single allowed value, inherited from the corresponding base package - so, usually, you don't have to think about it.

When your package supports more than one build system though, you have to explicitly declare which ones are allowed and under what conditions.
In the example above it's ``cmake`` for version 0.64 and higher and ``autotools`` for version 0.63 and lower.

The ``build_system`` variant can also be used to declare other properties which are conditional on the build system being selected.
For instance, above we declare that when using ``autotools``, the build requires ``automake``, ``autoconf``, and ``libtools``.

The other relevant difference, compared to previous recipes we have seen so far, is that the code prescribing the installation procedure will live into two separate classes:

.. code-block:: python

   class CMakeBuilder(spack.build_systems.cmake.CMakeBuilder):
      def cmake_args(self):
          pass

   class AutotoolsBuilder(spack.build_systems.autotools.AutotoolsBuilder):
      def configure_args(self):
          pass

Depending on the ``spec``, and more specifically on the value of the ``build_system`` directive, a ``Builder`` object will be instantiated from one of the two classes when an installation is requested from a user.

-----------
Cleaning Up
-----------

Before leaving this tutorial, let's ensure that our work does not interfere with your Spack instance or future sections of the tutorial.
Undo the work we've done here by entering the following commands:

.. literalinclude:: outputs/packaging/cleanup.out
   :language: console

--------------------
More information
--------------------

This tutorial module only scratches the surface of defining Spack package recipes.
The packaging guide, split over four sections, covers packaging topics more thoroughly:

* `creation <https://spack.readthedocs.io/en/latest/packaging_guide_creation.html>`_;
* `build customization <https://spack.readthedocs.io/en/latest/packaging_guide_build.html>`_;
* `testing <https://spack.readthedocs.io/en/latest/packaging_guide_testing.html>`_; and
* `advanced topics <https://spack.readthedocs.io/en/latest/packaging_guide_advanced.html>`_, such as multiple build systems and external detection.

Additional information on key topics can be found in the embedded keys above and at the links below.

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Customizing package-related environments
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

* `Retrieving Library Information
  <https://spack-tutorial.readthedocs.io/en/latest/tutorial_advanced_packaging.html#retrieving-library-information>`_:
  for supporting unique configuration options needed to locate libraries.
* `Modifying a Package's Build Environment
  <https://spack-tutorial.readthedocs.io/en/latest/tutorial_advanced_packaging.html#modifying-a-package-s-build-environment>`_:
  for customizing package and dependency build and run environments.

~~~~~~~~~~~~~~~~~~~~~~~
Testing an installation
~~~~~~~~~~~~~~~~~~~~~~~

* `Build-time tests
  <https://spack.readthedocs.io/en/latest/packaging_guide_testing.html#build-time-tests>`_:
  for sanity checks and pre-/post- ``build`` and or ``install`` phase tests.
* `Stand-alone tests
  <https://spack.readthedocs.io/en/latest/packaging_guide_testing.html#stand-alone-tests>`_:
  for tests that can run against any installed Spack package.

~~~~~~~~~~~~~~~~~~~~~~~~~
Using other build systems
~~~~~~~~~~~~~~~~~~~~~~~~~

* `Build Systems
  <https://spack.readthedocs.io/en/latest/build_systems.html>`_:
  for the full list of built-in build systems.
* `Spack Package Build Systems tutorial
  <https://spack-tutorial.readthedocs.io/en/latest/tutorial_buildsystems.html>`_:
  for tutorials on common build systems.
* `Multiple Build Systems
  <https://spack.readthedocs.io/en/latest/packaging_guide_advanced.html#multiple-build-systems>`_:
  for a reference on writing packages with multiple build systems.
* `Package Class Architecture
  <https://spack.readthedocs.io/en/latest/developer_guide.html#package-class-architecture>`_:
  for more insight on the inner workings of ``Package`` and ``Builder`` classes.
* `The GDAL Package
  <https://github.com/spack/spack-packages/blob/develop/repos/spack_repo/builtin/packages/gdal/package.py>`_:
  for an example of a complex package that extends Python while supporting two build systems.

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Making a package externally detectable
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

* `Making a package externally discoverable
  <https://spack.readthedocs.io/en/latest/packaging_guide_advanced.html#making-a-package-discoverable-with-spack-external-find>`_:
  for making a package discoverable using the ``spack external find`` command.
