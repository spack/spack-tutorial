.. Copyright 2013-2020 Lawrence Livermore National Security, LLC and other
   Spack Project Developers. See the top-level COPYRIGHT file for details.

   SPDX-License-Identifier: (Apache-2.0 OR MIT)

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
set of packages we want to install across a wide range of
compilers. The simplest way to express this in Spack is through a
matrix. Let's edit our ``spack.yaml`` file again.

.. literalinclude:: outputs/stacks/examples/0.spack.yaml.example
   :language: yaml
   :emphasize-lines: 8-10,12

For now, we'll avoid the view directive. We'll come back to this
later.

This would lead to a lot of install time, so for the sake of time
we'll just concretize and look at the concrete specs for the rest of
this section.

.. literalinclude:: outputs/stacks/concretize-0.out
   :language: console

The matrix operation does exactly what it looks like it does. It takes
the spec constraints in any number of lists and takes their inner
product. Here, we get ``boost``, ``trilinos``, and ``openmpi``, each
compiled with both ``gcc`` and ``clang``. Note that the compiler
constraints are prefaced with the ``%`` sigil, as they would be on the
command line.

There are a couple special things to note about how constraints are
resolved for matrices. Dependencies and variants can be used in a
matrix regardless of whether they apply to every package in the
matrix. Let's edit our file again.

.. literalinclude:: outputs/stacks/examples/1.spack.yaml.example
   :language: yaml
   :emphasize-lines: 10

What we will see here is that Spack applies the mpi constraints to
boost and trilinos, which depend on mpi, and not to openmpi, which
does not.

.. literalinclude:: outputs/stacks/concretize-1.out
   :language: console

This allows us to construct our matrices in a more general manner.

We can also exclude some values from a matrix.

.. literalinclude:: outputs/stacks/examples/2.spack.yaml.example
   :language: yaml
   :emphasize-lines: 12,13

This will exclude all specs built with clang that depend on
mvapich2. We will now see 3 configurations of ``trilinos``.

.. literalinclude:: outputs/stacks/concretize-2.out
   :language: console

---------------------------------
Named lists in spack environments
---------------------------------

Spack also allows for named lists in environments. We can use these
lists to clean up our example above. These named lists are defined in
the ``definitions`` key of the ``spack.yaml`` file. Our lists today
will be simple lists of packages or constraints, but in more
complicated examples the named lists can include matrices as well.

Let's clean up our file a bit now.

.. literalinclude:: outputs/stacks/examples/3.spack.yaml.example
   :language: yaml

This syntax may take some getting used to. Specifically, matrices and
references to named lists are always "splatted" into their current
position, rather than included as a list object in yaml. This may seem
counterintuitive, but it becomes important when we look to combine
lists. Notice that the ``mpi`` constraints can be declared as packages
and then applied as dependencies using the ``$^`` syntax. The same is true
for compilers (using ``$%``), so we're showing both syntaxes here.

.. literalinclude:: outputs/stacks/examples/3.1.spack.yaml.example
   :language: yaml

Our ``specs`` list in this example is still a list of specs, as the
environment requires.

This stack is the same as our previous example, with the additions of
single configurations of python and tcl.

.. literalinclude: outputs/stacks/concretize-3.out
   :language: console

-----------------------
Conditional definitions
-----------------------

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

Let's say we only want to use clang if the ``SPACK_STACK_USE_CLANG``
environment variable is set and edit our ``spack.yaml`` file
accordingly.

.. literalinclude:: outputs/stacks/examples/4.spack.yaml.example
   :language: yaml
   :emphasize-lines: 10-12

Note that named lists in the Spack stack are concatenated. We can
define our compilers list in one place unconditionally, and then
conditionally append clang to it when our environment variable is set
properly.

.. literalinclude:: outputs/stacks/concretize-4.out
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
linked into the view, or both.

Let's edit our ``spack.yaml`` file one last time.

.. literalinclude:: outputs/stacks/examples/5.spack.yaml.example
   :language: yaml
   :emphasize-lines: 24-33

We won't see the views fully filled-in since we don't have time to
install everything in the stack during the tutorial, but the packages
that already happen to be installed will be linked into the views.

.. literalinclude:: outputs/stacks/view-0.out
   :language: console

The view descriptor also contains a ``link`` key, which is either
"all" or "roots". The default behavior, as we have seen, is to link
all packages, including implicit dependencies, into the view. The
"roots" option links only root packages into the view.

.. literalinclude:: outputs/stacks/examples/6.spack.yaml.example
   :language: yaml
   :emphasize-lines: 28-29

.. literalinclude:: outputs/stacks/view-1.out
   :language: console

Now we see only the root libraries in the default view: boost,
trilinos, and openmpi. The rest are hidden, but are still available in
the full view.
