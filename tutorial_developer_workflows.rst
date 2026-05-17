.. Copyright Spack Project Developers. See COPYRIGHT file for details.

   SPDX-License-Identifier: (Apache-2.0 OR MIT)

.. include:: common/setup.rst

.. _developer-workflows-tutorial:

===================
Developer Workflows
===================

In the packaging chapter, ``quantum-espresso/package.py`` was opened but never
modified: the concretizer's choices were traced through three builds by reading
the recipe, not changing it.

This chapter follows the same recipe through a real upstream fix.  
The developer workflow uses ``spack develop`` to point Spack at a local clone, investigates a build failure, and authors a patch.  
Once that patch is submitted as a merge request, it can be encoded as a ``patch()`` directive in the recipe.
In this way  non-developers get the fix automatically when they install, without maintaining a clone.

The ``dev_path=`` attribute set by ``spack develop`` and the ``patch()`` directive share the same conditional machinery introduced on Day 1.
Both accept a ``when=`` clause that scopes their effect to specific versions or variants.

------------------------------------
The CMake / ELPA / OpenMP constraint
------------------------------------

On Day 1, requesting ``quantum-espresso +elpa %elpa +openmp`` caused the concretizer to switch from ``build_system=cmake`` to ``build_system=generic``.
The driving directive in the recipe is:

.. code-block:: python

   with when("+elpa"):
       # CMake builds only support elpa without openmp
       depends_on("elpa~openmp", when="build_system=cmake")
       with when("build_system=generic"):
           depends_on("elpa", when="+openmp")
           depends_on("elpa~openmp", when="~openmp")

The comment asserts that the CMake build does not support an OpenMP build of ELPA, but gives no reason.  
This chapter investigates whether the limitation is intrinsic or merely unimplemented, and fixes it if the latter.

--------------------------
Setting up the environment
--------------------------

Create a fresh environment for this session:

.. code-block:: console

   $ spack env activate --create qe-dev
   $ spack config edit

Replace the contents of ``spack.yaml`` with the following manifest:

.. code-block:: yaml

   spack:
     specs:
     - quantum-espresso +elpa %elpa +openmp
     view: view
     concretizer:
       unify: true
     packages:
       c:
         prefer: [gcc@15]
       cxx:
         prefer: [gcc@15]
       fortran:
         prefer: [gcc@15]

Concretize to confirm the starting point:

.. literalinclude:: outputs/dev/setup.out
   :language: console

The first line of the concretized spec shows ``build_system=generic``.
The:

.. code-block:: python

   depends_on("elpa~openmp", when="build_system=cmake")
   
constraint in the recipe prevents the concretizer from selecting ``build_system=cmake`` when ELPA is built with OpenMP.

---------------------------
Building from a local clone
---------------------------

Investigating the build failure requires a modifiable source tree: diagnosing a CMake configuration problem often involves editing the source, rebuilding, and inspecting the result in a tight loop.
Spack's developer workflow supports this through ``spack develop``, which directs the concretizer to build from a local directory instead of a downloaded tarball, and makes subsequent builds incremental — only files changed since the last ``spack install`` are recompiled.

Three steps prepare the workspace: 

1. Cloning the upstream source to have a git working tree, 
2. Registering that clone with Spack, and 
3. Relaxing the recipe constraint so the concretizer can select ``build_system=cmake`` together with ``+elpa`` and ``%elpa +openmp``.

^^^^^^^^^^^^^^^^^^^
Cloning the sources
^^^^^^^^^^^^^^^^^^^

Move to the home directory:

.. code-block:: console

   $ cd ~

and clone Quantum ESPRESSO at the ``qe-7.5`` tag:

.. literalinclude:: outputs/dev/clone.out
   :language: console

Two aspects of this invocation are worth noting:

.. list-table::
   :widths: 30 70
   :header-rows: 1

   * - Option
     - Effect
   * - ``--depth 2``
     - Fetches a shallow history (tag commit and one parent), keeping the download small while giving ``git apply`` enough context to work.
   * - ``-c advice.detachedHead=false``
     - Suppresses the detached HEAD notice that git prints when checking out a tag rather than a branch.

``git switch -c qe-7.5-dev`` immediately creates a named branch at that commit, so edits and commits land on a branch that can be pushed as a merge request.

