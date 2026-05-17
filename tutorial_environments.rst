.. Copyright Spack Project Developers. See COPYRIGHT file for details.

   SPDX-License-Identifier: (Apache-2.0 OR MIT)

.. _environments-tutorial:

==================
Spack Environments
==================

Scientific software often depends on a stack of libraries (MPI, BLAS/LAPACK, FFTW, etc.) whose exact configuration affects both performance and correctness.
Reproducing a working build on a different machine, or sharing it with a collaborator, requires capturing not just the package list but the specific versions, variants, and compiler flags that Spack resolved.

A Spack environment records that information in two files: ``spack.yaml`` holds the abstract requirements and configuration, ``spack.lock`` captures every concretization decision.
Both can be versioned and shared, making the same software stack reproducible on another system.

This tutorial covers creating, configuring, and sharing Spack environments, using Quantum ESPRESSO as the working example throughout.

-------------
Initial Setup
-------------

Start the tutorial container:

.. code-block:: console

   $ docker pull ghcr.io/spack/tutorial:cineca26
   $ docker run -it ghcr.io/spack/tutorial:cineca26

Set up Spack inside the container:

.. code-block:: console

   $ git clone --depth=2 --branch=develop https://github.com/spack/spack
   $ . spack/share/spack/setup-env.sh
   $ spack repo update builtin --commit 79fd9821dceebf719a4cb544ba67c3b2f39132ca
   $ spack bootstrap now
   $ spack compiler find
   $ spack mirror add --unsigned tutorial /buildcache

Check that the setup is working before proceeding:

.. literalinclude:: outputs/environments/find-no-env-1.out
   :language: console

The output lists the compilers Spack has detected and all currently installed packages.
With a fresh installation, no packages are present and only a single compiler is available.

For help, join the ``#tutorial`` channel on Slack (invitation at `slack.spack.io <https://slack.spack.io/>`_).

------------------------------------
Creating and Activating Environments
------------------------------------

Create a new environment called ``myproject`` with ``spack env create``:

.. literalinclude:: outputs/environments/env-create-1.out
   :language: console

List all environments with ``spack env list``:

.. literalinclude:: outputs/environments/env-list-1.out
   :language: console


Activate ``myproject`` with ``spack env activate``:

.. literalinclude:: outputs/environments/env-activate-1.out
   :language: console

Once an environment is active, ``spack find`` shows only what it contains:

.. literalinclude:: outputs/environments/find-env-1.out
   :language: console

The output confirms the active environment is ``myproject`` and, because it was just created, shows no installed packages and no root specs.
Root specs are the packages explicitly added to the environment; dependencies are resolved automatically.
While an environment is active, ``spack find`` and ``spack install`` operate within its scope and are unaware of packages outside it.

To check which environment is active without the full package listing, use ``spack env status``:

.. literalinclude:: outputs/environments/env-status-1.out
   :language: console

Deactivate the environment with ``spack env deactivate`` or the ``despacktivate`` shorthand:

.. literalinclude:: outputs/environments/env-status-2.out
   :language: console

-------------------
Installing packages
-------------------

Environments maintain an explicit list of which packages they contain.
Adding a spec to that list and installing it on disk are two separate operations.
This separation allows queuing several specs before building them all at once, and prevents accidental modifications to shared environments.

Re-activate ``myproject`` before adding packages:

.. code-block:: console

   $ spack env activate myproject

Use ``spack add`` to register specs in the environment's manifest:

.. literalinclude:: outputs/environments/env-add-1.out
   :language: spec

``quantum-espresso`` and ``py-numpy`` are now registered as **root specs** in ``myproject``:

.. literalinclude:: outputs/environments/env-add-find-1.out
   :language: spec

Concretize the environment to resolve all dependencies:

.. literalinclude:: outputs/environments/env-install-1.out
   :language: console

Install the concretized packages:

.. code-block:: console

   spack install

Because packages are fetched from a binary cache, Spack downloads pre-compiled binaries and only installs runtime dependencies.
Build-time tools such as ``cmake`` or ``autoconf`` are part of the concretized spec but are not installed locally, since the binaries were already compiled elsewhere.
Once installation completes, the environment's view is updated so that everything is immediately accessible on ``PATH``.

Confirm the contents with ``spack find``:

.. literalinclude:: outputs/environments/find-env-2.out
   :language: console

Compared to the empty environment seen after activation, the output now lists two named root specs and 40 installed packages.
Root specs appear at the top. The remaining packages are dependencies that Spack resolved automatically.


--------------
Using Packages
--------------

Activating a Spack environment makes all its installed packages available in the shell through a feature called **environment views**.

An environment view is a directory structure mirroring a standard Linux root filesystem with directories like ``/bin`` and ``/usr`` that contain symbolic links to all the packages installed in your Spack environment.
When you activate an environment with ``spack env activate``, Spack automatically:

* Prepends the view's ``bin`` directory to your ``PATH`` environment variable
* Adds the view's ``man`` directory to your ``MANPATH`` for manual pages
* Updates ``CMAKE_PREFIX_PATH`` to include the view's root directory

