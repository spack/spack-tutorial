.. Copyright Spack Project Developers. See COPYRIGHT file for details.

   SPDX-License-Identifier: (Apache-2.0 OR MIT)

.. include:: common/setup.rst

.. _environments-tutorial:

=====================
Environments Tutorial
=====================

So far in this tutorial, we've covered the basic commands for managing individual packages:

* `spack install <https://spack.readthedocs.io/en/latest/basic_usage.html#cmd-spack-install>`_ to install packages
* `spack uninstall <https://spack.readthedocs.io/en/latest/basic_usage.html#cmd-spack-uninstall>`_ to remove them
* `spack find <https://spack.readthedocs.io/en/latest/basic_usage.html#cmd-spack-find>`_ to view and query installed packages

.. Customizing Spack's installation with configuration files, like
   `packages.yaml <https://spack.readthedocs.io/en/latest/build_settings.html#build-settings>`_, was also discussed.

Now we'll explore Spack Environments --- a powerful feature that let's us manage collections of packages together in a documented and reproducible way.
Spack environments are similar to *virtual environments* in other package managers (e.g., `Python venv <https://docs.python.org/3/library/venv.html>`_, `Conda Environments <https://docs.conda.io/projects/conda/en/stable/user-guide/getting-started.html>`_, or `nix-env <https://nix.dev/manual/nix/2.24/command-ref/nix-env>`_).

-------------------------------
What Makes a Spack Environment?
-------------------------------

Spack environments are based around two key files that can be easily shared and reused across different systems:

* ``spack.yaml`` -- The main configuration file where we specify which packages to install, compilers to use, and other Spack settings.

* ``spack.lock`` -- A lockfile that captures the complete provenance of your environment, enabling reproduction of software environments.

---------------------
Why Use Environments?
---------------------

Managing complex software setups with multiple packages and varying configuration (like different MPI) can quickly become overwhelming.
Spack environments solve this by letting you:

* Establish standard software requirements for your project(s)
* Set up consistent runtime environments for your users
* Maintain reproducible development environments
* Configure packages for CI/CD pipelines
* Share and reproduce builds across different machines
* Document your software stack for collaboration
* And much more

----------------------
Goals of this Tutorial
----------------------

This tutorial will teach you the fundamentals of creating and using Spack environments.
We'll cover:
1. Command line basics -- Creating and managing environments with Spack commands.
2. Configuration files -- Editing ``spack.yaml`` and understanding ``spack.lock``.
3. Environment types -- Understanding Spack-managed vs. independent environments.
4. Reproducible builds -- Sharing and recreating environments across systems.

-------------------
Environment Basics
-------------------

Let's look at the output of ``spack find`` at this point in the tutorial.

.. literalinclude:: outputs/environments/find-no-env-1.out
   :language: console


This is a complete, but cluttered list of all our installed packages and their dependencies.
It contains packages built with both ``openmpi`` and ``mpich``, as well as multiple variants of other packages, like ``hdf5`` and ``zlib-ng``.
The query mechanism we learned about with ``spack find`` can help, but it would be nice if we could see only the software that is relevant to our current project instead of seeing everything on the machine.

^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
Creating and Activating Environments
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Let's create a new environment called ``myproject`` using the ``spack env create`` command:

.. literalinclude:: outputs/environments/env-create-1.out
   :language: console

To see all of our environments we've created so far we can run ``spack env list``:

.. literalinclude:: outputs/environments/env-list-1.out
   :language: console


.. note::
   Once we activate an environment it will show up highlighted in
   green in the list of environments.

Now let's **activate** our environment by running the ``spack env activate`` command or ``spacktivate`` alias:

.. literalinclude:: outputs/environments/env-activate-1.out
   :language: console

.. note::
   If we use the ``-p`` option for ``spack env activate``, Spack
   will prepend the environment name to our shell prompt. This is a handy
   way to be reminded if and which environment you are in.