^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
Register the clone with Spack
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Register the clone as the build tree for ``quantum-espresso@7.5``:

.. literalinclude:: outputs/dev/develop.out
   :language: console

``--path`` tells Spack where to find the source.  
Because the path already exists, Spack skips the download and records a ``dev_path=`` attribute in the ``develop:`` section of ``spack.yaml``, marking the spec for incremental builds from that source:

.. code-block:: yaml

   develop:
     quantum-espresso:
       spec: quantum-espresso@7.5 +elpa %elpa+openmp
       path: ~/q-e

Without ``--path``, ``spack develop quantum-espresso@7.5`` clones the source into the environment directory automatically.
This is convenient when the goal is to iterate on the recipe's build logic rather than contribute to upstream.

^^^^^^^^^^^^^^^^^^^^^^^^^^^
Relax the recipe constraint
^^^^^^^^^^^^^^^^^^^^^^^^^^^

Edit the recipe to remove the constraint that blocks the combination under investigation:

.. literalinclude:: outputs/dev/relax.out
   :language: console

The final result reads:

.. code-block:: python

   with when("+elpa"):
       # CMake builds only support elpa without openmp
       depends_on("elpa", when="+openmp")
       depends_on("elpa~openmp", when="~openmp")

We removed:

1. The ``depends_on("elpa~openmp", when="build_system=cmake")`` line 
2. The ``with when("build_system=generic"):`` block that scoped the remaining two lines to ``build_system=generic``

The concretizer is now free to pair ``build_system=cmake`` with ``elpa+openmp``.
Concretize the relaxed environment:

.. literalinclude:: outputs/dev/build-fail-concretize.out
   :language: console
   :lines: 1-5

After the constraint is removed, the concretizer selects ``build_system=cmake`` and ``elpa+openmp`` as the dependency.

------------------
Diagnosing the bug
------------------

Now install to see if the build fails:

.. literalinclude:: outputs/dev/build-fail-install.out
   :language: console

The build then fails inside CMake's ``FindELPA`` module.
The log excerpt printed by Spack names all four missing components (``ELPA_LIBRARIES``, ``ELPA_INCLUDE_DIRS``, ``ELPA_Fortran_MODS_DIR``, and ``ELPA_VERSION``) indicating the finder returned empty-handed rather than partially failing.

The full CMake output is in the build log, whose path is printed at the end of the install output.
Alternatively, the stage directory can be located with:

.. code-block:: console

   $ spack location --stage quantum-espresso

Reading ``cmake/FindELPA.cmake`` in the stage directory reveals the cause.
The finder searches unconditionally for a library named ``elpa`` and headers under ``include/elpa-*``.

Inspecting the ELPA installation prefix:

.. code-block:: console

   $ spack location -i elpa

shows that an OpenMP build of ELPA installs as ``libelpa_openmp``, with headers under ``include/elpa_openmp-*``.
*The two names never match, so all four finder variables remain unset*.

If interactive diagnosis was needed:

.. code-block:: console
   
   $ spack build-env quantum-espresso -- bash

opens a shell with all of QE's build-time environment variables set, making it straightforward to re-run CMake manually or inspect the ELPA prefix directly.


-----------------------------
Fixing the FindELPA module
-----------------------------

The fix is to detect which ELPA variant is installed and substitute the appropriate library name and header prefix throughout the finder.  
Edit ``q-e/cmake/FindELPA.cmake``:

.. literalinclude:: outputs/dev/fix.out
   :language: console

The patch introduces ``_ELPA_LIB_NAME`` (``elpa`` or ``elpa_openmp``) and ``_ELPA_INCLUDE_PREFIX``, selected by testing the ``QE_ENABLE_OPENMP`` CMake variable.
It then replaces every hardcoded occurrence of ``elpa`` in path suffixes, library searches, and version extraction with these variables:

