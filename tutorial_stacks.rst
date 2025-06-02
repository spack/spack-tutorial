.. Copyright 2013-2023 Lawrence Livermore National Security, LLC and other
   Spack Project Developers. See the top-level COPYRIGHT file for details.

   SPDX-License-Identifier: (Apache-2.0 OR MIT)

.. include:: common/setup.rst

.. _stacks-tutorial:

===============
Stacks Tutorial
===============

So far, we've discussed Spack environments in the context of unified user workflows.  
However, Spack environments have much broader capabilities.

In this tutorial, we'll explore how to use Spack environments to manage large software deployments.

The main difference between a typical environment for a single user and one used for large deployments is scope:  
in the latter case, we often need to install a set of packages across a wide range of MPI implementations, LAPACK libraries, or compilers.

In the following sections, we'll demonstrate how to create a software stack built as a cross-product of different LAPACK and MPI libraries, using a compiler that is newer than the one provided by the host system.

The first part focuses on how to properly configure and install the desired software.  
We'll learn how to pin certain requirements and how to express a cross-product of specs in a compact and flexible way.

Then, we'll consider how the installed software might be consumed by users, and examine the two main mechanisms that Spack provides for that: **views** and **module files**.

.. note::

   Before we start this hands-on, make sure the ``EDITOR`` environment variable is set to your
   preferred editor, for instance:

   .. code-block:: console

      $ export EDITOR='emacs -nw'

------------------
Setup the compiler
------------------

The first step in building our stack is to set up the compiler we want to use later.  
This is currently an iterative process that can be done in one of two ways:

 1. Install the compiler first, then register it in the environment  
 2. Use a separate environment dedicated to the compiler

In the following, we'll use the first approach.  
For those interested, an example of the second approach can be found `at this link <https://github.com/haampie/spack-intermediate-gcc-example/>`_.

Let's start by creating an environment in a directory of our choice:

.. literalinclude:: outputs/stacks/setup-0.out
   :language: console

Now we can add a new compiler from the command line.  
We'll also disable view generation for now, as we'll return to this topic later in the tutorial:

.. literalinclude:: outputs/stacks/setup-1.out
   :language: console

You should now see the following ``spack.yaml`` file on screen:

.. literalinclude:: outputs/stacks/examples/0.spack.stack.yaml
   :language: yaml
   :emphasize-lines: 8

The next step is to concretize and install our compiler:

.. literalinclude:: outputs/stacks/setup-2.out
   :language: console

Finally, let's register the new compiler in the environment:

.. literalinclude:: outputs/stacks/compiler-find-0.out
   :language: console

The ``spack location -i`` command returns the installation prefix for the spec being queried:

.. literalinclude:: outputs/stacks/compiler-find-1.out
   :language: console

This is generally useful when scripting Spack commands, as the example above shows.  
Listing the compilers now confirms the presence of ``gcc@12.3.0``:

.. literalinclude:: outputs/stacks/compiler-list-0.out
   :language: console

At this point, the manifest file looks like this:

.. literalinclude:: outputs/stacks/examples/1.spack.stack.yaml
   :language: yaml

We are now ready to build more software with our newly installed GCC!

------------------------
Install a software stack
------------------------

Now that we have a compiler ready, the next objective is to build software with it.  
We'll start by adding different versions of ``netlib-scalapack``, each linked against a different MPI implementation:

.. literalinclude:: outputs/stacks/unify-0.out
   :language: console

If we try to concretize the environment at this point, we'll encounter an error:

.. literalinclude:: outputs/stacks/unify-1.out
   :language: console

The error message is quite verbose—and admittedly a bit complex—but it ends with a useful hint:

.. code-block::

   You could consider setting `concretizer:unify` to `when_possible` or `false` to allow multiple versions of some packages.

Let's see what that means.

^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
Tuning concretizer options for a stack
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Whenever we concretize an environment with more than one root spec, we can configure Spack to be more or less strict about allowing duplicate nodes in the sub-DAG formed by following link and run dependencies from the roots.  
This subgraph is commonly referred to as the *root unification set*.

A diagram may help to better visualize the concept:

.. image:: _static/images/stacks-unify.svg

The image above represents our current environment, with the three root specs highlighted using a thicker dashed outline.  
Any node that can be reached via a link or run dependency from a root spec is part of the root unification set.  
Pure build dependencies may fall outside of it.