Once we activate an environment, ``spack find`` will only show what is in the current environment.
For example, because we just created this environment the output below doesn't show any installed packages.

.. literalinclude:: outputs/environments/find-env-1.out
   :language: console

.. note::
   Although Spack doesn't show all installed software packages when
   in an active environment, Spack will reuse packages across
   environments to save disk space and reduce build times.

Additionally the output now tells us that we're in the ``myproject`` environment, so there is no need to panic when we no longer see our previously installed packages.
It also states that there are **no** *root specs*.
We'll get back to what that means later.

While this detailed output is useful, if we *only* want to check what environment we're are in, we can use ``spack env status``:

.. literalinclude:: outputs/environments/env-status-1.out
   :language: console


To now exit out of this environment, we can use ``spack env deactivate`` or ``despacktivate`` if we're feeling fancy.

After deactivating, we can see everything installed in this Spack instance:

.. literalinclude:: outputs/environments/env-status-2.out
   :language: console

^^^^^^^^^^^^^^^^^^^
Installing packages
^^^^^^^^^^^^^^^^^^^

Now that we understand how creation and activation work, let's go back to our ``myproject`` environment and *install* a couple of packages, specifically, ``tcl`` and ``trilinos``.

Let's try the usual install commands we learned earlier:

.. literalinclude:: outputs/environments/env-fail-install-1.out
   :language: console

Environments are special in that we must *add* specs to the an environment before we can install them. This additional step helps prevent us from accidentally modifying a shared environment when installing new software.

``spack add`` allows us to queue up several specs to be installed together.
Let's try it:

.. literalinclude:: outputs/environments/env-add-1.out
   :language: console

Now, ``tcl`` and ``trilinos`` have been registered as **root specs** in our environment. **Root specs** are packages that we've explicitly requested to be installed in an environment.
They're called **"roots"** because they sit at the top of the dependency graph---when Spack installs these packages, with their respective dependency packages sitting below them.

Now, let's install:

.. literalinclude:: outputs/environments/env-install-1.out
   :language: console

We can see that Spack reused existing installations of ``tcl`` and the dependencies of ``trilinos`` that were already present on the system, rather than rebuilding them from scratch.

Additionally, the environment's view was automatically updated to include the installations. This means all the software in this environment has been added to our PATH, making the installed packages readily accessible from the command line while we have the environment activated.

Let's now confirm the contents of the environment using ``spack find``:

.. literalinclude:: outputs/environments/find-env-2.out
   :language: console

We can see that the roots and all their dependencies have been installed.

^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
Creating an environment incrementally
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

We can also add and install specs to an environment incrementally. For example:

.. code-block:: console

   $ spack install --add tcl
   $ spack install --add trilinos

If we create environments incrementally, Spack ensures that already installed roots are not re-concretized.
So, adding specs to an environment at a later point in time will not cause existing packages to rebuild.

.. note::

   Incrementally creating an environment may give us different package
   versions from an environment created all at once.
   We'll cover this later in the tutorial after we've discussed different
   concretization strategies.

   Further, there are two other advantages of concretizing and installing an
   environment all at once:


   * If you have a number of specs that can be installed together,
     adding them first and installing them together enables them to
     share dependencies and reduces total installation time.

   * You can launch all builds in parallel by taking advantage of Spack's
     `install-level build parallelism <https://spack.readthedocs.io/en/latest/config_yaml.html#build-jobs>`_.

^^^^^^^^^^^^^^
Using Packages
^^^^^^^^^^^^^^

Spack environments provide a convenient way to use your installed packages by automatically making them available in your shell environment.
This is accomplished through a feature called **environment views**.

An environment view is a directory structure mirroring a standard linux root filesystem with directories like ``/bin`` and ``/usr`` that contain symbolic links to all the packages installed in your Spack environment.
When you activate an environment with ``spack env activate``, Spack automatically:

