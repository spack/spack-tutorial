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

Now we'll explore Spack Environments, a powerful feature that lets us manage collections of packages together in a documented and reproducible way.
Spack environments are similar to *virtual environments* in other package managers (e.g., `Python venv <https://docs.python.org/3/library/venv.html>`_, `Conda Environments <https://docs.conda.io/projects/conda/en/stable/user-guide/getting-started.html>`_, or `nix-env <https://nix.dev/manual/nix/2.24/command-ref/nix-env>`_).

Managing a software stack with many packages and varying configuration can quickly become hard to track by hand.
An environment lets you:

* Establish a standard set of requirements for a project,
* Install and use them together as a unit,
* Reproduce the same build on another machine, and
* Document your software stack for collaborators, CI/CD pipelines, and releases.

Each environment is captured in two shareable files: ``spack.yaml`` records the requested specs and configuration, while ``spack.lock`` captures the fully concrete build for reproducibility.
We'll look at both in detail later in this tutorial.


-------------------------
Working with Environments
-------------------------

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
   Once we activate an environment it will show up highlighted in green in the list of environments.

Now let's **activate** our environment by running the ``spack env activate`` command or ``spacktivate`` alias:

.. literalinclude:: outputs/environments/env-activate-1.out
   :language: console

.. note::
   If we use the ``-p`` option for ``spack env activate``, Spack will prepend the environment name to our shell prompt.
   This is a handy way to be reminded if and which environment you are in.

.. note::
   For quick experiments you don't intend to keep, ``spack env activate --temp`` creates and activates a fresh, unnamed environment in a temporary directory.
   We'll use a regular named environment throughout this tutorial, but ``--temp`` is handy when you just want to try something out.

Once we activate an environment, ``spack find`` will only show what is in the current environment.
For example, because we just created this environment the output below doesn't show any installed packages.

.. literalinclude:: outputs/environments/find-env-1.out
   :language: console

.. note::
   Although Spack doesn't show all installed software packages when in an active environment, Spack will reuse packages across environments to save disk space and reduce build times.

Additionally the output now tells us that we're in the ``myproject`` environment, so there is no need to panic when we no longer see our previously installed packages.
It also states that there are **no** *root specs*.
We'll get back to what that means later.

While this detailed output is useful, if we *only* want to check what environment we are in, we can use ``spack env status``:

.. literalinclude:: outputs/environments/env-status-1.out
   :language: console


To now exit out of this environment, we can use ``spack env deactivate`` or ``despacktivate`` if we're feeling fancy.

After deactivating, we can see everything installed in this Spack instance:

.. literalinclude:: outputs/environments/env-status-2.out
   :language: console

^^^^^^^^^^^^^^^^^^^
Installing Packages
^^^^^^^^^^^^^^^^^^^

Now that we understand how creation and activation work, let's go back to our ``myproject`` environment and install a couple of packages, specifically ``tcl`` and ``trilinos``.

Installing software in an environment follows three steps:

1. **add** the specs we want, registering them as *root specs* of the environment;
2. **concretize** the environment, resolving every root and its dependencies into a concrete set; and
3. **install** the concretized specs.

We'll walk through them one at a time.

First, we *add* our two specs with ``spack add``:

.. literalinclude:: outputs/environments/env-add-1.out
   :language: console

``tcl`` and ``trilinos`` are now registered as **root specs** i.e. the packages we've explicitly requested.
They're called **"roots"** because they sit at the top of the dependency graph, with their dependency packages sitting below them.

If we run ``spack find`` now, it lists them as roots but reports nothing concretized yet.
Adding a spec only records our intent:

.. literalinclude:: outputs/environments/env-add-find-1.out
   :language: console

Next, we *concretize* the environment, resolving those roots and all their dependencies into a concrete set:

.. literalinclude:: outputs/environments/env-concretize-1.out
   :language: console

The ``spack find`` above hinted at this with *show with* ``spack find -c``.
Now that the environment is concretized, that command lists the concrete set, including the packages still to be installed:

.. literalinclude:: outputs/environments/env-find-c-1.out
   :language: console

Finally, we *install*:

.. literalinclude:: outputs/environments/env-install-1.out
   :language: console

We can see that Spack reused existing installations of ``tcl`` and the dependencies of ``trilinos`` that were already present on the system, rather than rebuilding them from scratch.
Additionally, the environment's view was automatically updated to include the installations.
This means all the software in this environment has been added to our PATH, making the installed packages readily accessible from the command line while we have the environment activated.

Let's confirm the contents of the environment using ``spack find``:

.. literalinclude:: outputs/environments/find-env-2.out
   :language: console

We can see that the roots and their dependencies have been installed.
The packages reported as *concretized packages to be installed* are build-only dependencies, which Spack skips when it installs from binaries.

.. note::

   We walked through the three steps separately, but in practice ``spack install`` concretizes for you, so ``spack add`` followed by ``spack install`` is all you need.
   You must still add a spec before installing it, which prevents you from accidentally changing a shared environment.
   Adding all specs before installing also lets Spack concretize them together, so they share dependencies and can all build in parallel.

^^^^^^^^^^^^^^^^^^^^^^^^
Using installed packages
^^^^^^^^^^^^^^^^^^^^^^^^

Activating an environment adds all of its installed software to our shell search paths through a feature called *environment views*.
A view is a directory tree of symlinks to all installed packages, structured like a standard Linux filesystem (``bin/``, ``lib/``, ``include/``, ...).

For example, ``tcl`` ships a shell called ``tclsh``.
Activating ``myproject`` puts it on our ``PATH``:

.. literalinclude:: outputs/environments/use-tcl-1.out
   :language: console

Notice the path includes the environment name and a ``view`` subdirectory.
With ``openmpi`` installed in ``myproject`` as a dependency of ``trilinos``, ``mpicc`` is also on our ``PATH``:

.. literalinclude:: outputs/environments/show-mpicc-1.out
   :language: console

This means we can compile code against the environment's packages without any manual ``-I`` or ``-L`` flags.
Let's build a small program that uses both MPI and ``zlib``:

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

.. literalinclude:: outputs/environments/use-mpi-1.out
   :language: console

If we look at the full set of path variables activation set:

.. literalinclude:: outputs/environments/show-paths-1.out
   :language: console

we find ``CMAKE_PREFIX_PATH`` and ``PKG_CONFIG_PATH`` too, so build tools find the environment's libraries and headers automatically.

^^^^^^^^^^^^^^^^^
Removing Packages
^^^^^^^^^^^^^^^^^

Spack offers two ways to get rid of a package in an environment:

* ``spack remove`` takes a spec *out of the environment*
* ``spack uninstall`` deletes the installed files *from disk*

In a setup with several environments these behave quite differently, so let's create a second environment to see how.
We'll create ``myproject2``, activate it, and add both ``scr`` and ``trilinos``:

.. literalinclude:: outputs/environments/env-create-2.out
   :language: console

then concretize and install as usual:

.. code-block:: console

   $ spack concretize
   $ spack install

``spack find`` lets us confirm the environment now holds both roots and their dependencies:

.. literalinclude:: outputs/environments/env-create-2-find.out
   :language: console

So ``myproject`` contains ``tcl`` and ``trilinos``, while ``myproject2`` contains ``scr`` and ``trilinos``.

Let's start with the simplest case.
``scr`` is used only by ``myproject2``, so we can remove it cleanly.
``spack remove`` is the counterpart to ``spack add``: it drops ``scr`` as a root spec.

.. literalinclude:: outputs/environments/env-remove-scr-1.out
   :language: console

That only updates the environment's configuration, though.
Right afterward, ``spack find`` still lists ``scr``.
It is no longer a root, but it is still part of the environment:

.. literalinclude:: outputs/environments/env-remove-scr-2.out
   :language: console

