.. Copyright Spack Project Developers. See COPYRIGHT file for details.

   SPDX-License-Identifier: (Apache-2.0 OR MIT)

.. include:: common/setup.rst

.. _stacks-tutorial:

===============
Stacks Tutorial
===============

Spack environments are a powerful tool not just for managing a single user's project, but for deploying entire software stacks.
In this tutorial we will see how to use them to manage large deployments, a common pattern in HPC centers.

What usually characterizes these deployments, compared to a typical single-user environment, is the need to provide the same set of packages built against a variety of configurations: different MPI libraries, LAPACK implementations, or compilers.

Below, we'll build a representative example of such a deployment.
Our goal is to install ``netlib-scalapack`` against:

- two MPI libraries (``openmpi`` and ``mpich``)
- two LAPACK providers (``openblas`` and ``netlib-lapack``)

and compiled with ``gcc@16``, which is newer than the system-provided ``gcc@15``.
We'll also install ``py-scipy`` linked against ``openblas``.

We'll first focus on how to configure and install the software correctly.
Then we'll discuss how to make it accessible to users through environment views and module files.

----------------------------
Installing a Software Stack
----------------------------

Let's start by creating an environment in a directory of our choice:

.. literalinclude:: outputs/stacks/setup-0.out
   :language: console

The first step is to install the compiler we want to use.
Let's write a minimal ``spack.yaml`` that contains just the compiler and ``lmod``, which we'll need later to generate module files:

.. literalinclude:: outputs/stacks/examples/compiler.spack.stack.yaml
   :language: yaml

Concretize and install:

.. literalinclude:: outputs/stacks/compiler-0.out
   :language: console

^^^^^^^^^^^
Spec groups
^^^^^^^^^^^

We are now ready to build the software stack on top of this compiler.
To do that cleanly, we'll use *spec groups*, which allow you to organize specs into named collections, each with its own configuration and concretization order.

Let's start with a single spec and a two-group ``spack.yaml``:

.. literalinclude:: outputs/stacks/examples/groups-0.spack.stack.yaml
   :language: yaml
   :emphasize-lines: 7-14

The environment declares two groups:

1. The ``compiler`` group contains GCC 16 and ``lmod`` (both already installed).
2. The ``stack`` group lists the software we want to deploy.

The ``needs: [compiler]`` declaration ensures that the ``compiler`` group is always concretized *before* the ``stack`` group, making its specs available for reuse.

Let's concretize to see this in action:

.. literalinclude:: outputs/stacks/groups-0.out
   :language: console

Notice that the ``compiler`` group is processed first, and ``gcc@16`` is immediately reused by the ``stack`` group.

We just used ``%gcc@16`` to pin the compiler, but it's a coarse constraint that must be repeated on every spec and does not distinguish between C, C++, and Fortran compilers.
Spec groups offer a better tool: the ``override`` block, which scopes any Spack configuration to a single group.

.. literalinclude:: outputs/stacks/examples/groups-1.spack.stack.yaml
   :language: yaml
   :emphasize-lines: 11-18,23-30

Here we used it to set compiler preferences at the language level, once for each group:

1. The ``compiler`` group prefers ``gcc@15``
2. The ``stack`` group prefers ``gcc@16``

These language preferences are expressed once and apply automatically to every spec in the group.

^^^^^^^^^^^^^^^^^^^^^^^^^^
Tuning concretizer options
^^^^^^^^^^^^^^^^^^^^^^^^^^

Now we add a second MPI variant to the stack, listing both ``^openmpi`` and ``^mpich`` variants of ``netlib-scalapack``:

.. literalinclude:: outputs/stacks/examples/0.spack.stack.yaml
   :language: yaml
   :emphasize-lines: 22-23

The ``stack`` group now has two conflicting configurations, so before concretizing let's check the ``concretizer:unify`` option:

.. literalinclude:: outputs/stacks/unify-2.out
   :language: console

With ``unify:true``, the concretizer restricts the environment to a single configuration of each package within its *root unification set*: the nodes reachable from the root specs via link or run edges.
Pure build dependencies, which fall outside the set, are not affected:

.. image:: _static/images/stacks-unify.svg

This is the right default for a single-user environment, since it ensures a filesystem view can be built without conflicts.
A software stack, however, requires multiple configurations of the same package by design, so we need to relax this constraint.

Let's update ``spack.yaml`` to set ``unify: false`` and concretize:

.. literalinclude:: outputs/stacks/examples/1.spack.stack.yaml
   :language: yaml
   :emphasize-lines: 33-34

.. literalinclude:: outputs/stacks/unify-3.out
   :language: console

With ``unify: false``, Spack concretizes each root spec independently and merges the results, which is exactly what a software stack needs.

.. note::

   If the environment is expected to have only a few duplicate nodes, there is another option to consider:

   .. code-block:: console

      $ spack config add concretizer:unify:when_possible

   With this option Spack tries to unify the environment in an eager, multi-round process.
   The concretization at round ``n`` contains all the specs that could not be unified at round ``n-1``, and considers all the specs from previous rounds for reuse.

