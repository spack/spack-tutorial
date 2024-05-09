.. Copyright 2013-2023 Lawrence Livermore National Security, LLC and other
   Spack Project Developers. See the top-level COPYRIGHT file for details.

   SPDX-License-Identifier: (Apache-2.0 OR MIT)

.. include:: common/setup.rst

.. _stacks-tutorial:

===============
Stacks Tutorial
===============

So far, we've talked about Spack environments in the context of a
unified user environment or development environment. But environments
in Spack have much broader capabilities. In this tutorial we will
consider how to use a specialized sort of Spack environment, that we
call a Spack stack, to manage large deployments of software using
Spack.

-------------
Spec matrices
-------------

In a typical Spack environment for a single user, a simple list of
specs is sufficient. For software deployment, however, we often have a
set of packages we want to install across a wide range of MPIs or compilers.
In the following we'll mimic the creation of a software stack using different
libraries for LAPACK and MPI and a compiler for the software which is more
recent than the one provided by the system.

^^^^^^^^^^^^^^^^^^
Setup the compiler
^^^^^^^^^^^^^^^^^^

Let's create a new independent environment and setup the compiler we want to use to build
our stack:

.. literalinclude:: outputs/stacks/setup-0.out
   :language: console

.. literalinclude:: outputs/stacks/examples/0.spack.stack.yaml
   :language: yaml
   :emphasize-lines: 9

For now, we'll avoid the view directive. We'll come back to this later. Let's
concretize and install our compiler:

.. code-block:: console

   $ spack concretize -f
   $ spack install

Finally, let's register it as a new compiler in the environment:

.. literalinclude:: outputs/stacks/compiler-find-0.out
   :language: console

Asking Spack to list the compilers we have available should confirm the
presence of ``gcc@12.3.0``:

.. literalinclude:: outputs/stacks/compiler-list-0.out
   :language: console

The manifest file at this point should look like:

.. literalinclude:: outputs/stacks/examples/1.spack.stack.yaml
   :language: yaml


.. note::

   Setting up a Spack installed compiler for reuse in the same environment is, currently,
   an iterative process. This requires either to install the compiler first - like done here,
   or to use more than one environment. An example of the latter approach can be
   found `at this link <https://github.com/haampie/spack-intermediate-gcc-example/>`_.

^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
Install software against different MPIs and LAPACKs
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Let's now try to install 4 different versions of ``netlib-scalapack``, compiled with ``gcc@12.3.0``
and linked against different LAPACK and MPI providers. The simplest way to express a cross-product
like this in Spack is through a matrix:

.. code-block:: console

   $ spack config edit

.. literalinclude:: outputs/stacks/examples/2.spack.stack.yaml
   :language: yaml
   :emphasize-lines: 9-13,16

Notice that we have to change the concretizer configuration here. By
default, environments co-concretize all specs to be compatible, but
that's simply impossible in an environment with multiple specs for
each package. We set the concretizer unification to ``false`` to allow all
of these builds in one environment:

.. literalinclude:: outputs/stacks/concretize-0.out
   :language: console

The matrix operation does exactly what it looks like it does. It performs
the cross-product of the spec constraints appearing in the lists. This
allows us to deploy software that will satisfy the expectations of HPC users.

.. note::

   Depending on the use case, for software deployment we can set concretizer
   unification either to ``false`` or to ``when_possible``. The latter option
   will cause Spack to allow deviations based on the specific abstract specs
   we requested, but otherwise minimize the proliferation of duplicate specs
   in the environment.

Finally, we can also exclude some values from a matrix:

.. literalinclude:: outputs/stacks/examples/3.spack.stack.yaml
   :language: yaml
   :emphasize-lines: 14-19