* Prepends the view's ``bin`` directory to your ``PATH`` environment variable
* Adds the view's ``man`` directory to your ``MANPATH`` for manual pages
* Updates ``CMAKE_PREFIX_PATH`` to include the view's root directory

This means that executables, libraries, and other files from your environment's packages become immediately accessible from your command line, just as if they were installed system-wide.

Let's explore how views work using the ``tcl`` package we just installed in our ``myproject`` environment. The Tcl package includes a shell-like application called ``tclsh``.

To see the path to ``tclsh`` let's use the ``which`` command:

.. literalinclude:: outputs/environments/use-tcl-1.out
   :language: console


Notice its path includes the name of our environment *and* a ``view`` subdirectory.

We can now run ``tclsh`` just like you would any other program that is in your path:

.. code-block:: console

    $ tclsh
    % echo "hello world!"
    hello world!
    % exit

^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
Removing Packages from Environments
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

One of Spack's key features is that you can safely remove packages from specific environments without affecting other environments.
This works because Spack environments only create links to shared package installations---they don't contain the actual package files.

Let's demonstrate this capability by creating a second environment.
Imagine we have two projects:

* ``myproject`` - requires ``trilinos``
* ``myproject2`` - previously needed ``trilinos`` but no longer requires it

Let's start by creating the ``myproject2`` environment and installing both ``scr`` and ``trilinos``:

.. literalinclude:: outputs/environments/env-create-2.out
   :language: console


Now we have two environments with different package combinations:

* The ``myproject`` environment contains ``tcl`` and ``trilinos``
* The ``myproject2`` environment contains ``scr`` and ``trilinos``

Now let's attempt to uninstall ``trilinos`` from ``myproject2`` and examine what happens:

.. literalinclude:: outputs/environments/env-uninstall-1.out
   :language: console


Notice that ``trilinos`` won't be uninstalled because it's still referenced in ``myproject``. This safety feature prevents accidental removal of packages that other environments depend on.

Instead, if we want to remove ``trilinos`` from the ``myproject2`` environment (without affecting it in other environments), we need to use ``spack remove``:

.. literalinclude:: outputs/environments/env-remove-1.out
   :language: console

After running ``spack remove`` we'll see that ``trilinos`` is no longer a root but is still present in the installed specs.
Reconcretizing the environment, we'll see the vestigial ``trilinos`` and its dependencies will be pruned and will no longer be listed in the environment at all.

We know ``trilinos`` is still needed for the ``myproject`` environment, so let's switch back to that environment to confirm that it is still installed.

.. literalinclude:: outputs/environments/env-swap-1.out
   :language: console


Phew!
We can see that ``myproject`` still has ``trilinos`` as a root spec.

.. note::

   You can also uninstall a package and remove it from the environment
   in one go with ``spack uninstall --remove trilinos``.

-----------------------
The ``spack.yaml`` file
-----------------------

An environment is more than just a list of root specs --- it includes **configuration settings** that control how Spack behaves when the environment it activated.
So far, ``myproject`` relies on configuration defaults, but these can be overridden to customize our environment's behavior.

In this section, we'll learn how to enforce that all the packages in our environment depending on ``mpi`` build with ``mpich`` by modifying our configuration.

We can customize the selection of the ``mpi`` provider using `concretization preferences <https://spack.readthedocs.io/en/latest/build_settings.html#concretization-preferences>`_ to change the behavior of the concretizer.

.. note::

   Before proceeding, make sure your ``EDITOR`` environment variable
   is set to the path of your preferred text editor.

Let's start by examining our environment's configuration using ``spack config edit``:

.. literalinclude:: outputs/environments/config-get-1.out
   :emphasize-lines: 8-13

The output shows the special ``spack.yaml`` configuration file that Spack uses to store environment configurations.

There are several important parts of this file:

* ``specs:`` The list of package specs to install in the environment.
* ``view:`` Controls whether the environment generates a *view* (the
  directory tree with symlinks to installed packages we discussed earlier).
