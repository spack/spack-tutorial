.. Copyright 2013-2023 Lawrence Livermore National Security, LLC and other
   Spack Project Developers. See the top-level COPYRIGHT file for details.

   SPDX-License-Identifier: (Apache-2.0 OR MIT)

.. include:: common/setup.rst

.. _environments-tutorial:

=====================
Environments Tutorial
=====================

We've covered how to install, remove, and list packages in Spack using the following commands:

* `spack install <https://spack.readthedocs.io/en/latest/basic_usage.html#cmd-spack-install>`_ to install packages;
* `spack uninstall <https://spack.readthedocs.io/en/latest/basic_usage.html#cmd-spack-uninstall>`_ to remove packages; and
* `spack find <https://spack.readthedocs.io/en/latest/basic_usage.html#cmd-spack-find>`_ to list and query installed packages.

.. Customizing Spack's installation with configuration files such as
   `packages.yaml <https://spack.readthedocs.io/en/latest/build_settings.html#build-settings>`_ was also discussed.

This section of the tutorial introduces **Spack Environments**, which let you manage independent groups of packages in a reproducible way.
In some ways, Spack environments are similar to *virtual environments* in other systems (e.g., `Python venv <https://docs.python.org/3/library/venv.html>`_), but they are built around file formats (``spack.yaml`` and ``spack.lock``) that can be easily shared and reused across systems.

Managing software that involves many packages and varying configuration requirements (e.g., different ``mpi`` implementations) for multiple projects can quickly become overwhelming.
Spack environments help by enabling you to:

* define and standardize software requirements for your projects;
* configure user runtime environments;
* support consistent development setups;
* define packages for CI/CD workflows;
* reproduce builds—approximately or exactly—on other systems; and
* much more.

This tutorial introduces the basics of creating and using environments, explains how to expand, configure, and build software within them, and distinguishes between Spack-managed and standalone environments.
We'll begin with the command-line interface, then cover editing key environment files directly, and conclude with guidance on reproducible builds.

-------------------
Environment Basics
-------------------

Let's take a look at the output of ``spack find`` at this point in the tutorial:

.. literalinclude:: outputs/environments/find-no-env-1.out
   :language: console

This is a complete—but cluttered—list of installed packages and their dependencies.
It includes packages built with both ``openmpi`` and ``mpich``, along with multiple variants of other packages such as ``hdf5`` and ``zlib-ng``.

While the ``spack find`` query mechanisms we've covered can help navigate this, it would be even more useful to start from a clean slate—without losing what we've already installed.

^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
Creating and activating environments
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

The ``spack env`` command is used to manage environments.
Let's create a new environment called ``myproject``:

.. literalinclude:: outputs/environments/env-create-1.out
   :language: console

An environment is like a virtualized Spack instance that aggregates package installations for a specific project or purpose.
It has an associated *view*, which is a single directory where all packages from the environment are linked.

You can list the environments you've created so far with the ``spack env list`` command:

.. literalinclude:: outputs/environments/env-list-1.out
   :language: console

Now, let's **activate** our environment.
Use the ``spack env activate`` command:

.. literalinclude:: outputs/environments/env-activate-1.out
   :language: console

.. note::

   If you use the ``-p`` option with ``spack env activate``, Spack will prepend the environment name to your shell prompt.  
   This is a helpful reminder of which environment is currently active.

You can also use the shorter alias ``spacktivate`` for ``spack env activate``.

.. note::

   Alias behavior may vary depending on your shell. In Bash, alias use requires the ``expand_aliases`` option to be enabled.  
   This option is set by default in interactive shells, but not in non-interactive ones (e.g., when running a Bash script).  
   To enable it in a script, run: ``shopt -s expand_aliases``.

Once you activate an environment, ``spack find`` shows only the packages in that environment.
Since we just created this one, it does not contain any packages yet:

.. literalinclude:: outputs/environments/find-env-1.out
   :language: console