The configuration option that controls unification behavior is ``concretizer:unify``.  
Let's check its current value:

.. literalinclude:: outputs/stacks/unify-2.out
   :language: console

Setting ``concretizer:unify: true`` means that only one configuration of each package is allowed in the environment.  
This setting is ideal for single-project environments, since it ensures a unified view of all installed software, resembling a traditional Unix filesystem layout, without the risk of collisions between installations.

However, in our case, this strict unification is not feasible—our root specs already require two different configurations of ``netlib-scalapack``.  
Let's update the setting to ``false`` and try to re-concretize:

.. literalinclude:: outputs/stacks/unify-3.out
   :language: console

This time, concretization succeeds.  
Setting ``concretizer:unify: false`` effectively tells Spack to concretize each root spec independently, then merge the results into the environment.  
This allows us to retain multiple versions or configurations of the same package when necessary.

.. note::

   If the environment is expected to contain only a few duplicate nodes, there's another unification strategy worth considering:

   .. code-block:: console

      $ spack config add concretizer:unify:when_possible

   With this option, Spack will attempt to unify the environment eagerly by solving it in multiple rounds.  
   The concretization at round ``n`` includes all specs that could not be unified at round ``n-1``, and considers previous rounds' results for reuse.


^^^^^^^^^^^^^
Spec matrices
^^^^^^^^^^^^^

Let's expand our stack further to also link against different LAPACK providers.  
We could, of course, add new specs explicitly:

.. literalinclude:: outputs/stacks/unify-4.out
   :language: console

However, this approach becomes tedious as soon as additional software is required.  
The best way to express a cross-product like this in Spack is by using a **matrix**:

.. literalinclude:: outputs/stacks/examples/2.spack.stack.yaml
   :language: yaml
   :emphasize-lines: 8-12

Matrices expand to the cross-product of their rows. So the following matrix:

.. code-block:: yaml

   - matrix:
     - ["netlib-scalapack"]
     - ["^openmpi", "^mpich"]
     - ["^openblas", "^netlib-lapack"]
     - ["%gcc@12"]

is equivalent to this list of specs:

.. code-block:: yaml

   - "netlib-scalapack %gcc@12 ^openblas ^openmpi"
   - "netlib-scalapack %gcc@12 ^openblas ^mpich"
   - "netlib-scalapack %gcc@12 ^netlib-lapack ^openmpi"
   - "netlib-scalapack %gcc@12 ^netlib-lapack ^mpich"

We're now ready to concretize and install the environment:

.. literalinclude:: outputs/stacks/concretize-0.out
   :language: console

Let's double-check which specs have been installed so far:

.. literalinclude:: outputs/stacks/concretize-01.out
   :language: console

As we can see, all four variations of ``netlib-scalapack`` have been successfully installed.

^^^^^^^^^^^^^^^^^^^^
Reusable definitions
^^^^^^^^^^^^^^^^^^^^

So far, we've seen how spec matrices can generate cross-product specs from rows containing lists of constraints.  
In large deployments, it's common to include multiple matrices in the spec list—often sharing some of the same rows.

To reduce duplication in the manifest file and lower the maintenance burden, Spack allows you to *define* reusable lists of constraints under the ``definitions`` attribute, and expand them later wherever needed.

Let's rewrite our manifest using this feature:

.. literalinclude:: outputs/stacks/examples/3.spack.stack.yaml
   :language: yaml
   :emphasize-lines: 6-10,14-18

Next, let's verify that re-concretizing the environment results in no changes:

.. literalinclude:: outputs/stacks/concretize-1.out
   :language: console

Now we can use those definitions to add, for example, serial packages built against the LAPACK libraries.  
Let's demonstrate this using ``py-scipy`` as an example.

Another useful feature is the ability to exclude specific entries from a cross-product matrix.  
This can be done using the ``exclude`` keyword within the same item as the ``matrix``.

Let's exclude ``py-scipy ^netlib-lapack`` from the matrix:

.. literalinclude:: outputs/stacks/examples/4bis.spack.stack.yaml
   :language: yaml
   :emphasize-lines: 11,20-25

Let's concretize the environment and install the specs again:

.. literalinclude:: outputs/stacks/concretize-3.out
   :language: console

At this point, the environment should contain only ``py-scipy ^openblas``.  
Let's verify that:

.. literalinclude:: outputs/stacks/concretize-4.out
   :language: console

^^^^^^^^^^^^^^^^^^^^^^^
Conditional definitions
^^^^^^^^^^^^^^^^^^^^^^^

Spec list definitions can also be conditioned using a ``when`` clause.  
The ``when`` clause is a Python conditional that is evaluated in a restricted context.  
The following variables are available for use in ``when`` clauses:

================= ============================================
Variable Name     Value
================= ============================================
``platform``      The Spack platform name for this machine  
``os``            The default Spack OS name and version string  
``target``        The default Spack target string  
``architecture``  The default Spack architecture string (platform-os-target)  
``arch``          Alias for ``architecture``  
``env``           A dictionary representing the user's environment variables  
``re``            The Python ``re`` module for regular expressions  
``hostname``      The hostname of the current node  
================= ============================================

Let's say we want to restrict the MPI provider to just ``mpich``, unless the ``SPACK_STACK_USE_OPENMPI`` environment variable is set.  
To accomplish this, we could write the following ``spack.yaml``:

.. literalinclude:: outputs/stacks/examples/5.spack.stack.yaml
   :language: yaml
   :emphasize-lines: 7-9

Different definitions for the same list name are concatenated.  
This allows you to define the base list unconditionally and then append additional values conditionally using separate ``when`` blocks.

Let's first see what happens when we concretize without setting the environment variable:

.. literalinclude:: outputs/stacks/concretize-5.out
   :language: console

As expected, only ``mpich`` is used as the MPI provider.  
To include ``openmpi``, we simply set the appropriate environment variable:

.. literalinclude:: outputs/stacks/concretize-6.out
   :language: console

There's no need to reinstall in this case, since all the specs are already present in the store.


^^^^^^^^^^^^^^^^^^^^^
Other useful features
^^^^^^^^^^^^^^^^^^^^^

Sometimes it can be helpful to create a local source mirror for the specs installed in an environment.  
If the environment is active, this is as simple as:

.. code-block:: console

   $ spack mirror create --all -d ./stacks-mirror

This command fetches all the tarballs for the packages listed in the ``spack.lock`` file and places them in the specified directory.  
Later, you can move this mirror to an air-gapped machine and run:

.. code-block:: console

   $ spack mirror add <name> <stacks-mirror>

This allows you to rebuild the specs from source.  
If instead you want to create a buildcache, you can do the following:

.. code-block:: console

   $ spack gpg create <name> <e-mail>
   $ spack buildcache push ./mirror

In that case, don't forget to set an appropriate value for the padding of the install tree.  
See the documentation on `how to set up relocation <https://spack.readthedocs.io/en/latest/binary_caches.html#relocation>`_ for details.

By default, Spack installs one package at a time, using the ``-j`` option where possible.  
If you are installing a large environment and have access to a powerful build node, you might want to launch multiple builds in parallel to make better use of available resources.

This can be done by generating a ``depfile`` while the environment is active:

.. code-block:: console

   $ spack env depfile -o Makefile

This generates a Makefile that starts multiple Spack instances, sharing resources via the GNU jobserver.  
More details on this feature can be found in the `Spack documentation <https://spack.readthedocs.io/en/latest/environments.html#generating-depfiles-from-environments>`_.

Using this approach can significantly reduce build time, especially if you frequently build from source.

-----------------------------------
Make the software stack easy to use
-----------------------------------

Now that the software stack has been installed, we need to focus on how it can be used by end users.  
We'll first look at how to configure views to project a subset of installed specs onto a directory structure that resembles a typical Unix filesystem layout.  
Then we'll discuss an alternative approach using module files.  
Which of these methods is more appropriate depends heavily on the specific use case.

^^^^^^^^^^^^^^^^
View descriptors
^^^^^^^^^^^^^^^^

At the beginning of this tutorial, we configured Spack not to create a view for this stack.  
That's because simple views won't work well with software stacks: we've been concretizing multiple packages with the same name, and they would conflict if linked into a single view.

Instead, we can create *multiple views* using view descriptors.  
This allows us to control exactly which packages are included in a view—and how they're laid out.

Let's edit our ``spack.yaml`` file again:

.. literalinclude:: outputs/stacks/examples/6.spack.stack.yaml
   :language: yaml
   :emphasize-lines: 44-54

In the configuration above, we define two views: ``default`` and ``full``.