This means that executables, libraries, and other files from your environment's packages become immediately accessible from the command line without any module loads or manual path changes.

After activation, ``pw.x`` is accessible directly on ``PATH``:

.. literalinclude:: outputs/environments/use-pwx-1.out
   :language: console

The path goes through the environment's ``view`` directory, which is where Spack maintains symlinks to all installed executables.

The full set of path-related variables set by activation is visible with ``env | grep PATH``:

.. literalinclude:: outputs/environments/show-paths-1.out
   :language: console

Deactivating the environment removes those directories from the shell's path variables, cleanly isolating the installation from the rest of the system:

.. literalinclude:: outputs/environments/env-deactivate-1.out
   :language: console

Re-activate ``myproject`` before continuing:

.. code-block:: console

   $ spack env activate myproject

--------------------------
Inspecting the environment
--------------------------

Two commands are useful for inspecting the active environment: ``spack find`` and ``spack spec``.

Each installed package has a hash that uniquely identifies its build configuration.
``spack find -l`` adds those hashes to the output:

.. literalinclude:: outputs/environments/find-l-1.out
   :language: console

Within an environment, ``spack spec`` reports the full concretized spec for a package, including all variants and compiler flags.
This is useful for inspecting a specific dependency in detail:

.. literalinclude:: outputs/environments/spec-openmpi-1.out
   :language: console

-----------------
Removing Packages
-----------------

Spack environments hold references to shared package installations, not the packages themselves.
Removing a spec from an environment's manifest therefore does not uninstall it from disk. Other environments referencing the same package are unaffected.

Use ``spack remove`` to drop a spec from the manifest:

.. literalinclude:: outputs/environments/env-remove-1.out
   :language: console

``py-numpy`` no longer appears as a root spec, but it remains installed on disk and mentioned in the environment.
Concretizing the environment reconciles the manifest with the installed state and prunes packages that are no longer needed:

.. literalinclude:: outputs/environments/env-concretize-remove-1.out
   :language: console

``py-numpy`` and its exclusive dependencies are no longer listed in the environment.
Since no other environment references ``py-numpy``, it can now be removed from disk.

Because the environment is still active, a plain ``spack uninstall`` would search only within the active environment's view and find nothing.
The ``-E`` flag tells Spack to ignore the active environment and operate on the full package store:

.. literalinclude:: outputs/environments/env-uninstall-1.out
   :language: console

.. note::

   ``spack uninstall --remove py-numpy`` combines all three steps into one: it removes the spec from the manifest, reconciles the environment, and uninstalls from disk, provided no other environment references it.

Restore ``py-numpy`` to the environment before continuing:

.. literalinclude:: outputs/environments/env-restore-1.out
   :language: console

--------------------
Environments on disk
--------------------

Two files define a Spack environment:

.. list-table::
   :header-rows: 1
   :widths: 20 80

   * - File
     - Contents
   * - ``spack.yaml``
     - *Abstract* specs and configuration settings.
   * - ``spack.lock``
     - Fully *concrete* specs generated during concretization.

Environments created by Spack are stored by default in the ``var/spack/environments`` directory of your Spack instance.
Navigate to ``myproject``'s directory with ``spack cd``:

.. literalinclude:: outputs/environments/filenames-1.out
   :language: console

The directory contains both environment files.
Inspect ``spack.yaml``:

.. literalinclude:: outputs/environments/cat-config-1.out
   :language: yaml

The ``view`` key controls whether Spack maintains a symlink tree for the installed files.
The ``concretizer:unify`` key determines how specs are concretized relative to each other:

.. list-table::
   :header-rows: 1
   :widths: 20 80

   * - Value
     - Behavior
   * - ``true`` (default)
     - All specs are concretized together; at most one version of each dependency appears in the environment.
   * - ``false``
     - Specs are concretized independently; multiple versions of a dependency can coexist.
   * - ``when_possible``
     - Spack unifies where it can and falls back to duplicates only when root specs require incompatible versions.

``spack.lock`` is the machine-readable record of every concretization decision, written in JSON.
Inspect the top 30 lines:

.. literalinclude:: outputs/environments/lockfile-1.out
   :language: console

While it is still readable, it consists of over 1900 lines representing the actual configurations for each of the environment's packages.

Environments created with ``spack env create <name>`` are *managed* environments: Spack stores them under ``var/spack/environments`` and tracks them by name.
You can also create *independent* environments with:

.. code-block:: console

   spack env create -d <path>
   
which allows you to store the environment files in any directory you choose and manage them yourself.


--------------------
Sharing environments
--------------------

Passing either of these files to ``spack env create`` recreates the environment.
The ``spack.yaml`` file preserves the abstract requirements but allows the concretizer to adapt to a new platform.
The ``spack.lock`` file fixes every concretization decision and reproduces the build exactly.

^^^^^^^^^^^^^^^^^^^^
Using ``spack.yaml``
^^^^^^^^^^^^^^^^^^^^