.. code-block:: diff

   diff --git a/cmake/FindELPA.cmake b/cmake/FindELPA.cmake
   --- a/cmake/FindELPA.cmake
   +++ b/cmake/FindELPA.cmake
   @@ -67,6 +67,21 @@ else()
        set(CMAKE_FIND_LIBRARY_SUFFIXES ${CMAKE_FIND_LIBRARY_SUFFIXES_SAV})
    endif()

   +# ELPA built with --enable-openmp installs as libelpa_openmp, with headers
   +# under include/elpa_openmp-YYYY.MM.NNN and a pkg-config file named
   +# elpa_openmp.pc. The two flavors can be installed side-by-side, so when QE
   +# itself is configured with OpenMP we must look for the _openmp variant.
   +if(NOT DEFINED ELPA_OPENMP)
   +    set(ELPA_OPENMP ${QE_ENABLE_OPENMP})
   +endif()
   +if(ELPA_OPENMP)
   +    set(_ELPA_LIB_NAME elpa_openmp)
   +    set(_ELPA_INCLUDE_PREFIX elpa_openmp)
   +else()
   +    set(_ELPA_LIB_NAME elpa)
   +    set(_ELPA_INCLUDE_PREFIX elpa)
   +endif()
   +
    # ELPA depends on SCALAPACK anyway, try to find it
    if(NOT SCALAPACK_FOUND)
        if(ELPA_FIND_REQUIRED)
   @@ -96,7 +111,7 @@ macro(glob_elpa_header_file)
        foreach(DIR ${ARGN_EXPANDED})
            message(DEBUG "globing ${DIR}")
            if(NOT ELPA_elpa.h_FILEPATH AND DIR)
   -            file(GLOB ELPA_elpa.h_FILEPATH "${DIR}/include/elpa-20*/elpa/elpa.h")
   +            file(GLOB ELPA_elpa.h_FILEPATH "${DIR}/include/${_ELPA_INCLUDE_PREFIX}-20*/elpa/elpa.h")
            endif()
        endforeach()
    endmacro()
   @@ -122,10 +137,10 @@ if(NOT ELPA_INCLUDE_DIRS)
        find_package(PkgConfig QUIET)
        if(PKG_CONFIG_FOUND)
            if(NOT PKG_ELPA_FOUND AND ELPA_PKGCONFIG_VERSION)
   -            pkg_search_module(PKG_ELPA elpa-${ELPA_PKGCONFIG_VERSION})
   +            pkg_search_module(PKG_ELPA ${_ELPA_LIB_NAME}-${ELPA_PKGCONFIG_VERSION})
            endif()
            if(NOT PKG_ELPA_FOUND)
   -            pkg_search_module(PKG_ELPA elpa)
   +            pkg_search_module(PKG_ELPA ${_ELPA_LIB_NAME})
            endif()
   @@ -145,7 +160,7 @@ find_path(
        ELPA_INCLUDE_DIRS
        NAMES "elpa/elpa.h"
        HINTS ${PKG_ELPA_INCLUDE_DIRS}
   -    PATH_SUFFIXES "include" "include/elpa")
   +    PATH_SUFFIXES "include" "include/${_ELPA_INCLUDE_PREFIX}")

   @@ -165,13 +180,13 @@ endif()

    find_library(
        ELPA_LIBRARIES
   -    NAMES elpa
   +    NAMES ${_ELPA_LIB_NAME}
        HINTS ${PKG_ELPA_LIBRARY_DIRS}
        PATH_SUFFIXES "lib" "lib64")

    # extract version string from ELPA_INCLUDE_DIRS
    if(ELPA_INCLUDE_DIRS)
   -    string(REGEX MATCH "elpa-20[0-9][0-9]\.[0-9][0-9]\.[0-9][0-9][0-9]" CMAKE_MATCH_ELPA_VER "${ELPA_INCLUDE_DIRS}")
   +    string(REGEX MATCH "${_ELPA_INCLUDE_PREFIX}-20[0-9][0-9]\.[0-9][0-9]\.[0-9][0-9][0-9]" CMAKE_MATCH_ELPA_VER "${ELPA_INCLUDE_DIRS}")

With the finder corrected, reconfigure Quantum ESPRESSO from the local source tree.

.. literalinclude:: outputs/dev/build-ok.out
   :language: console

``--until cmake`` stops the build after the configure phase so the output is not overwhelmed by compilation messages.
The key lines confirm that the patched finder now locates the correct library and header tree: ``Found ELPA: .../libelpa_openmp.so``.