* ``concretizer:unify:`` Determines how package specs in the environment are
  concretized together to reduce duplicated dependencies when possible.

The ``specs`` list should look familiar --- these are the package specs we've been modifying previously with ``spack add`` and ``spack install``.

The ``concretizer:unify:true`` setting controls how Spack resolves dependencies across packages specs in an environment:

* ``true`` (default): specs are concretized *together*, ensuring
  there is only one version of each package in the environment.
* ``false``: specs are concretized *independently* from each other,
  potentially allowing multiple versions of the package to appear in the
  environment twice.
* ``when_possible``: A middle ground --- Spack attempts to unify dependencies
  as possible but will backoff to allow duplicates when root specs require
  incompatible versions of dependencies.

^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
Editing environment configuration
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Let's edit ``spack.yaml`` to *require* ``mpich`` as our ``mpi`` provider.

You should have the above file open in your editor.
Change it to include the ``packages:mpi:require`` entry below:

.. code-block:: yaml
   :emphasize-lines: 6-8

   # This is a Spack Environment file.
   #
   # It describes a set of packages to be installed, along with
   # configuration settings.
   spack:
     packages:
       mpi:
         require: [mpich]

     # add package specs to the `specs` list
     specs:
     - tcl
     - trilinos


.. note::

   We introduce this here to show you how environment configuration
   can affect concretization. Configuration options are covered in much
   more detail in the :ref:`configuration tutorial <configs-tutorial>`.


We've only scratched the surface here by requiring a specific ``mpi`` provider for packages depending on ``mpi``.
There are many other customizations you can make to an environment.
Refer to the links at the end of this section for more information.

^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
Re-concretizing the environment
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

You may need to re-install packages in the environment after making significant changes to the configuration, such as changing virtual providers.
This can be accomplished by forcing Spack to re-concretize the environment and re-install the specs.

For example, the packages installed in our ``myproject`` environment are now out of sync with our new configuration since we already installed part of the environment with ``openmpi``.
Suppose we want to install everything in ``myproject`` with ``mpich``.

Let's run ``spack concretize --force`` (or ``-f`` in short) to make Spack re-concretize all the environment's specs:

.. literalinclude:: outputs/environments/concretize-f-1.out
   :language: console


All the specs are now concrete **and** ready to be installed with ``mpich`` as the MPI implementation.


^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
Creating an environment incrementally
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

We can also add and install specs to an environment incrementally. For example:

.. code-block:: console

   $ spack install --add python
   $ spack install --add py-numpy@1.20

If we create environments incrementally, Spack ensures that already installed roots are not re-concretized.
So, adding specs to an environment at a later point in time will not cause existing packages to rebuild.

Adding and installing specs incrementally leads to greedy concretization, meaning that the environment may concain different package versions compared to an environment created all at once.

When you first install ``python`` in an environment, Spack will pick a recent version for it.
If you then add ``py-numpy``, it may be in conflict with the ``python`` version already installed, and fail to concretize:

.. literalinclude:: outputs/environments/incremental-1.out
   :language: console

The solution is to re-concretize the environment as a whole, which causes ``python`` to downgrade to a version compatible with ``py-numpy``:

.. literalinclude:: outputs/environments/incremental-2.out
   :language: console

.. note::
   There are advantages to concretizing and installing an environment all at once:

   * If you have a number of specs that can be installed together,
     adding them first and installing them together enables them to
     share dependencies and reduces total installation time.

   * You can launch all builds in parallel by taking advantage of Spack's
     `install-level build parallelism <https://spack.readthedocs.io/en/latest/config_yaml.html#build-jobs>`_.

------------------------
Building in environments
------------------------

Activated environments allow you to invoke any programs installed in them as if they were installed on the system.
In this section, we will take advantage of that feature.