To actually drop it, we reconcretize the environment:

.. literalinclude:: outputs/environments/env-remove-scr-3.out
   :language: console

Now ``scr``, along with any dependencies nothing else needs, has been pruned, and ``spack find`` no longer lists it:

.. literalinclude:: outputs/environments/env-remove-scr-4.out
   :language: console

``trilinos`` is a more interesting case, because ``myproject`` uses it too.
Environments only *point to* shared installations rather than owning the files, so Spack won't let us delete one out from under another environment.
If we try to uninstall ``trilinos`` from ``myproject2``, Spack refuses, since ``myproject`` still references it:

.. literalinclude:: outputs/environments/env-uninstall-1.out
   :language: console

As the error suggests, ``spack remove`` is the right tool: it takes ``trilinos`` out of ``myproject2`` without touching the shared installation.

.. literalinclude:: outputs/environments/env-remove-1.out
   :language: console

We know ``trilinos`` is still needed by ``myproject``, so let's switch back and confirm it's still there:

.. literalinclude:: outputs/environments/env-swap-1.out
   :language: console

``myproject`` still has ``trilinos`` as a root spec.


.. _environments-on-disk:

--------------------
Environments on disk
--------------------

We have been treating an environment as an abstraction, but it is really just a directory on disk.
``spack cd -e`` takes us to ``myproject``'s directory:

.. literalinclude:: outputs/environments/filenames-1.out
   :language: console

Because we created ``myproject`` with ``spack env create <name>``, it lives under ``var/spack/environments`` inside the Spack installation.
This is what makes it a *managed* environment: we can refer to it by name.
Environments can also be *independent*, with their files placed in any directory of our choosing.

The directory holds the two files that define the environment:

* ``spack.yaml``: the *manifest* file containing the abstract specs we asked for plus configuration settings.
* ``spack.lock``: the *lockfile* contaning the concrete specs generated whenever the environment is concretized.

``spack.yaml`` is the human-readable file we have been editing indirectly with ``spack add`` and ``spack remove``:

.. literalinclude:: outputs/environments/cat-config-1.out
   :language: spec

The ``concretizer:unify: true`` setting ensures all specs in the environment share a single version of each dependency.
``spack.lock`` records the fully concretized environment (every package, version, variant, and dependency) so the build can be reproduced exactly.
It is machine-readable JSON:

.. literalinclude:: outputs/environments/lockfile-1.out
   :language: console

The full file runs to thousands of lines.
A hidden ``.spack-env`` directory (not shown by ``ls``) sits alongside these files and holds Spack's bookkeeping, including the view we used earlier.

Managed environments also appear by name in ``spack env list``, with the active one highlighted:

.. literalinclude:: outputs/environments/env-list-2.out
   :language: console

We will come back to both files when we reproduce environments later.

------------------------
Configuring environments
------------------------

We've seen ``spack.yaml`` contains the root specs of the environment.
It also controls **configuration settings** that shape how Spack behaves when the environment is used.

Let's edit ``spack.yaml`` to *require* ``mpich`` as our ``mpi`` provider using ``spack config edit`` (make sure ``EDITOR`` is set first).
You should now have ``spack.yaml`` open in your editor.
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

The environment is now out of sync: ``myproject`` was installed with ``openmpi``, but the configuration now requires ``mpich``.
If we run ``spack concretize``, Spack sees the existing concretization is still valid and does nothing:

.. literalinclude:: outputs/environments/concretize-1.out
   :language: console

To force Spack to re-concretize from scratch, use ``spack concretize --force``:

.. literalinclude:: outputs/environments/concretize-f-1.out
   :language: console

All the specs are now concrete with ``mpich`` as the MPI implementation, ready to be installed.
Next you'd run ``spack install`` to rebuild the environment with the new MPI provider.

.. note::

   In general, when building an environment it is also possible to add and install specs one at a time, but Spack will then concretize each new spec *greedily* against the versions already locked in.
   This can lead to a different (and sometimes less optimal) result than concretizing everything together.

