.. Copyright Spack Project Developers. See COPYRIGHT file for details.

   SPDX-License-Identifier: (Apache-2.0 OR MIT)

.. include:: common/setup.rst

.. _packaging-tutorial:

=======================
Reading Package Recipes
=======================

In the previous section we built and installed Quantum ESPRESSO from an environment without opening its package recipe.
The concretizer chose a build system, picked variants, and selected dependencies on our behalf.

This section is about the file that drives those choices: ``package.py``.
Rather than write a recipe from scratch, we will use the existing Quantum ESPRESSO recipe as a worked example.
Over the course of the chapter we concretize ``quantum-espresso`` three times with slightly different constraints, and each time we open ``package.py`` to explain the result.
The recipe also happens to support two different build systems for the same software, and we will see the concretizer switch between them in response to a constraint we add.


-----------------------------
Setting up the environment
-----------------------------

We work in a fresh environment so that the changes made here do not interfere with the rest of the tutorial:

.. code-block:: console

   $ spack env create qe-packaging
   $ spack env activate qe-packaging
   $ spack config edit

Replace the contents with a minimal manifest that points at the pre-populated build cache and pins a compiler:

.. code-block:: yaml

   spack:
     specs:
     - quantum-espresso
     view: view
     concretizer:
       unify: true
     mirrors:
       local:
         url: /buildcache
         signed: false
     packages:
       c:
         prefer: [gcc@15]
       cxx:
         prefer: [gcc@15]
       fortran:
         prefer: [gcc@15]

This is the same shape of manifest used in the environments chapter, restricted to a single spec so that one recipe is in focus.

----------------------------------
First concretization: the defaults
----------------------------------

Asking Spack to concretize the spec as written gives:

.. code-block:: console

   $ spack concretize
   ==> Concretized 1 spec:
    -   zia4bn3  quantum-espresso@7.5~clock~elpa+epw~fox~gipaw~ipo~libxc+mpi~nvtx+openmp
                  +patch~qmcpack+scalapack build_system=cmake build_type=Release
                  generator=make hdf5=none ... %c,cxx,fortran=gcc@15.2.0
   [-]  ri2m772      ^cmake@3.31.11~doc+ncurses+ownlibs~qtgui ...
   [+]  6zwro7e      ^fftw@3.3.11+mpi+openmp~pfft_patches+shared ...
   [+]  k3wh5o7      ^openmpi@5.0.10+atomics~cuda~debug+fortran ...
   [+]  i6kndj2      ^netlib-scalapack@2.2.3~ipo~pic+shared ...
   [+]  tqv4kp2      ^openblas@0.3.33 ... threads=openmp ...
   ...

The output above is trimmed: spec lines are wrapped and most of the dependency tree is omitted.
A few things are worth noting even at this level of detail.
The concretizer chose version ``7.5``, the highest non-development tagged version of Quantum ESPRESSO.
The spec carries an explicit ``build_system=cmake``, indicating that the recipe supports more than one build system and that CMake is the default.
A list of variants appears with their default values, written run-together: ``+mpi``, ``+openmp``, ``+scalapack``, ``+epw``, ``~elpa``, ``~libxc``, and so on.
Dependencies such as ``openmpi``, ``netlib-scalapack``, ``fftw``, and ``openblas`` are pulled in transitively.

Installing the spec is immediate, since every dependency is available in ``/buildcache``:

.. code-block:: console

   $ spack install
   ...
   [+] zia4bn3 quantum-espresso@7.5 /root/spack/opt/spack/.../quantum-espresso-7.5-zia4bn3... (8s)

-----------------------------------------
Inspecting the recipe with ``spack info``
-----------------------------------------

Before opening the recipe in an editor, ``spack info`` shows a digested view of what the recipe declares.
The output below is abbreviated; running the command in the container gives the full version.

.. code-block:: console

   $ spack info quantum-espresso
   CMakePackage:   quantum-espresso

   Description:
       Quantum ESPRESSO is an integrated suite of Open-Source computer codes
       for electronic-structure calculations and materials modeling at the
       nanoscale. ...

   Homepage: https://quantum-espresso.org

   Preferred version:
       7.5        https://gitlab.com/QEF/q-e/-/archive/qe-7.5/q-e-qe-7.5.tar.gz

   Safe versions:
       develop    [git] https://gitlab.com/QEF/q-e.git on branch develop
       7.5        https://gitlab.com/QEF/q-e/-/archive/qe-7.5/q-e-qe-7.5.tar.gz
       7.4.1      https://gitlab.com/QEF/q-e/-/archive/qe-7.4.1/...
       ...

   Variants:
       build_system [cmake]   cmake, generic
           Build systems supported by the package

       mpi [true]             false, true
           Builds with mpi support

       openmp [true]          false, true
           Enables OpenMP support

       scalapack [true]       false, true
         when +mpi
           Enables scalapack support

       elpa [false]           false, true
         when +scalapack
           Uses elpa as an eigenvalue solver

       hdf5 [none]            none, parallel, serial
           Orbital and density data I/O with HDF5
       ...

   Dependencies:
       blas                   build, link
       elpa                   build, link
         when +elpa+openmp build_system=generic
       elpa~openmp            build, link
         when +elpa build_system=cmake
       elpa~openmp            build, link
         when +elpa~openmp build_system=generic
       fftw-api@3             build, link
       mpi                    build, link
         when +mpi
       scalapack              build, link
         when +scalapack
       ...