Suppose you want to compile some MPI programs.
We have an MPI implementation installed in our ``myproject2`` environment, so ``mpicc`` is available in our path.
We can confirm this using ``which``:

.. literalinclude:: outputs/environments/show-mpicc-1.out
   :language: console


As mentioned before, activating the environment sets a number of environment variables.
That includes variables like ``PATH``, ``MANPATH``, and ``CMAKE_PREFIX_PATH``, which allows you to easily find package executables and libraries installed in the environment.

Let's look specifically at path-related environment variables using ``env | grep PATH``:

.. literalinclude:: outputs/environments/show-paths-1.out
   :language: console


We can demonstrate use of these environment settings by building a really simple MPI program.

Let's create a program called ``mpi-hello.c`` that contains the following code:

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
            printf("zlib-ng version: %s\n", ZLIBNG_VERSION);
      }

      MPI_Finalize();
    }

This program includes headers from ``mpi`` and ``zlib``.
It also prints out a message from each MPI rank and the version of ``zlib``.

Let's build and run our program:

.. literalinclude:: outputs/environments/use-mpi-1.out
   :language: console


Notice that we only needed to pass the include path to the compiler.
We also see that ``Hello world`` is output for each of the ranks and the version of ``zlib`` used to build the program is printed.

We can confirm the version of ``zlib`` used to build the program is in our environment using ``spack find``:

.. literalinclude:: outputs/environments/myproject-zlib-ng-1.out
   :language: console

Note that the reported version *does* match that of our installation.

------------------
Reproducing builds
------------------

Spack environments provide users with *virtual environments* similar to `Python venv <https://docs.python.org/3/library/venv.html>`_ and `Conda environments <https://docs.conda.io/projects/conda/en/latest/user-guide/tasks/manage-environments.html#>`_).
The goal is to ensure packages in one environment are kept separate from those of another.
These environments can be managed by Spack or independent.
In either case, their environment files can be used to reproduce builds by other users and on other machines.
Since those files are key to reproducing builds, let's start with them.

^^^^^^^^^^^^^^^^^
Environment files
^^^^^^^^^^^^^^^^^

There are two key files tracking the contents of environments: ``spack.yaml`` and ``spack.lock``.
The ``spack.yaml`` file holds the environment configuration that we previously edited through ``spack config edit``.
The ``spack.lock`` file is automatically generated during concretization.

The two files represent two fundamental concepts:

* ``spack.yaml``: *abstract* specs and configuration to install; and
* ``spack.lock``: all fully *concrete* specs.


These files are intended to be used by developers and administrators to manage the environments in a reproducible way.
We will cover their reuse later.

.. note::

   Both environment files can be versioned in repositories, shared, and
   used to install the same set of software by different users and on
   other machines.

^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
Managed versus independent environments
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Environments are either Spack-managed or independent.
Both types of environments are defined by their environment files.
So far, we have only created managed environments.
This section describes their differences.

*Managed environments* are created using ``spack env create <name>``.
They are automatically created in the ``var/spack/environments`` subdirectory and can be referenced by their names.

*Independent environments* can be created in one of two ways.
First, the Spack environment file(s) can be placed in any directory (other than ``var/spack/environments``).
Alternatively, you can use ``spack env create -d <directory>`` to specify the directory (``<directory>``) in which the files should reside.
Independent environments are not named.

^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
Reviewing a managed environment
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

We created the ``myproject`` environment earlier using ``spack env create myproject`` so let's mainly focus on its environment files in this section.

Earlier, when we changed the environment's configuration using ``spack config edit``, we were actually editing its ``spack.yaml`` file.
We can move to the directory containing the file using ``spack cd``:

.. literalinclude:: outputs/environments/filenames-1.out
   :language: console


Notice that ``myproject`` is a subdirectory of ``var/spack/environments`` within the Spack installation making it a *managed* environment.
Consequently, it can be referenced by name.
It will also show up when running ``spack env list``:

.. literalinclude:: outputs/environments/env-list-2.out
   :language: console

which indicates the active environment by highlighting it in green.

We can also see from the listing above that the current environment directory contains both of the environment files: ``spack.yaml`` and ``spack.lock``.
This is because ``spack.lock`` was generated when we concretized the environment.

If we ``cat`` the ``spack.yaml`` file, we'll see the same specs and view options previously shown by ``spack config get``:

.. literalinclude:: outputs/environments/cat-config-1.out
   :language: console


^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
Creating an independent environment
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Environments do not have to be created in or managed by a Spack instance.
Rather, their environment files can be placed in any directory.
This feature can be quite helpful for use cases such as environment-based software releases and CI/CD.

Let's create an *independent* environment from scratch for a simple project:

.. literalinclude:: outputs/environments/independent-create-1.out
   :language: console


Notice that the command shows Spack created the environment, updated the view, and printed the command needed to activate it.
As we can see in the activation command, since the environment is independent, it must be referenced by its directory path.

Let's see what really happened with this command by listing the directory contents and looking at the configuration file:

.. literalinclude:: outputs/environments/independent-create-2.out
   :language: console


Notice that Spack created a ``spack.yaml`` file in the *code* directory.
Also note that the configuration file has an empty spec list (i.e., ``[]``).
That list is intended to contain only the *root specs* of the environment.

We can confirm that it is not a managed environment by running ``spack env list``:

.. literalinclude:: outputs/environments/env-list-3.out
   :language: console

and noting that the path does not appear in the output.

Now let's add some specs to the environment.
Suppose your project depends on ``trilinos`` and ``openmpi``.
Add these packages to the spec list using your favorite text editor.
The dash syntax for a YAML list is used in our example.
Your package should now contain the following entries:

.. code-block:: yaml

   # This is a Spack Environment file.
   #
   # It describes a set of packages to be installed, along with
   # configuration settings.
   spack:
     # add package specs to the `specs` list
     specs:
     - trilinos
     - openmpi
     view: true
     concretizer:
       unify: true

Now activate the environment and install the packages:

.. literalinclude:: outputs/environments/install-independent-1.out
   :language: console


Notice that Spack concretized the specs before installing them and their dependencies.
It also updated the environment's view.
Since we already installed all these packages outside of the environment, their links were simply added to it.

^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
Updating an installed environment
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Spack supports tweaking an environment even after the initial specs are installed.
You are free to add and remove specs just as you would outside of the environment using the command line interface as before.

For example, let's add ``hdf5`` and look at our file:

.. literalinclude:: outputs/environments/add-independent-1.out
   :language: console


Notice that ``spack add`` added the package to our active environment and it appears in the configuration file's spec list.

.. note::

   You'll need to run ``spack install`` to install added packages
   in your environment because ``spack add`` only adds it to the
   configuration.

Now use ``spack remove`` to remove the spec from the configuration:

.. literalinclude:: outputs/environments/remove-independent-1.out
   :language: console

and we see that the spec *was* removed from the spec list of our environment.

.. note::

   You can also edit the ``spack.yaml`` file directly instead of
   using the ``spack add`` and ``spack remove`` commands.

^^^^^^^^^^^^^^^^^^^^^^^^
Reviewing ``spack.lock``
^^^^^^^^^^^^^^^^^^^^^^^^

Now let's turn our attention from the abstract to the concrete.

Our focus so far has been on the abstract environment configuration represented by the ``spack.yaml`` file.
Once that file is concretized, Spack *generates* a corresponding ``spack.lock`` file representing the full concretized state of the environment.

This file is intended to be a machine-readable representation of the information needed to *reproduce* the build of an environment.
As such, it is written in ``json``, which is less readable than ``yaml``.

Let's look at the top 30 lines of our current environment:

.. literalinclude:: outputs/environments/lockfile-1.out
   :language: console


While it is still readable, it consists of over 1900 lines of information representing the actual configurations for each of the environment's packages.