^^^^^^^^^^^^^
Spec matrices
^^^^^^^^^^^^^

Let's further expand our stack to link against different LAPACK providers as well.
Adding them explicitly would be tedious, so we use a *matrix* to express the cross-product compactly:

.. literalinclude:: outputs/stacks/examples/2.spack.stack.yaml
   :language: yaml
   :emphasize-lines: 22-25

A matrix expands to the cross-product of its rows.
This matrix:

.. code-block:: yaml

   - matrix:
     - [netlib-scalapack]
     - [^openmpi, ^mpich]
     - [^openblas, ^netlib-lapack]

is equivalent to this explicit list of specs:

.. code-block:: yaml

   - "netlib-scalapack ^openblas ^openmpi"
   - "netlib-scalapack ^openblas ^mpich"
   - "netlib-scalapack ^netlib-lapack ^openmpi"
   - "netlib-scalapack ^netlib-lapack ^mpich"

No compiler annotation appears in the matrix rows: the ``override`` block in the ``stack`` group handles that.
Let's concretize to verify our four variants:

.. literalinclude:: outputs/stacks/concretize-0.out
   :language: console

We now have four variations of ``netlib-scalapack`` ready to install.

^^^^^^^^^^^^^^^^^^^^
Reusable definitions
^^^^^^^^^^^^^^^^^^^^

So far each matrix row has been written out inline.
When multiple matrices share rows, duplicating them becomes a maintenance burden.
Spack allows *defining* lists of constraints under the ``definitions`` attribute and reusing them across matrices.
Let's rewrite our manifest using definitions:

.. literalinclude:: outputs/stacks/examples/3.spack.stack.yaml
   :language: yaml
   :emphasize-lines: 6-9,27-30

Concretizing confirms the result is identical:

.. literalinclude:: outputs/stacks/concretize-1.out
   :language: console

Now that we have definitions, we can add a second matrix for serial packages that link against LAPACK but not MPI.
In a real deployment this list might include many packages but here we use just ``py-scipy`` as an example.
Not every combination is meaningful though: ``py-scipy ^netlib-lapack`` is not a useful build, so we use ``exclude`` to drop that specific entry from the cross-product:

.. literalinclude:: outputs/stacks/examples/4bis.spack.stack.yaml
   :language: yaml
   :emphasize-lines: 10,32-36

Concretize the environment again:

.. literalinclude:: outputs/stacks/concretize-3.out
   :language: console

The exclusion worked: the environment contains only ``py-scipy ^openblas``:

.. literalinclude:: outputs/stacks/concretize-4.out
   :language: spec

^^^^^^^^^^^^^^^^^^^^^^^
Conditional definitions
^^^^^^^^^^^^^^^^^^^^^^^

A common need in multi-site or multi-cluster deployments is enabling different software sets based on environment variables or host properties.
Definitions support a ``when`` clause for exactly this.
``when`` is a Python expression evaluated at concretization time, with access to the following variables:

================= ===========
variable name     value
================= ===========
``platform``      The spack platform name for this machine
``os``            The default spack os name and version string for this machine
``target``        The default spack target string for this machine
``architecture``  The default spack architecture string platform-os-target for this machine
``arch``          Alias for ``architecture``
``env``           A dictionary representing the users environment variables
``re``            The python ``re`` module for regex
``hostname``      The hostname of this node
================= ===========

Suppose we want to build with ``mpich`` by default, and add ``openmpi`` when a site-specific environment variable is set.
We can express this with two definitions of ``mpis``, the second guarded by a ``when`` clause:

.. literalinclude:: outputs/stacks/examples/5.spack.stack.yaml
   :language: yaml
   :emphasize-lines: 7-9

When multiple definitions share the same name, they are concatenated, so the conditional entry simply appends ``openmpi`` to the list when the variable is set.

First, concretize without the variable:

.. literalinclude:: outputs/stacks/concretize-5.out
   :language: spec

Only ``mpich`` is used.
Now set the variable and re-concretize:

.. literalinclude:: outputs/stacks/concretize-6.out
   :language: console

Both MPI providers are now active.

We now have a complete, well-structured environment.
It's time to install it:

.. literalinclude:: outputs/stacks/install-0.out
   :language: console

^^^^^^^^^^^^^^^^^^^^^
Other useful features
^^^^^^^^^^^^^^^^^^^^^

Before moving to views and modules, two other features are worth knowing about.

The first is source mirrors.
When the environment is active, creating one is as simple as:

.. code-block:: console

   $ spack mirror create --all -d ./stacks-mirror

This fetches all the tarballs listed in ``spack.lock`` into the given directory.
You can then move the mirror to an air-gapped machine and register it with:

.. code-block:: console

   $ spack mirror add <name> <stacks-mirror>

This lets you rebuild the specs from source on the target machine.
Alternatively, to create a buildcache you can:

.. code-block:: console

   $ spack gpg create <name> <e-mail>
   $ spack buildcache push ./mirror