Several things in this output are worth recognising before we open the file.

Variants are listed with their default in square brackets and the set of allowed values to the right.
Multi-valued variants like ``hdf5`` appear with the same syntax; their allowed values happen to be strings rather than booleans.

Some variants carry a ``when`` clause: ``scalapack`` only exists ``when +mpi``, and ``elpa`` only exists ``when +scalapack``.
A variant scoped this way is not a knob the user can always turn; it only becomes available when its parent variant is enabled.
``build_system`` itself appears as a variant with two allowed values, which is why the concretized spec carries an explicit ``build_system=cmake``.

The Dependencies block is organised similarly.
The ``elpa`` dependency appears three times with different constraints, each guarded by a different ``when`` clause that combines Quantum ESPRESSO's own variants.
This is the structure responsible for the surprising concretization in the next section.

A general point worth keeping in mind while reading any Spack recipe: nearly everything is conditional.
Variants exist only ``when`` some other variant is set; dependencies are pulled in only ``when`` they apply; patches are attached only ``when`` a specific version range and variant combination is selected; and ``build_system`` itself is just another variant the concretizer chooses.
Most of the interesting behaviour of a recipe is encoded in those ``when`` clauses rather than in the unconditional statements at the top of the file.

-------------------------
Opening ``package.py``
-------------------------

The ``spack edit`` command opens a package's recipe in your editor:

.. code-block:: console

   $ spack edit quantum-espresso

This opens ``quantum_espresso/package.py`` from Spack's package repository.
The top of the file maps fairly directly onto the spec line we saw above:

.. code-block:: python

   class QuantumEspresso(CMakePackage, Package):
       """Quantum ESPRESSO is an integrated suite of Open-Source computer codes
       for electronic-structure calculations and materials modeling at the
       nanoscale. ..."""

       homepage = "https://quantum-espresso.org"
       url = "https://gitlab.com/QEF/q-e/-/archive/qe-6.6/q-e-qe-6.6.tar.gz"
       git = "https://gitlab.com/QEF/q-e.git"

       maintainers("ye-luo", "bellenlau", "tgorni")

       build_system(conditional("cmake", when="@6.8:"), "generic", default="cmake")

       license("GPL-2.0-only")

       version("develop", branch="develop")
       version("7.5", sha256="7e1f7a9a21b63192f5135218bee20a5321b66582e4756536681b76e9c59b3cc8")
       version("7.4.1", sha256="6ef9c53dbf0add2a5bf5ad2a372c0bff935ad56c4472baa001003e4f932cab97")
       ...

A Spack recipe is a Python class whose body consists largely of **directives**: function-call-shaped declarations that the concretizer reads.
Three of them are visible in the snippet above.

The ``version(...)`` directive declares an installable version of the upstream software; the recipe carries one such directive for each release listed by ``spack info``.
The concretizer picked ``7.5`` because it is the highest non-development tagged version and nothing in our manifest constrains the choice.
The ``maintainers(...)`` and ``license(...)`` directives are metadata and do not influence the build.

The most important of the three is

.. code-block:: python

   build_system(conditional("cmake", when="@6.8:"), "generic", default="cmake")

which explains the ``build_system=cmake`` we saw on the concretized spec.
Quantum ESPRESSO supports two build systems: a ``./configure``-based one available for every version, and a CMake-based one available from ``@6.8`` onward.
CMake is the default; we will revisit this directive in the third concretization below.

--------------------------------------------
Adding a variant: ``quantum-espresso +elpa``
--------------------------------------------

Quantum ESPRESSO can use `ELPA <https://elpa.mpcdf.mpg.de/>`_ as an eigenvalue solver.
Edit the manifest with ``spack config edit`` and change the spec list to:

.. code-block:: yaml

   specs:
   - quantum-espresso +elpa

Reconcretize:

.. code-block:: console

   $ spack concretize -f
   ==> Concretized 1 spec:
    -   pyrr7wu  quantum-espresso@7.5~clock+elpa+epw~fox~gipaw~ipo~libxc+mpi~nvtx+openmp
                  +patch~qmcpack+scalapack build_system=cmake ...
    -   ffaa5ax      ^elpa@2026.02.001~autotune~cuda+mpi~openmp~rocm build_system=autotools ...
   ...

As expected, ``^elpa`` now appears in the dependency graph.
There is a less obvious detail in the same output:

.. code-block:: text

   quantum-espresso@7.5 ... +openmp ...
       ^elpa@2026.02.001 ... ~openmp ...

Quantum ESPRESSO is being built with OpenMP, but its ELPA dependency is not.
Nothing in the manifest requested ``~openmp`` for ELPA, so this configuration deserves an explanation.
Before tracking it down, install the spec from the build cache:

.. code-block:: console

   $ spack install
   ...
   [+] ffaa5ax elpa@2026.02.001 /root/spack/opt/spack/.../elpa-2026.02.001-ffaa5ax... (1s)
   [+] pyrr7wu quantum-espresso@7.5 /root/spack/opt/spack/.../quantum-espresso-7.5-pyrr7wu... (9s)

------------------------------------------
Locating the constraint in ``package.py``
------------------------------------------

Run ``spack edit quantum-espresso`` again and search the file for ``elpa``.
The relevant block is the following:

.. code-block:: python

   with when("+scalapack"):
       depends_on("scalapack")
       variant("elpa", default=False, description="Uses elpa as an eigenvalue solver")

   with when("+elpa"):
       # CMake builds only support elpa without openmp
       depends_on("elpa~openmp", when="build_system=cmake")
       with when("build_system=generic"):
           depends_on("elpa", when="+openmp")
           depends_on("elpa~openmp", when="~openmp")
       conflicts("@:5.4.0", msg="+elpa requires QE >= 6.0")

Reading the block from the outside in:

The ``variant("elpa", default=False, ...)`` directive declares the ``+elpa`` / ``~elpa`` switch we just used.
It is nested inside ``with when("+scalapack"):``, which is why ``spack info`` reported ``elpa`` only ``when +scalapack``: the variant only exists when Quantum ESPRESSO is built with ScaLAPACK.

The ``with when("+elpa"):`` block scopes several directives to the case in which ELPA is enabled.
Inside that scope, the recipe declares dependencies that are themselves conditioned on other variants of Quantum ESPRESSO:

* ``depends_on("elpa~openmp", when="build_system=cmake")`` requires ELPA to be built without OpenMP whenever Quantum ESPRESSO is built with CMake.
  This is the directive that produced the ``~openmp`` we observed.
* The ``with when("build_system=generic"):`` block states the inverse rule for the autoconf build: there, ELPA's OpenMP setting tracks Quantum ESPRESSO's own.

The ``conflicts(...)`` directive rules out impossible combinations (here, ``+elpa`` with Quantum ESPRESSO @5.4 or earlier).
The condition does not apply to our spec, but the directive is worth recognising.

The reason behind the CMake constraint is given in the comment immediately above the directive: Quantum ESPRESSO's CMake build system does not support an OpenMP build of ELPA.
This is a constraint imposed by upstream, not by Spack.
The recipe encodes it so that the concretizer cannot produce a configuration that would fail to compile.

The concretizer's task is to find a spec consistent with every directive that applies.
Given ``quantum-espresso +elpa`` and the default ``build_system=cmake``, the only value of ``elpa`` the recipe allows is ``~openmp``, which is what we saw in the previous concretization.

--------------------------------------------------
Requesting ``%elpa +openmp`` explicitly
--------------------------------------------------

There are legitimate reasons to want ELPA with OpenMP enabled — for example, performance, or parity with an existing reference build on another machine.
Adding that constraint to the manifest forces the concretizer to find a different solution.
Edit the manifest:

.. code-block:: yaml

   specs:
   - quantum-espresso +elpa %elpa +openmp

.. note::

   The ``%name +variant`` syntax was introduced in Spack 1.0 and applies the constraint to a *direct* dependency.
   In older Spack syntax, ``%elpa +openmp`` here plays the same role as ``^elpa +openmp``.

Reconcretize:

.. code-block:: console

   $ spack concretize -f
   ==> Concretized 1 spec:
    -   nlaupca  quantum-espresso@7.5~clock+elpa~environ+epw~fox~gipaw~libxc+mpi~nvtx+openmp
                  +patch~qmcpack+scalapack build_system=generic hdf5=none ...
    -   nkefiie      ^elpa@2026.02.001~autotune~cuda+mpi+openmp~rocm build_system=autotools ...

The Quantum ESPRESSO spec now carries ``build_system=generic`` rather than the previous ``build_system=cmake``.
The concretizer arrived at that result by following the constraints in the recipe:

1. The user requested ``+elpa`` and ``^elpa +openmp``.
2. The recipe states ``depends_on("elpa~openmp", when="build_system=cmake")``.
3. These two constraints are incompatible, so ``build_system=cmake`` is no longer a valid choice.
4. The ``build_system(...)`` directive offers ``"generic"`` as the only alternative for this version.
5. Switching to ``build_system=generic`` activates the inner ``when("build_system=generic")`` block, which allows ``elpa+openmp`` as long as Quantum ESPRESSO is also ``+openmp`` (which it is, by default).

The dependency graph reflects the switch: there is no longer a ``cmake`` build dependency, since the two build systems pull in different build-time tools.

This spec is also present in the build cache:

.. code-block:: console

   $ spack install
   ...
   [+] nkefiie elpa@2026.02.001 /root/spack/opt/spack/.../elpa-2026.02.001-nkefiie... (0s)
   [+] nlaupca quantum-espresso@7.5 /root/spack/opt/spack/.../quantum-espresso-7.5-nlaupca... (11s)

The constraint that ELPA with OpenMP requires the autoconf build is encoded once, in the recipe, in a form the concretizer can reason about.
Users get a working configuration regardless of how the spec is written, and the constraint does not need to be repeated in every manifest.

---------------------------
Summary of directives
---------------------------

A summary of the directives that appeared in the recipe sections above:

* ``version(name, sha256=..., ...)`` declares a buildable version of the software; a recipe typically carries one such directive per release.
* ``variant("name", default=..., description=...)`` declares a user-tunable option of the build.
  Reading the recipe is the authoritative way to determine which variants exist and what their defaults are.
* ``depends_on("spec", when=...)`` declares a dependency, optionally with a constraint on the dependency and a condition on the consuming package.
* ``with when("..."):`` scopes a block of directives to a condition on the consuming package.
  Quantum ESPRESSO uses this pattern extensively to group related dependency rules.
* ``build_system(...)`` enumerates the build systems a package supports and identifies the default; every spec carries an explicit ``build_system=...``.
* ``requires(...)`` and ``conflicts(...)`` assert combinations that are required or disallowed, typically with an explanatory ``msg=``.

Two further directives are visible in Quantum ESPRESSO's recipe but were not exercised here.
Both will be used in the developer workflow session on Day 2:

* ``patch(url_or_path, sha256=..., when=...)`` attaches a patch to a version range or variant combination.
  Quantum ESPRESSO's recipe already contains several, including ``patch(... when="@=7.3+elpa build_system=cmake")``, which backports a fix relevant to the build system discussed above.
* ``dev_path=`` is a per-spec setting (not a directive in the recipe) that points the build at a local source tree instead of the upstream tarball.
  It is the basis of Spack's developer workflow.

---------------------------------------------
Continuation on Day 2: developer workflow
---------------------------------------------

In this section we treated the Quantum ESPRESSO recipe as a read-only artifact and traced the reasoning behind each concretization.
The Day 2 session on developer workflow covers modifying the same recipe to test a fix against upstream Quantum ESPRESSO, in two ways:

1. Pointing Quantum ESPRESSO at a local clone with ``spack install quantum-espresso dev_path=/path/to/q-e``, so that iteration on the source tree feeds directly into Spack's build.
2. Adding a ``patch("https://gitlab.com/QEF/q-e/-/merge_requests/<N>.diff", sha256=...)`` line to the recipe, so that anyone consuming the recipe picks up the in-progress merge request without needing a local checkout.

The directives involved are the same as those discussed here, but tomorrow we write them instead of reading them.

-------------
Cleaning up
-------------

Deactivate and remove the environment:

.. code-block:: console

   $ spack env deactivate
   $ spack env rm -y qe-packaging

----------------
More information
----------------

* `Packaging guide — creation <https://spack.readthedocs.io/en/latest/packaging_guide_creation.html>`_: directives, versions, variants, dependencies.
* `Packaging guide — build customization <https://spack.readthedocs.io/en/latest/packaging_guide_build.html>`_: how install phases work for each build system.
* `Build Systems <https://spack.readthedocs.io/en/latest/build_systems.html>`_: the full list of supported build systems, including the ``CMakePackage`` and (generic) ``Package`` base classes QE inherits from.
* `Multiple Build Systems <https://spack.readthedocs.io/en/latest/packaging_guide_advanced.html#multiple-build-systems>`_: reference for the ``build_system(...)`` directive we saw in action.
* `spack pkg grep <https://spack.readthedocs.io/en/latest/command_index.html#spack-pkg>`_: search across all built-in recipes for a directive or pattern — invaluable when looking for examples.