Recreating from ``spack.yaml`` preserves the root specs but leaves dependency resolution to the concretizer, which may produce different versions on a new platform or as packages are updated.

Create an environment called ``abstract`` from the file:

.. literalinclude:: outputs/environments/create-from-file-1.out
   :language: console

The new environment has no installed packages yet. Only the root specs from the file are registered:

.. literalinclude:: outputs/environments/find-env-abstract-1.out
   :language: console

^^^^^^^^^^^^^^^^^^^^
Using ``spack.lock``
^^^^^^^^^^^^^^^^^^^^

Recreating from ``spack.lock`` reproduces the exact build, and thus requires the same machine architecture.
All packages recorded in the lockfile are installed without a separate install step:

.. literalinclude:: outputs/environments/create-from-file-2.out
   :language: console

.. literalinclude:: outputs/environments/find-env-concrete-1.out
   :language: console

Re-activate ``myproject`` before proceeding to the next section:

.. code-block:: console

   $ spack env activate myproject

---------------------------
Configuring the environment
---------------------------

The goal for the rest of this section is to extend ``myproject`` so that it bootstraps ``gcc@16`` and then builds Quantum ESPRESSO with it, all within the same environment.
This requires *spec groups*, introduced in Spack 1.2, which allow different sets of specs to share scoped configuration and declare ordering dependencies between them.

``spack config edit`` opens ``spack.yaml`` in ``$EDITOR``.
Set it now if it is not already configured, as the remaining examples in this section edit the file directly:

.. code-block:: console

   $ export EDITOR=emacs

Replace the contents of ``spack.yaml`` with:

.. code-block:: yaml

   spack:
     specs:
     - group: compiler
       specs:
       - gcc@16 build_type=Release +profiled +strip
     - group: gcc-16-specs
       needs: [compiler]
       specs:
       - quantum-espresso %mpi=mpich
       override:
         packages:
           c:
             prefer: [gcc@16]
           cxx:
             prefer: [gcc@16]
           fortran:
             prefer: [gcc@16]
     view: false
     concretizer:
       unify: true

The ``needs`` key declares that a group is concretized and installed after the listed groups, ensuring ``gcc@16`` is available before Quantum ESPRESSO builds with it.
The ``override`` key sets package configuration that applies only to the specs within that group.
Re-concretize to apply the new configuration:

.. literalinclude:: outputs/environments/concretize-f-1.out
   :language: console

Install the environment:

.. code-block:: console

   $ spack install

Spack installs ``gcc@16`` first, then builds ``quantum-espresso`` with it:

.. literalinclude:: outputs/environments/find-gcc16-1.out
   :language: console

Concretizing and installing all specs together allows Spack to share dependencies across groups and enables `install-level parallelism <https://spack.readthedocs.io/en/latest/config_yaml.html#build-jobs>`_.

When multiple groups install packages built with different compilers, a single flat view directory produces symlink conflicts: two builds of the same file compete for the same path.
Named views assign a separate directory to each group, avoiding the conflict.
With ``view: false``, no executables are added to ``PATH`` on activation; for a single-group environment, ``view: true`` suffices.
Update ``spack.yaml`` to replace ``view: false`` with:

.. code-block:: yaml

   view:
     apps:
       root: ./views/qe
       group: gcc-16-specs
     compilers:
       root: ./views/compilers
       group: compiler

Regenerate the views:

.. literalinclude:: outputs/environments/view-regenerate-1.out
   :language: console

Activating with a different view name replaces the current one, so no explicit deactivation is needed between them.

Activate with the ``apps`` view to access Quantum ESPRESSO executables:

.. literalinclude:: outputs/environments/view-apps-1.out
   :language: console

Activate with the ``compilers`` view to access ``gcc@16``:

.. literalinclude:: outputs/environments/view-compilers-1.out
   :language: console

---------------------
Removing environments
---------------------

Remove the managed environments created during this tutorial:

.. code-block:: console

   $ spack env rm myproject abstract concrete

----------------
More information
----------------

* `Environments <https://spack.readthedocs.io/en/latest/environments.html>`_: reference docs
* `Configuration tutorial <https://spack-tutorial.readthedocs.io/en/latest/tutorial_configuration.html>`_: for customizing your environment
* `Spack stacks tutorial <https://spack-tutorial.readthedocs.io/en/latest/tutorial_stacks.html>`_: for combinatorial environments and large deployments
* `Install-level parallel builds <https://spack.readthedocs.io/en/latest/config_yaml.html#build-jobs>`_: for launching ``spack install`` in parallel
* `Developer workflows <https://spack-tutorial.readthedocs.io/en/latest/tutorial_developer_workflows.html>`_: for developing code inside an environment
* `GitLab CI pipelines with Spack environments <https://spack.readthedocs.io/en/latest/pipelines.html>`_: for generating CI pipelines from environments
* `Container Images <https://spack.readthedocs.io/en/latest/containers.html>`_: for creating containers from environments
* `Spack Stack Catalog <https://spack.github.io/spack-stack-catalog/>`_: for discovering environments on GitHub