Here we constructed a list with both ``py-scipy ^netlib-lapack`` and ``py-scipy ^openblas``,
and excluded the former from the final output. This example might seem a bit silly right now,
where we have a single spec, but it can be really useful to keep configuration file tidy
in presence of multiple root specs or when reusing named lists (as we'll see next).

Let's concretize the environment and install the specs once again:

.. code-block:: console

   $ spack concretize -f
   $ spack install

At this point the environment contains only ``py-scipy ^openblas``. Let's verify it:

.. literalinclude:: outputs/stacks/concretize-1.out
   :language: console

^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
Named lists in spack environments
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Spack also allows for named lists in environments. We can use these
lists to clean up our example above. These named lists are defined in
the ``definitions`` key of the ``spack.yaml`` file. Our lists today
will be simple lists of packages or constraints, but in more
complicated examples the named lists can include matrices as well.
Let's clean up our file a bit now:

.. literalinclude:: outputs/stacks/examples/4.spack.stack.yaml
   :language: yaml
   :emphasize-lines: 6-11

This syntax may take some time getting used to. Specifically, matrices and
references to named lists are always "splatted" into their current
position, rather than included as a list object in yaml. This may seem
counterintuitive, but it becomes important when we look to combine lists.

Notice that the ``mpi`` constraints can be declared as packages and then applied
as dependencies using the ``$^`` syntax. The same is true for compilers (using ``$%``),
so we're showing both syntaxes here.

^^^^^^^^^^^^^^^^^^^^^^^
Conditional definitions
^^^^^^^^^^^^^^^^^^^^^^^

Spec list definitions can also be conditioned on a ``when``
clause. The ``when`` clause is a python conditional that is evaluated
in a restricted environment. The variables available in ``when``
clauses are:

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

Let's say we only want to limit to just use ``mpich``, unless the ``SPACK_STACK_USE_OPENMPI``
environment variable is set. To do so we could write the following ``spack.yaml``:

.. literalinclude:: outputs/stacks/examples/5.spack.stack.yaml
   :language: yaml
   :emphasize-lines: 7-9

Named lists in the Spack stack are concatenated, so we can define our MPI list
in one place unconditionally, and then conditionally append one or more values to it.

Let's first check what happens when we concretize and don't set any environment variable:

.. literalinclude:: outputs/stacks/concretize-2.out
   :language: console

As we expected now we are only using ``mpich`` as an MPI provider. To get ``openmpi`` back
we just need to set the appropriate environment variable:

.. literalinclude:: outputs/stacks/concretize-3.out
   :language: console

----------------
View descriptors
----------------

We told Spack not to create a view for this stack earlier because
simple views won't work with stacks. We've been concretizing multiple
packages of the same name -- they will conflict if linked into the
same view.

To work around this, we will use a view descriptor. This allows us to
define how each package is linked into the view, which packages are
linked into the view, or both. Let's edit our ``spack.yaml`` file again.

.. literalinclude:: outputs/stacks/examples/6.spack.stack.yaml
   :language: yaml
   :emphasize-lines: 28-38

When we'll concretize again we'll see packages linked into the view:

.. literalinclude:: outputs/stacks/view-0.out
   :language: console

The view descriptor also contains a ``link`` key, which is either
"all" or "roots". The default behavior, as we have seen, is to link
all packages, including implicit dependencies, into the view. The
"roots" option links only root packages into the view.

.. literalinclude:: outputs/stacks/examples/7.spack.stack.yaml
   :language: yaml
   :emphasize-lines: 33

.. literalinclude:: outputs/stacks/view-1.out
   :language: console

Now we see only the root libraries in the default view.
The rest are hidden, but are still available in the full view.

------------
Module files
------------

Module files are another very popular way to let your end users profit from
the software you installed. Here we'll  show how you can incorporate the configuration
to generate LMod hierarchical module files within the same environment used to
install the software.

.. note::

   A more in-depth tutorial, focused only on module files, can be found at :ref:`modules-tutorial`.
   There we discuss the general architecture of module file generation in Spack and we highlight
   differences between ``environment-modules`` and ``lmod`` that won't be covered in this section.

Let's start by adding ``lmod`` to the software installed with the system compiler:

.. code-block:: console

   $ spack add lmod%gcc@11
   $ spack concretize
   $ spack install

Once that is done, let's add the ``module`` command to our shell like this:

.. code-block:: console

   $ . $(spack location -i lmod)/lmod/lmod/init/bash

If everything worked out correctly you should now have the module command available in you shell:

.. literalinclude:: outputs/stacks/modules-1.out
   :language: console

The next step is to add some basic configuration to our ``spack.yaml`` to generate module files:

.. literalinclude:: outputs/stacks/examples/8.spack.stack.yaml
   :language: yaml
   :emphasize-lines: 45-54

In these few lines of additional configuration we told Spack to generate ``lmod`` module files
in a subdirectory named ``modules``, using a hierarchy comprising both ``lapack`` and ``mpi``.

We can generate the module files and use them with the following commands:

.. code-block:: console

   $ spack module lmod refresh -y
   $ module use $PWD/modules/linux-ubuntu22.04-x86_64/Core

Now we should be able to see the module files that have been generated:

.. literalinclude:: outputs/stacks/modules-2.out
   :language: console

The sets of modules is already usable, and the hierarchy already works. For instance we can
load the ``gcc`` compiler and check that we have ``gcc`` in out path and we have a lot more
modules available - all the ones compiled with ``gcc@12.3.0``:

.. literalinclude:: outputs/stacks/modules-3.out
   :language: console

There are a few issues though. For once, we have a lot of modules generated from dependencies
of ``gcc`` that are cluttering the view, and won't likely be needed directly by users. Then, module
names contain hashes, which go against users being able to reuse the same script in similar, but
not equal, environments.

Also, some of the modules might need to set custom environment variables, which are specific to
the deployment aspects that don't enter the hash - for instance a policy at the deploying site.

To address all these needs we can complicate out ``modules`` configuration a bit more:

.. literalinclude:: outputs/stacks/examples/9.spack.stack.yaml
   :language: yaml
   :emphasize-lines: 55-70

Let's regenerate the modules once again:

.. literalinclude:: outputs/stacks/modules-4.out
   :language: console

Now we have a set of module files without hashes, with a correct hierarchy, and with all our custom modifications:

.. literalinclude:: outputs/stacks/modules-5.out
   :language: console