--------------------
Sharing environments
--------------------

The ``spack.yaml`` and ``spack.lock`` files we have been working with are not just a record of the environment: they are also the mechanism for sharing it.
You can commit them to version control, hand them to a colleague, or drop them into a CI/CD pipeline.
Anyone with a Spack installation can recreate the environment from them.

To demonstrate, we'll play the role of the recipient of a shared environment.
Let's build a fresh independent environment in a new ``code/`` directory — it stands in for a project a colleague has shared with us:

.. literalinclude:: outputs/environments/independent-create-1.out
   :language: console

Since the environment is independent, it must be activated by path, not by name.
Edit the ``spack.yaml`` created in the directory to add ``trilinos`` and ``openmpi``:

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

.. literalinclude:: outputs/environments/install-independent-1.out
   :language: console

Passing either of these files to ``spack env create`` recreates the environment.
The ``spack.yaml`` file preserves the abstract requirements but allows the concretizer to adapt to a new platform.
The ``spack.lock`` file fixes every concretization decision and reproduces the build exactly.

^^^^^^^^^^^^^^^^^^^^
Using ``spack.yaml``
^^^^^^^^^^^^^^^^^^^^

Recreating from ``spack.yaml`` preserves the root specs but leaves dependency resolution to the concretizer, which may produce different versions on a new platform or as packages are updated:

.. literalinclude:: outputs/environments/create-from-file-1.out
   :language: console

The new environment has no installed packages yet — only the root specs from the file are registered:

.. literalinclude:: outputs/environments/find-env-abstract-1.out
   :language: console

^^^^^^^^^^^^^^^^^^^^
Using ``spack.lock``
^^^^^^^^^^^^^^^^^^^^

Recreating from ``spack.lock`` reproduces the exact build, and thus requires the same machine architecture.
All packages recorded in the lockfile are installed without a separate install step:

.. literalinclude:: outputs/environments/create-from-file-2.out
   :language: console

Since the environment was created from ``spack.lock``, the root specs and all their dependencies are already installed:

.. literalinclude:: outputs/environments/find-env-concrete-1.out
   :language: console

---------------------
Removing environments
---------------------

Let's clean up the environments we created during the tutorial.
First, deactivate the current environment:

.. code-block:: console

   $ spack env deactivate

Then remove all the managed environments at once:

.. code-block:: console

   $ spack env rm myproject myproject2 abstract concrete

-------------------
More information
-------------------

This tutorial only scratches the surface of environments and what they can do.
For more information, take a look at the Spack resources below.

^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
Setting up and building environments
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

* `Environments <https://spack.readthedocs.io/en/latest/environments.html>`_: reference docs
* `Configuration tutorial <https://spack-tutorial.readthedocs.io/en/latest/tutorial_configuration.html>`_: for customizing your environment
* `Spack stacks tutorial <https://spack-tutorial.readthedocs.io/en/latest/tutorial_stacks.html>`_: for configuring combinatorial environments
* `Install-level parallel builds <https://spack.readthedocs.io/en/latest/config_yaml.html#build-jobs>`_: for how to launch ``spack install`` to build your environment in parallel

^^^^^^^^^^^^^^^^^^^^^^^
Using environments
^^^^^^^^^^^^^^^^^^^^^^^

* `Developer workflows <https://spack-tutorial.readthedocs.io/en/latest/tutorial_developer_workflows.html>`_: for developing code in an environment
* `GitLab CI pipelines with Spack environments <https://spack.readthedocs.io/en/latest/pipelines.html>`_: for using environments to generate CI pipelines
* `Container Images <https://spack.readthedocs.io/en/latest/containers.html>`_: for creating containers from environments

^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
Finding examples of environments
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

* `Spack Stack Catalog <https://spack.github.io/spack-stack-catalog/>`_: for discovering environments that you can explore on GitHub