The ``default`` view includes all packages built with ``gcc@12``, but excludes those that depend on ``mpich`` or ``netlib-lapack``.  
As shown, we can use both *include* and *exclude* spec constraints in our view descriptors.

The ``full`` view uses a more complex projection layout.  
This places each spec in a subdirectory according to the first matching constraint.  
The ``all`` pattern acts as a fallback and always has the lowest priority, regardless of where it appears.  
To avoid confusion, we recommend placing ``all`` last in the projection list.

Let's re-concretize the environment to regenerate the views, and check their structure:

.. literalinclude:: outputs/stacks/view-0.out
   :language: console

View descriptors also support a ``link`` key.  
By default, Spack links all packages—including implicit link and run dependencies—into the view.  
If we set this option to ``roots``, Spack links only the root packages into the view.

.. literalinclude:: outputs/stacks/examples/7.spack.stack.yaml
   :language: yaml
   :emphasize-lines: 49

.. literalinclude:: outputs/stacks/view-1.out
   :language: console

Now, only the root libraries appear in the ``default`` view.  
All other packages are excluded from the view but remain available in the ``full`` view.

You can find the complete documentation on views in the Spack manual `here <https://spack.readthedocs.io/en/latest/environments.html#filesystem-views>`_.

^^^^^^^^^^^^
Module files
^^^^^^^^^^^^

Module files are a widely used mechanism for managing software environments on HPC systems.  
In this section, we'll show how to configure and generate a hierarchical module structure suitable for use with ``lmod``.

A more detailed tutorial focused exclusively on module files is available at :ref:`modules-tutorial`.  
That tutorial covers Spack's module file architecture in depth and compares ``environment-modules`` and ``lmod``—a distinction we won't address here.

Let's start by installing ``lmod`` using the system compiler:

.. code-block:: console

   $ spack add lmod%gcc@11
   $ spack concretize
   $ spack install

Once installed, initialize the ``module`` command in your shell:

.. code-block:: console

   $ . $(spack location -i lmod)/lmod/lmod/init/bash

If everything worked correctly, the ``module`` command should now be available in your shell:

.. literalinclude:: outputs/stacks/modules-1.out
   :language: console

Next, let's add basic configuration to our ``spack.yaml`` file to enable module file generation:

.. literalinclude:: outputs/stacks/examples/8.spack.stack.yaml
   :language: yaml
   :emphasize-lines: 45-54

In these lines, we instruct Spack to generate ``lmod`` module files in a subdirectory named ``modules``, using a hierarchy based on ``lapack`` and ``mpi``.

To generate and use the module files, run:

.. code-block:: console

   $ spack module lmod refresh -y
   $ module use $PWD/stacks/modules/linux-ubuntu22.04-x86_64/Core

You should now see the generated module files:

.. literalinclude:: outputs/stacks/modules-2.out
   :language: console

This basic setup is already functional.  
For example, you can load the ``gcc`` compiler module and confirm that it adjusts your path and exposes additional modules compiled with ``gcc@12.3.0``:

.. literalinclude:: outputs/stacks/modules-3.out
   :language: console

However, there are still some issues:

- Many modules generated from compiler dependencies clutter the view and are not useful to end users.
- Module names include hashes, which makes them harder to reuse across similar environments.
- Some modules may need to set custom environment variables based on site-specific deployment policies—information that isn't encoded in the spec hash.

To address these issues, we can enhance the ``modules`` configuration:

.. literalinclude:: outputs/stacks/examples/9.spack.stack.yaml
   :language: yaml
   :emphasize-lines: 55-70

Let's regenerate the module files with the updated configuration:

.. literalinclude:: outputs/stacks/modules-4.out
   :language: console

Now, the generated module files:

- exclude hashes from names,
- follow a clean and correct hierarchy,
- and include our custom modifications.

.. literalinclude:: outputs/stacks/modules-5.out
   :language: console

This concludes our brief tour of module file generation—and the tutorial on software stacks.

-------
Summary
-------

In this tutorial, we configured Spack to install a stack of software built as a cross-product of different MPI and LAPACK libraries.  
We used spec matrix syntax to compactly define the specs to install, and leveraged spec list definitions to reuse matrix rows in multiple contexts.

Finally, we discussed how to make the installed software accessible to users, using either filesystem views or module files—choosing the best approach depending on your use case.