-------------------------------------------------
Encoding the fix: the ``patch()`` directive
-------------------------------------------------

The fix is self-contained and applies cleanly to the upstream ``@7.5`` tarball.
Encoding it in the recipe means that any user concretizing ``quantum-espresso +elpa build_system=cmake`` picks it up automatically, without maintaining a local clone.

Once the fix has been pushed or submitted as a pull request upstream, it can be referenced it in the recipe.
Compute the patch's sha256 hash:

.. code-block:: console

   $ curl -sL https://gitlab.com/haampie/q-e/-/commit/517a7bba47628af8f93f985765d7ab7d23077c4c.diff \
         | sha256sum
   e297b3b391dfd5ec3b9f41ef882be77571c32266891322a126ebe1f22d75083a  -

Then edit the recipe to add the ``patch()`` directive:

.. code-block:: python

   patch(
       "https://gitlab.com/haampie/q-e/-/commit/"
       "517a7bba47628af8f93f985765d7ab7d23077c4c.diff",
       sha256="e297b3b391dfd5ec3b9f41ef882be77571c32266891322a126ebe1f22d75083a",
       when="+elpa build_system=cmake",
   )

The ``when=`` clause on ``patch()`` uses the same conditional machinery seen throughout Day 1.
The patch is applied only when the concretized spec satisfies ``+elpa build_system=cmake``.  

Concretize and verify that the recipe encodes the fix correctly:

.. literalinclude:: outputs/dev/reinstall-concretize.out
   :language: console
   :lines: 1-5

The concretized spec carries ``patches:=e297b3b``, the sha256 prefix of the new directive.

When you install:

.. literalinclude:: outputs/dev/reinstall-install.out
   :language: console

Spack fetches and unpacks the ``@7.5`` release, applies the patch, and the CMake configure step finds ``libelpa_openmp.so`` without a local clone.

---------------------------
Comparing the two workflows
---------------------------

The two approaches serve different stages of the development cycle.

``spack develop --path`` is appropriate while a change is in flight.
Spack reuses compiled objects across ``spack install`` invocations, so builds are incremental, and the source directory is a full git working tree that can be pushed to a fork and turned into a merge request.

``patch()`` is appropriate once a change has been submitted upstream.
It encodes the fix in the recipe alongside the ``when=`` conditions that scope its application, and any user of the recipe picks up the fix automatically.

The source tree managed by ``dev_path=`` is the user's responsibility. 
Spack provides the initial clone but makes no further guarantees.  
Calling ``spack undevelop`` and reinstalling returns the spec to a reproducible, tarball-based build.

------------------------------------
Developing multiple packages at once
------------------------------------

The scenario in this chapter required modifying only one package: QE's ``FindELPA.cmake`` finder.
Had the fix required changing the ELPA library itself (for example, correcting the pkg-config file it installs) the same ``spack develop`` mechanism applies to dependencies.

Multiple ``develop:`` entries in ``spack.yaml`` are supported.
Adding a second entry for ELPA alongside the existing one for QE registers both packages for incremental builds from local source trees.
Spack respects the dependency graph: a rebuild of ELPA triggers recompilation of any package that depends on it, including QE, without requiring a full reinstall of the rest of the graph.

This is most useful when a bug spans a package boundary --- an interface change in a library that requires a coordinated fix in the consumer.
The iteration loop is the same as for a single package: edit source, run ``spack install``, inspect the result.
Only the packages registered under ``develop:`` are built from source.
All other dependencies continue to install from the binary cache.

-----------
Cleaning up
-----------

Deactivate and remove the environment:

.. literalinclude:: outputs/dev/wrapup.out
   :language: console

----------------
More information
----------------

* `Developer workflow
  <https://spack.readthedocs.io/en/latest/developer_guide.html>`_:
  ``spack develop`` reference, including ``--path``, ``--force``, and the
  ``develop:`` section in ``spack.yaml``.
* `Packaging guide — patches
  <https://spack.readthedocs.io/en/latest/packaging_guide.html#patching>`_:
  ``patch()`` directive arguments, URL patches, and archive patches.
* `Multiple Build Systems
  <https://spack.readthedocs.io/en/latest/packaging_guide_advanced.html#multiple-build-systems>`_:
  ``build_system(...)`` directive reference.