Don't forget to set an appropriate value for the padding of the install tree, see `how to setup relocation <https://spack.readthedocs.io/en/latest/binary_caches.html#relocation>`_ in our documentation.

-------------------
Environment Views
-------------------

A simple view won't work with a stack: we have multiple configurations of the same package, and they would conflict if linked into the same directory tree.
What we can do instead is create *multiple views*, using view descriptors that specify which packages are included and how they are projected onto the filesystem.

Edit our ``spack.yaml`` to add view descriptors:

.. literalinclude:: outputs/stacks/examples/6.spack.stack.yaml
   :language: yaml
   :emphasize-lines: 49-62

In the configuration above we created two views, named ``default`` and ``full``.
The ``default`` view consists of all the packages compiled with ``gcc@16``, but excluding those that depend on ``mpich`` or ``netlib-lapack``.
As we can see, we can both *include* and *exclude* specs using constraints.

The ``full`` view uses a more complex projection to place each spec into an appropriate subdirectory, according to the first constraint that matches.
``all`` is the default projection and always has the lowest priority, regardless of the order in which it appears.
To avoid confusion, we advise always keeping it last in projections.

Concretize to regenerate the views and check their structure:

.. literalinclude:: outputs/stacks/view-0.out
   :language: console

The view descriptor also contains a ``link`` key.
The default behavior, as we have seen, is to link all packages — including implicit link and run dependencies — into the view.
If we set the option to ``"roots"``, Spack links only the root packages into the view:

.. literalinclude:: outputs/stacks/examples/7.spack.stack.yaml
   :language: yaml
   :emphasize-lines: 54

.. literalinclude:: outputs/stacks/view-1.out
   :language: console

Now we see only the root libraries in the default view.
The rest are hidden, but are still available in the full view.
The complete documentation on views can be found `here <https://spack.readthedocs.io/en/latest/environments.html#environment-views>`_.

------------
Module Files
------------

Module files are another very popular way to use software on HPC systems.
In this section we'll show how to configure and generate a hierarchical module structure, suitable for ``lmod``.

A more in-depth tutorial, focused only on module files, can be found at :ref:`modules-tutorial`.
There we discuss the general architecture of module file generation in Spack and we highlight differences between ``environment-modules`` and ``lmod`` that won't be covered in this section.

Since ``lmod`` is already part of our compiler group and has been installed, we just need to add the ``module`` command to our shell:

.. code-block:: console

   $ . $(spack location -i lmod)/lmod/lmod/init/bash

If everything worked out correctly you should have the module command available in your shell:

.. literalinclude:: outputs/stacks/modules-1.out
   :language: console

The next step is to add some basic configuration to our ``spack.yaml`` to generate module files:

.. literalinclude:: outputs/stacks/examples/8.spack.stack.yaml
   :language: yaml
   :emphasize-lines: 50-61

In these few lines of additional configuration we told Spack to generate ``lmod`` module files in a subdirectory named ``modules``, using a hierarchy comprising both ``lapack`` and ``mpi``.
We've also configured it to place all specs built with our system compiler into the ``Core`` designation in the lmod hierarchy.

We can generate the module files and use them with the following commands:

.. code-block:: console

   $ spack module lmod refresh -y
   $ module use $PWD/stacks/modules/linux-ubuntu26.04-x86_64/Core

Now we should be able to see the module files that have been generated:

.. literalinclude:: outputs/stacks/modules-2.out
   :language: console

The set of modules is already usable, and the hierarchy already works.
For instance, we can load the ``gcc`` compiler and check that we have ``gcc`` in our path and a lot of modules available — all the ones compiled with ``gcc@16``:

.. literalinclude:: outputs/stacks/modules-3.out
   :language: console

There are a few issues though.
For instance, we have a lot of modules generated from dependencies of ``gcc`` that are cluttering the view, and won't likely be needed directly by users.
Then, module names contain hashes, which prevent users from being able to reuse the same script in similar, but not equal, environments.

Also, some of the modules might need to set custom environment variables, which are specific to deployment aspects not captured by the hash — for instance a policy at the deploying site.

To address all these needs we can extend our ``modules`` configuration:

.. literalinclude:: outputs/stacks/examples/9.spack.stack.yaml
   :language: yaml
   :emphasize-lines: 62-78

Regenerate the modules:

.. literalinclude:: outputs/stacks/modules-4.out
   :language: console

Now we have a set of module files without hashes, with a correct hierarchy, and with all our custom modifications:

.. literalinclude:: outputs/stacks/modules-5.out
   :language: console

This concludes the quick tour of module file generation, and the tutorial on stacks.

-------
Summary
-------

In this tutorial, we configured Spack to install a stack of software built on a cross-product of different MPI and LAPACK libraries, using a compiler newer than the one provided by the system.
We used spec groups to organize the environment into a compiler group and a stack group, leveraging the ``needs`` and ``override`` keys to control build order and compiler selection.
We used spec matrices and definitions to express the cross-product concisely, and conditional definitions to make the MPI selection configurable at concretization time.
Finally, we discussed how to make the software accessible to users through filesystem views and module files.