The output from ``spack find`` is now *slightly* different: It tells you that you're in the ``myproject`` environment—so don't panic if none of your previously installed packages are listed.
It also notes that there are **no** *root specs* (we'll explain that term shortly).

If you only want to check which environment is currently active, use:

.. literalinclude:: outputs/environments/env-status-1.out
   :language: console

To leave the environment, use ``spack env deactivate`` or its alias ``despacktivate``.

After deactivating, ``spack find`` will again show all packages installed in your Spack instance:

.. literalinclude:: outputs/environments/env-status-2.out
   :language: console

Notice that we are no longer in an environment—and all your previously installed packages are still available.


^^^^^^^^^^^^^^^^^^^
Installing packages
^^^^^^^^^^^^^^^^^^^

Now that we understand how environment creation and activation work, let's return to the ``myproject`` environment and *install* a couple of packages: ``tcl`` and ``trilinos``.

First, try the usual install command:

.. literalinclude:: outputs/environments/env-fail-install-1.out
   :language: console

Environments are a bit different—before installing packages, you must first *add* them.
The ``spack add`` command queues up specs to be installed in the environment.
Let's try it:

.. literalinclude:: outputs/environments/env-add-1.out
   :language: console

Now, ``tcl`` and ``trilinos`` have been registered as **root specs** in this environment.
Root specs are the packages you explicitly request for installation—they serve as the **roots** of the environment's dependency graph.

Let's install them:

.. literalinclude:: outputs/environments/env-install-1.out
   :language: console

We see that ``tcl`` and the dependencies of ``trilinos`` were already installed, while ``trilinos`` itself was newly built.
The environment's view was also updated to reflect the new installations.

Now, confirm the environment contents using ``spack find``:

.. literalinclude:: outputs/environments/find-env-2.out
   :language: console

As shown, the root specs and all their dependencies are now installed within the ``myproject`` environment.


^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
Creating an environment incrementally
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

As a shorthand, you can use the ``install --add`` flag to add and install specs in a single step:

.. code-block:: console

   $ spack install --add tcl trilinos

This command adds the specs to the environment and installs them immediately.

You can also add and install specs incrementally, one at a time:

.. code-block:: console

   $ spack install --add tcl
   $ spack install --add trilinos

When building environments incrementally, Spack ensures that already installed root specs are not re-concretized.
This means that adding new specs later will not cause previously installed packages to be rebuilt.

However, incrementally adding and installing specs may result in different package versions than installing them all at once.
We'll revisit this topic when we discuss different concretization strategies.

Additionally, there are two key benefits to concretizing and installing an environment all at once:

* If several specs can share dependencies, installing them together can reduce total installation time.
* You can take advantage of Spack's `install-level build parallelism <https://spack.readthedocs.io/en/latest/packaging_guide.html#install-level-build-parallelism>`_ to launch builds in parallel.


^^^^^^^^^^^^^^
Using packages
^^^^^^^^^^^^^^

Environments provide a convenient way to use installed packages.
Activating an environment with ``spack env activate`` automatically places everything in the environment on your ``PATH``.

Without environments, you would need to manually use `spack load <https://spack.readthedocs.io/en/latest/basic_usage.html#cmd-spack-load>`_ or `module load <https://spack.readthedocs.io/en/latest/module_file_support.html>`_ for each package to set up the appropriate environment for the package and its dependencies.

When you install packages into an environment, they are—by default—linked into a single directory prefix known as a *view*.
Activating the environment with ``spack env activate`` adds relevant subdirectories from this view to ``PATH``, ``MANPATH``, ``CMAKE_PREFIX_PATH``, and other environment variables, making the environment easier to use.

Let's try it out.

We just installed ``tcl`` in the ``myproject`` environment.
Tcl includes a shell-like executable called ``tclsh``.
You can check its location with ``which``:

.. literalinclude:: outputs/environments/use-tcl-1.out
   :language: console

Notice that the path includes the name of our environment and a ``view`` subdirectory.

You can now run ``tclsh`` like any other command available in your ``PATH``:

.. code-block:: console

   $ tclsh
   % puts "hello world!"
   hello world!
   % exit

^^^^^^^^^^^^^^^^^^^^^
Uninstalling packages
^^^^^^^^^^^^^^^^^^^^^

Spack environments let you uninstall or remove packages *within* one environment without affecting other environments or globally installed packages.
This is because environments primarily manage which packages are part of their configuration and view.

Let's demonstrate this by creating another environment.
Suppose ``myproject`` requires ``trilinos``, but we have another project that also installed it and no longer needs it.

Start by creating a ``myproject2`` environment and adding the installed packages ``scr`` and ``trilinos``:

.. literalinclude:: outputs/environments/env-create-2.out
   :language: console

Now we have two environments:

- ``myproject`` contains ``tcl`` and ``trilinos``
- ``myproject2`` contains ``scr`` and ``trilinos``

Let's try uninstalling ``trilinos`` from ``myproject2`` and review the environment contents:

.. literalinclude:: outputs/environments/env-uninstall-1.out
   :language: console

We see that ``trilinos`` was not uninstalled because it is still referenced by another environment.
To remove it from the list of root specs in ``myproject2``, use ``spack remove``:

.. literalinclude:: outputs/environments/env-remove-1.out
   :language: console

After removing it, you'll see that ``trilinos`` is no longer listed as a root spec—but it still appears in the environment until we re-concretize.
Once we do, the spec is fully removed.

To confirm ``trilinos`` is still available in the ``myproject`` environment, switch back:

.. literalinclude:: outputs/environments/env-swap-1.out
   :language: console

Phew! ``trilinos`` is still present as a root spec in ``myproject``.
Spack uses reference counting to ensure packages aren't uninstalled while they're still required elsewhere.

.. note::

   Spack only uninstalls a package when it is no longer needed by any environment or their dependencies.

You can also uninstall a package and remove it from the environment in one step with:

.. code-block:: console

   $ spack uninstall --remove trilinos

-----------------------
The ``spack.yaml`` file
-----------------------

An environment is more than just a list of root specs.
It also includes *configuration* settings that affect Spack's behavior when the environment is active.

So far, ``myproject`` has relied on configuration defaults, but these can be overridden.
For example, we may want to ensure that all packages depending on ``mpi`` use ``mpich`` instead of another provider.

We can customize provider selection using `concretization preferences <https://spack.readthedocs.io/en/latest/build_settings.html#concretization-preferences>`_.

Let's start by examining the current environment configuration with:

.. literalinclude:: outputs/environments/config-get-1.out
   :emphasize-lines: 8-13

This output shows the ``spack.yaml`` configuration file used by Spack to store environment state.

Key parts of this file include:

* ``specs:`` — the list of root specs to install  
* ``view:`` — controls whether the environment has a *view*; set to ``false`` to disable view generation  
* ``concretizer:unify:`` — controls how specs in the environment are concretized

The ``specs`` list should look familiar—these are the packages we've been managing with ``spack add``.

The ``concretizer:unify`` setting controls how the concretizer resolves versions:

- ``true`` (default): Spack tries to unify dependencies so that only one version of each package is used
- ``false``: specs are concretized independently, allowing multiple versions
- ``when_possible``: Spack unifies packages where it can but allows divergence if necessary

This setting helps determine whether all specs share the same dependency versions or not.

^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
Editing environment configuration
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. note::

   Before proceeding, ensure that your ``EDITOR`` environment variable  
   is set to the path of your preferred text editor.

Let's edit ``spack.yaml`` to *require* ``mpich`` as the ``mpi`` provider using the ``spack config edit`` command.

This should open the file in your configured editor.
Modify it to include the ``packages:mpi:require`` entry as shown below:

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
     specs: [tcl, trilinos]

.. note::

   We introduce this configuration to demonstrate how environment settings  
   can affect concretization. Configuration is covered in more detail  
   in the :ref:`configuration tutorial <configs-tutorial>`.

Here, we've only scratched the surface by requiring a specific ``mpi`` provider for packages that depend on ``mpi``.
Spack environments support many additional customizations—refer to the links at the end of this section for further exploration.

^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
Re-concretizing the environment
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

You may need to re-install packages in an environment after making significant configuration changes—such as switching virtual providers.
This is done by forcing Spack to *re-concretize* the environment and re-install the affected specs.

For example, the packages currently installed in our ``myproject`` environment are now out of sync with the configuration, because we previously installed part of the environment with ``openmpi``.
Suppose we now want everything in ``myproject`` to use ``mpich`` instead.

We can run:

.. code-block:: console

   $ spack concretize --force

(or use the shorthand ``-f``) to force Spack to re-concretize all specs in the environment:

.. literalinclude:: outputs/environments/concretize-f-1.out
   :language: console

All specs are now concrete and ready to be installed with ``mpich`` as the selected MPI provider.

Re-concretization is also necessary when building environments *incrementally* with unification enabled.
By default, Spack avoids modifying already concretized specs when new ones are added.

Incrementally adding and installing specs leads to *greedy concretization*.
For example, if you install ``python`` first, Spack may choose the most recent version.
Later, if you add ``py-numpy``, it might conflict with the previously selected ``python`` version and fail to concretize:

.. literalinclude:: outputs/environments/incremental-1.out
   :language: console

To fix this, re-concretize the entire environment.
Spack will then select compatible versions for all specs—for example, downgrading ``python`` if needed:

.. literalinclude:: outputs/environments/incremental-2.out
   :language: console

------------------------
Building in environments
------------------------

Activated environments allow you to use any installed programs as if they were installed system-wide.
In this section, we'll take advantage of that feature.

Suppose you want to compile an MPI program.
Since our ``myproject2`` environment includes an MPI implementation, ``mpicc`` is available on the ``PATH``.
We can confirm this using ``which``:

.. literalinclude:: outputs/environments/show-mpicc-1.out
   :language: console

As mentioned earlier, activating an environment sets several key environment variables.
These include ``PATH``, ``MANPATH``, and ``CMAKE_PREFIX_PATH``, which allow tools and compilers to easily locate the executables, headers, and libraries installed in the environment.

Let's inspect the relevant environment variables using:

.. literalinclude:: outputs/environments/show-paths-1.out
   :language: console

We'll now demonstrate how this environment setup enables building a simple MPI program.

Create a source file named ``mpi-hello.c`` with the following code:

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

This program includes headers from both ``mpi`` and ``zlib``, prints a message from each MPI rank, and reports the version of ``zlib`` used.

Let's build and run the program:

.. literalinclude:: outputs/environments/use-mpi-1.out
   :language: console

Notice that we only needed to pass the include path to the compiler—no additional setup was required.
The output confirms that:

- Each MPI rank prints a “Hello world” message.
- Rank 0 prints the versions of ``zlib`` and ``zlib-ng``.

We can confirm which version of ``zlib`` was used by checking our environment with ``spack find``:

.. literalinclude:: outputs/environments/myproject-zlib-ng-1.out
   :language: console

As expected, the reported version matches the one installed in the environment.

------------------
Reproducing builds
------------------

Spack environments provide users with *virtual environments*—similar to `Python venv <https://docs.python.org/3/library/venv.html>`_ and `Conda environments <https://docs.conda.io/projects/conda/en/latest/user-guide/tasks/manage-environments.html>`_.

These environments help ensure that packages in one project are isolated from those in another.
They can be either Spack-managed or standalone, but in both cases, their configuration files allow builds to be reproduced by other users or on different machines.

Since these files are key to reproducibility, let's begin by reviewing them.

^^^^^^^^^^^^^^^^^
Environment files
^^^^^^^^^^^^^^^^^

There are two key files that track the contents of a Spack environment: ``spack.yaml`` and ``spack.lock``.

- ``spack.yaml`` stores the environment configuration, including package specs and any overrides (as we previously edited using ``spack config edit``).
- ``spack.lock`` is automatically generated during concretization and captures the fully resolved dependency graph.

These two files represent distinct but complementary concepts:

* ``spack.yaml``: defines *abstract* specs and configuration to install  
* ``spack.lock``: records all *concrete* specs (versions, variants, dependencies)

Together, they allow developers and administrators to manage and reproduce software environments consistently.

.. note::

   Both environment files can be version-controlled, shared, and reused  
   to install the same set of packages across different machines and by different users.


^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
Managed versus independent environments
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Spack environments can be either *managed* or *independent*.
Both types are defined by their environment files (``spack.yaml`` and optionally ``spack.lock``), but they differ in how they are created and referenced.

So far, we have only worked with **managed environments**.
This section explains the difference between the two types.

**Managed environments** are created using:

.. code-block:: console

   $ spack env create <name>

These environments are automatically placed under the ``var/spack/environments`` directory in your Spack installation.
They are referenced by their given names.

**Independent environments** are created outside of Spack's internal directory structure.
You can create one in two ways:

1. By placing a ``spack.yaml`` (and optionally ``spack.lock``) file in any directory *other than* ``var/spack/environments``.  
2. By explicitly specifying the directory using:

   .. code-block:: console

      $ spack env create -d <directory>

Independent environments are *not* referenced by name; instead, they are activated or accessed by their path.

^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
Reviewing a managed environment
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

We created the ``myproject`` environment earlier using:

.. code-block:: console

   $ spack env create myproject

So let's focus on reviewing its environment files.

When we modified the environment's configuration with ``spack config edit``, we were actually editing its ``spack.yaml`` file.
To navigate to the directory containing that file, use:

.. literalinclude:: outputs/environments/filenames-1.out
   :language: console

As shown, ``myproject`` is a subdirectory under ``var/spack/environments`` in your Spack installation—making it a *managed* environment.
Because of this, it can be referenced by name and will appear in the list produced by:

.. literalinclude:: outputs/environments/env-list-2.out
   :language: console

The active environment will be highlighted in green in this listing.

We can also see from the listing above that the environment directory contains both ``spack.yaml`` and ``spack.lock``.
The ``spack.lock`` file was generated automatically when we concretized the environment.

If we examine the contents of ``spack.yaml`` using ``cat``, we'll see the same specs and view options previously shown by ``spack config get``:

.. literalinclude:: outputs/environments/cat-config-1.out
   :language: console


^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
Creating an independent environment
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Environments do not need to be created within or managed by a Spack instance.
Instead, their environment files (``spack.yaml`` and optionally ``spack.lock``) can be placed in any directory.
This flexibility is useful for workflows like software releases and CI/CD pipelines.

Let's create an *independent* environment from scratch for a simple project:

.. literalinclude:: outputs/environments/independent-create-1.out
   :language: console

The output confirms that Spack created the environment, updated the view, and printed the command required to activate it.
Because the environment is independent, it must be referenced by its directory path when activating it.

Let's inspect the directory contents and view the configuration file:

.. literalinclude:: outputs/environments/independent-create-2.out
   :language: console

As shown, Spack created a ``spack.yaml`` file in the ``code`` directory.
This file contains an empty spec list (``[]``), which is intended to hold only the *root specs* of the environment.

To confirm this is not a managed environment, run:

.. literalinclude:: outputs/environments/env-list-3.out
   :language: console

You'll see that the environment path does not appear in the output—indicating it is not registered under Spack's ``var/spack/environments``.

Next, let's add some specs to the environment.
Suppose your project depends on ``trilinos`` and ``openmpi``.
Edit the ``spack.yaml`` file using your preferred text editor, and add the following under ``specs:``:

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

As shown, Spack concretizes the specs and installs them along with their dependencies.
It also updates the environment's view.
In this case, since the packages were already installed elsewhere, Spack reused them and simply linked them into the environment.


^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
Updating an installed environment
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Spack allows you to modify an environment even after it has been installed.
You can add or remove specs just as you would outside an environment—using the same command-line interface.

For example, let's add ``hdf5`` and inspect the result:

.. literalinclude:: outputs/environments/add-independent-1.out
   :language: console

Notice that ``spack add`` updated the active environment and ``hdf5`` now appears in the ``specs`` list of the configuration file.

.. note::

   ``spack add`` only updates the configuration—it does not install the package.  
   You must run ``spack install`` separately to install the newly added spec.

Now, let's remove the spec from the configuration using ``spack remove``:

.. literalinclude:: outputs/environments/remove-independent-1.out
   :language: console

As shown, the spec *was* removed from the ``specs`` list of the environment.

.. note::

   You can also directly edit the ``spack.yaml`` file to add or remove specs,  
   instead of using ``spack add`` and ``spack remove``.


^^^^^^^^^^^^^^^^^^^^^^^^
Reviewing ``spack.lock``
^^^^^^^^^^^^^^^^^^^^^^^^

Now let's shift focus from the *abstract* configuration to the *concrete* environment state.

Up to this point, we've focused on the abstract environment configuration defined in the ``spack.yaml`` file.
Once that file is concretized, Spack automatically generates a corresponding ``spack.lock`` file.
This lockfile represents the fully concretized state of the environment.

The ``spack.lock`` file is intended to serve as a machine-readable snapshot of everything needed to *reproduce* the environment's build.
Unlike the human-friendly ``yaml`` format used for ``spack.yaml``, the lockfile is written in ``json``, which is more suitable for automation—but less readable.

Let's view the top 30 lines of the current environment's lockfile:

.. literalinclude:: outputs/environments/lockfile-1.out
   :language: console

While still somewhat readable, the lockfile spans more than 1900 lines, detailing the exact configurations of all packages in the environment.

^^^^^^^^^^^^^^^^^^^^^^^^^^
Reproducing an environment
^^^^^^^^^^^^^^^^^^^^^^^^^^

Now that we've explored the contents of environment files, let's discuss how they can be used to reproduce environments.
You may want to do this yourself on another machine, or use an environment defined by someone else—the process is the same in either case.

You can recreate an environment by passing either ``spack.yaml`` or ``spack.lock`` to ``spack env create``.
The file you choose determines whether the environment is built approximately from abstract specs or exactly from concrete specs.

""""""""""""""""""""
Using ``spack.yaml``
""""""""""""""""""""

An approximate (re-)build is created using the ``spack.yaml`` file.
This approach is useful when replicating environments across different platforms or when aiming to match general software requirements rather than exact versions.

Using ``spack.yaml`` preserves the *abstract* intent of the environment (e.g., package names and constraints), but the actual concretization may differ if:

- The platform has different compilers or external packages
- The Spack package recipes or configuration have changed
- The default versions or variants have been updated

Let's create a new environment called ``abstract`` using the ``spack.yaml`` file:

.. literalinclude:: outputs/environments/create-from-file-1.out
   :language: console

As shown, Spack created a new *managed* environment using the name we provided.

Since it's newly created, no specs have been installed yet.
We can confirm this by activating the environment and running ``spack find``:

.. literalinclude:: outputs/environments/find-env-abstract-1.out
   :language: console

We see that the environment includes the same root specs listed in the original ``spack.yaml`` file, but they have not yet been installed.


""""""""""""""""""""
Using ``spack.lock``
""""""""""""""""""""

The ``spack.lock`` file enables *exact* reproduction of a previously concretized environment.
This is possible because it encodes all decisions made during the original concretization process, including package versions, variants, compilers, and dependency resolutions.

Let's create a new environment called ``concrete`` using the ``spack.lock`` file:

.. literalinclude:: outputs/environments/create-from-file-2.out
   :language: console

As shown, Spack created another *managed* environment using the provided name.

Since we created this environment from the ``spack.lock`` file, it includes not just the root specs—but also all the concrete, previously installed packages.
We can confirm this by activating the environment and running ``spack find``:

.. literalinclude:: outputs/environments/find-env-concrete-1.out
   :language: console

.. note::

   Reproducing a build from ``spack.lock`` currently requires running on a  
   machine with the same platform (architecture, OS, etc.) as the one where  
   the lockfile was originally created.

-------------------
More information
-------------------

This tutorial only scratches the surface of what environments in Spack can do.
For more in-depth guidance, refer to the resources below.

^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
Setting up and building environments
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

* `Environments <https://spack.readthedocs.io/en/latest/environments.html>`_: reference docs
* `Configuration tutorial <https://spack-tutorial.readthedocs.io/en/latest/tutorial_configuration.html>`_: customizing environment configuration  
* `Spack stacks tutorial <https://spack-tutorial.readthedocs.io/en/latest/tutorial_stacks.html>`_: managing combinatorial environments (e.g., same packages across multiple compilers)  
* `Install-level parallel builds <https://spack.readthedocs.io/en/latest/packaging_guide.html#install-level-build-parallelism>`_: using parallelism to speed up large environment builds

^^^^^^^^^^^^^^^^^^^^^^^
Using environments
^^^^^^^^^^^^^^^^^^^^^^^

* `Developer workflows <https://spack-tutorial.readthedocs.io/en/latest/tutorial_developer_workflows.html>`_: developing software in an active environment  
* `GitLab CI pipelines with Spack environments <https://spack.readthedocs.io/en/latest/pipelines.html>`_: using environments to define and run CI/CD pipelines  
* `Container Images <https://spack.readthedocs.io/en/latest/containers.html>`_: building container images directly from Spack environments  
* `Spack stacks tutorial <https://spack-tutorial.readthedocs.io/en/latest/tutorial_stacks.html>`_: deploying large-scale, multi-config environments

^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
Finding examples of environments
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

* `Spack Stack Catalog <https://spack.github.io/spack-stack-catalog/>`_: searchable catalog of example environments and configurations on GitHub