^^^^^^^^^^^^^^^^^^^^^^^^^^
Reproducing an environment
^^^^^^^^^^^^^^^^^^^^^^^^^^

Now that we've described the contents of the environment files we can discuss how they can be used to reproduce environments.
You may want to do this yourself on a different machine, or use an environment built by someone else.
The process is the same in either case.

You can recreate an environment by passing either of the environment files to ``spack env create``.
The file you choose depends on whether you want to approximate the build using the abstract specs or an *exact* build based on the concrete specs.

""""""""""""""""""""
Using ``spack.yaml``
""""""""""""""""""""

An approximate build is created using the ``spack.yaml`` file.
This approach is relevant when we want to build the same specs on a new platform, for example.
It allows you to reproduce the environment by preserving the abstract requirements in the file.
However, the software may actually build differently in part because the concretizer may choose different dependencies.

Let's use ``spack env create`` to create an abstract environment from the file that we'll call ``abstract``:

.. literalinclude:: outputs/environments/create-from-file-1.out
   :language: console


Here we see that Spack created a managed environment with the name we provided.

And, since it is a newly created environment, it does not have any *installed* specs yet as we can see from calling ``spack find`` **after** activating the environment:

.. literalinclude:: outputs/environments/find-env-abstract-1.out
   :language: console

Notice that we have the same root specs as were listed in the ``spack.yaml`` file.

""""""""""""""""""""
Using ``spack.lock``
""""""""""""""""""""

The ``spack.lock`` file is used for an exact reproduction of the original build.
It can replicate the build because it contains the information for all the decisions made during concretization.

Now let's create a concrete environment, called ``concrete``, from the file:

.. literalinclude:: outputs/environments/create-from-file-2.out
   :language: console

Here we see that Spack again created a managed environment with the provided name.

Since we created the environment from our ``spack.lock`` file, not only do we get the same root specs, all of the packages are installed in the environment as we can see from calling ``spack find`` **after** activating the environment:

.. literalinclude:: outputs/environments/find-env-concrete-1.out
   :language: console

.. note::

   Use of ``spack.lock`` to reproduce a build (currently) requires you
   to be on the same type of machine.

-------------------
More information
-------------------

This tutorial only scratches the surface of environments and what they can do.
For more information, take a look at the Spack resources below.

^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
Setting up and building environments
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

* `Environments <https://spack.readthedocs.io/en/latest/environments.html>`_:
  reference docs
* `Configuration tutorial
  <https://spack-tutorial.readthedocs.io/en/latest/tutorial_configuration.html>`_:
  for customizing your environment
* `Spack stacks tutorial
  <https://spack-tutorial.readthedocs.io/en/latest/tutorial_stacks.html>`_:
  for configuring combinatorial environments (e.g., same packages across a
  list of compilers)
* `Install-level parallel builds
  <https://spack.readthedocs.io/en/latest/config_yaml.html#build-jobs>`_:
  for how to launch ``spack install`` to build your environment in parallel

^^^^^^^^^^^^^^^^^^^^^^^
Using environments
^^^^^^^^^^^^^^^^^^^^^^^

* `Developer workflows
  <https://spack-tutorial.readthedocs.io/en/latest/tutorial_developer_workflows.html>`_:
  for developing code in an environment
* `GitLab CI pipelines with Spack environments
  <https://spack.readthedocs.io/en/latest/pipelines.html>`_:
  for using environments to generate CI pipelines
* `Container Images <https://spack.readthedocs.io/en/latest/containers.html>`_:
  for creating containers from environments
* `Spack stacks tutorial
  <https://spack-tutorial.readthedocs.io/en/latest/tutorial_stacks.html>`_:
  for managing large deployments of software

^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
Finding examples of environments
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

* `Spack Stack Catalog <https://spack.github.io/spack-stack-catalog/>`_: for
  discovering environments that you can explore on GitHub
