.. Copyright Spack Project Developers. See COPYRIGHT file for details.

   SPDX-License-Identifier: (Apache-2.0 OR MIT)

.. include:: common/setup.rst

.. _reproducible-builds-tutorial:

======================================
Best Practices for Reproducible Builds
======================================

Spack identifies every installation by a hash of *all its inputs*: the package recipe, the concrete spec (version, variants, compiler, target), and the hashes of every dependency, recursively.
The hope behind this design is that a ``spack.yaml`` and its accompanying ``spack.lock`` are enough to reproduce a build bit-for-bit, on a different machine, at a different time.

Bit-for-bit reproducibility of native code is often assumed to be infeasible in practice, but Debian, for example, now only ships binaries that have been independently rebuilt and verified to be identical on different machines and at different times.
Independent reproduction is a strong defense against supply chain attacks, since a backdoored compiler or a tampered build host shows up immediately as a divergence from the reference build.
For scientific computing the motivation is closely related: a published result that depends on a specific software stack can only be trusted and re-examined later if that stack can be rebuilt exactly, by a different group, on a different machine, possibly years after the original run.
Reproducible builds turn "the same software" from a claim about labels and version numbers into a verifiable property of the bytes that actually executed.

Spack aims for the same property, but there are obvious obstacles.
We rely on externals like ``glibc`` and the host's kernel headers.
The build environment is impure: the compiler will happily pick up headers and libraries from ``/usr`` if it finds them, and small changes to the host system can leak into the binary.
Spack also runs on top of whatever environment the user happens to be in: loaded modules, ``LD_LIBRARY_PATH``, locale, ``umask``, and so on.

Closing this gap requires work on two sides: in Spack itself, and in the packages it builds.
The rest of this chapter is about the latter, with concrete examples drawn from the build systems of five widely deployed electronic-structure codes from the MaX Centre: Quantum ESPRESSO, SIESTA, FLEUR, BigDFT, and Yambo.

--------------------------------------
What Spack itself is doing
--------------------------------------

Several pieces of the Spack-side problem are already addressed or in active work.
The compiler wrappers normalize compiler invocations and strip non-deterministic temporary file names and host paths out of debug info.
Every fetched archive is validated against a ``sha256`` checksum recorded in the recipe, so the source side of the build is already pinned.
Spack v1.2 adds opt-in filesystem and network sandboxing via Linux Landlock; the sandbox is still maturing, but in the cases where it works it turns implicit reads from ``/usr`` and network fetches into hard errors.

What Spack does *not* yet do is fully reset the environment for the build.
Today, Spack unsets a curated list of variables known to cause trouble, such as ``LD_LIBRARY_PATH``, ``CPATH``, ``CMAKE_PREFIX_PATH``, ``PYTHONPATH``, ``CFLAGS`` and friends, but anything else the user happens to have exported survives into the build.
Moving to the opposite policy, where only an allowed set of variables is passed through and everything else is cleared, is on the Spack roadmap; until that lands, the user's shell remains a possible source of build-to-build variation.

A second cluster of issues is mostly the build environment's responsibility rather than the package author's: embedded ``__DATE__`` and ``__TIME__`` macros, archive timestamps inside ``.a`` and tarballs, ``PYTHONHASHSEED``-sensitive ``.pyc`` output, and globs of build inputs that are read in filesystem order.
The remediation for these is well understood: ``SOURCE_DATE_EPOCH`` for embedded timestamps, deterministic archivers such as ``ar D`` and ``tar --mtime=...``, ``strip-nondeterminism`` over generated archives, and ``LC_ALL=C sort`` wherever filesystem ordering enters a generated file.
These can be plumbed by the packager or the build wrapper without changes to the upstream project, so they are not the focus of this chapter.
The remaining sources of non-determinism that *do* require upstream changes live in the build systems themselves, and that is what the rest of this chapter is about.

-----------------------------------------------------
Common reproducibility traps in package build systems
-----------------------------------------------------

The recurring theme on the package side is that anything which depends on the specific CPU, kernel, hostname, user, or wall-clock of the build host will make the resulting binary non-reproducible, and usually non-portable as well.
The patterns below are common across scientific HPC codes; they reflect priorities that were entirely reasonable when the build systems were first written, before reproducible builds became a separate concern from "builds at all on my cluster".
The MaX-Centre electronic-structure codes are used as concrete examples throughout because they are mature, widely deployed projects with well-engineered builds, which makes them a fair sample of what real codebases look like rather than cautionary tales.

Unconditional writes to ``CFLAGS`` / ``CXXFLAGS`` / ``FFLAGS``
---------------------------------------------------------------

A project that hardcodes flags like ``-march=native``, ``-mtune=native``, or ``-xHost`` into its own ``CFLAGS`` / ``CXXFLAGS`` / ``FFLAGS`` (or their CMake equivalents) forces every build to target the build host's CPU.
The problem is not the flags themselves: a per-machine preset script that a user opts into by sourcing it, or a CMake toolchain file selected explicitly on the command line, is a perfectly reasonable way to ship cluster-specific tuning.
The problem is when the same flags are written *unconditionally* from inside the build, because they conflict with the microarchitecture already encoded in the Spack spec (``target=x86_64_v3``, ``target=zen3``, and so on), and the only way for the packager to undo them is to ship a patch.

This pattern appears in both CMake-based and autotools-based builds.
As one illustration, FLEUR's ``cmake/compilerflags.cmake`` appends ``-O3 -march=core-avx2 -mtune=core-avx2`` to ``CMAKE_Fortran_FLAGS_RELEASE`` in the GNU branch and ``-Ofast -mtune=native`` in the Intel branch; these run on every build, regardless of which target was requested.
On the autotools side, Yambo's ``configure`` script writes ``SYSFLAGS="-O3 -g -mtune=native -fno-lto"`` and ``FUFLAGS="-O0 -mtune=native"`` into the generated build configuration for every supported compiler branch, and adds ``CPU_FLAG="-xHost"`` on the Intel branch, all as defaults.

The fix is to leave the project's flag variables alone and let the build environment supply the architecture: Spack already exposes the concrete target in the spec hash, so as long as the build honors what the wrapper passes in, the binary is reproducible across hosts of the same family.
Per-machine presets that the user explicitly selects are orthogonal to this and remain a useful pattern.

Running ``git`` at build time
-----------------------------

A common convention is to embed a version string derived from ``git describe`` into the binary so that bug reports identify the exact commit.
Two reproducibility concerns follow from this: the embedded string depends on the state of the working tree at the moment of build, and the build acquires an implicit dependency on a working ``git`` even when the sources come from a release tarball.

Quantum ESPRESSO illustrates both at once.
Its autoconf ``configure`` aborts with the error message ``git needed`` whenever the ``$git`` shell variable is empty, and invokes ``git rev-parse --abbrev-ref HEAD`` and ``git describe --always --dirty --abbrev=40`` to embed the results into the build.
The CMake build similarly declares ``find_package(Git REQUIRED)`` at the top of ``CMakeLists.txt``, and ``cmake/qeHelpers.cmake`` can fetch missing submodules over the network during configure when no submodule-hash record file is present.
SIESTA follows a related pattern in ``Tools/version_generate.sh``: it checks whether the source tree is a git checkout, runs ``git describe --always …`` if so, and uses ``git update-index -q --refresh`` to test whether the working tree is dirty, falling back to a separate ``SIESTA.release`` file for tarball builds.

An incident from Spack's own CI illustrates the kind of failure these probes invite.
A release tarball was extracted into a build directory that happened to be nested inside the Spack source tree.
The package's build called ``git describe``, ``git`` walked up the directory tree looking for a ``.git`` directory, found the one belonging to Spack itself, and the package was duly built with Spack's version tag embedded as its own.
Nothing about this was caught by the build, and nothing in the recipe was obviously wrong; the only fix was to make the build either not run ``git`` at all, or run it under conditions where the answer was guaranteed to come from the right repository.

The upstream fix is to write the version string into the release tarball at packaging time and to fall back to that file when ``.git`` is absent.
The fix on the Spack side, when that is not possible, is to either patch the version script or declare an explicit ``depends_on("git", type="build")`` so the dependency shows up in the spec hash.

Fetching dependencies during configure
--------------------------------------

A build that talks to the network during ``configure`` or ``cmake`` is by definition not reproducible: the upstream server can change, go away, or serve a tampered artifact, and none of that is captured by the recipe.

Two illustrations: Quantum ESPRESSO's ``cmake/qeHelpers.cmake`` runs ``git fetch --depth 1 origin <hash>`` to populate submodules such as ``external/lapack`` when the submodule directory is missing, and SIESTA's ``External/Lua-Engine/CMakeLists.txt`` uses CMake ``FetchContent_Declare`` and ``ExternalProject_Add`` to pull in ``flook`` and a Wannier90 wrapper from the network at configure time.
In both cases the upstream intent is convenience for developers building from a fresh checkout, not a deliberate choice for packaged builds.

From a packaging point of view these fetches are redundant: the dependency is already pinned in the Spack spec graph, and the recipe knows how to install it.
The upstream-friendly fix is to wrap the fetch in an ``if(NOT <DEP>_FOUND)`` guard so that the packager can point the build at an external install via ``-D<DEP>_ROOT=...`` and skip the network step.

Features that turn on whenever a dependency is found
----------------------------------------------------

The patterns under this heading vary in severity.
A CMake fragment of the form

.. code-block:: cmake

   find_package(LibFoo)
   option(MYPROJECT_WITH_FOO "Enable foo support" ${LibFoo_FOUND})

is acceptable: the default is host-dependent, but the recipe can override it with ``-DMYPROJECT_WITH_FOO=OFF`` on the command line, so the packager retains control.

The pattern that causes real trouble is when no user-facing toggle exists at all and the build is wired up iff the probe succeeds:

.. code-block:: cmake

   find_package(LibFoo)
   if(TARGET LibFoo::libfoo)
     target_link_libraries(myapp PRIVATE LibFoo::libfoo)
   endif()

Two builds of the same recipe on two hosts now produce different binaries, with no diagnostic and no way to disable the feature without removing ``libfoo`` from the environment.
The recommended inversion is to gate the ``find_package`` call on the toggle instead of the other way around:

.. code-block:: cmake

   if(MYPROJECT_WITH_FOO)
     find_package(LibFoo REQUIRED)
     target_link_libraries(myapp PRIVATE LibFoo::libfoo)
   endif()

With this shape, the dependency search only happens when the user has asked for the feature, and the build fails fast if the user asked for it and the dependency is missing.

A concrete no-toggle example lives in FLEUR's ``cmake/tests/test_XML.cmake``: the build first does a ``try_compile`` against a small XML test program with whatever happens to already be in ``FLEUR_LIBRARIES``, and only when that fails does it call ``find_package(LibXml2)`` and try ``-lxml2`` as a further fallback.
XML support is enabled iff one of those link attempts succeeds.
The sibling file ``cmake/tests/test_LAPACK.cmake`` follows the same shape for LAPACK.
There is no ``FLEUR_WITH_XML`` or ``FLEUR_WITH_LAPACK`` knob to force the result one way or the other, so a Spack recipe cannot make the choice deterministic without patching the probe out.

The fix is to make every optional feature explicit, and to drive the search from the toggle rather than the toggle from the search.
Spack variants tied to ``-DWITH_FOO=ON/OFF`` arguments passed unconditionally on the CMake command line then carry the full configuration through the spec hash.

----------------------------
Runtime telemetry, briefly
----------------------------

It is conventional in HPC applications to print hostname, username, and wall-clock time at the start of every run, and to write those values into output logs.
This is a separate concern from binary reproducibility: the bytes on disk are still identical, but the log files of two otherwise identical runs differ, which complicates side-by-side comparison and journal-quality re-execution of a published calculation.
A complete fix requires the application itself to gate this output on a ``--reproducible`` flag or similar, which is out of scope for the build system.

----------------------------
A practical checklist
----------------------------

Before claiming a package builds reproducibly:

#. The project does not write ``-march=native`` / ``-mtune=native`` / ``-xHost`` into its own ``CFLAGS`` / ``CXXFLAGS`` / ``FFLAGS``; the microarchitecture comes from the Spack spec.
#. The build completes from a tarball with no ``git`` binary available, and no network access during ``configure`` or ``cmake``.
#. Every optional feature is gated by an explicit ``-DWITH_FOO=ON/OFF`` or ``--with-foo`` / ``--without-foo``, with the ``find_package`` call placed *inside* the toggle.
#. ``strings`` over the installed prefix turns up no ``__DATE__`` / ``__TIME__`` / ``hostname`` / ``$USER`` strings.
#. Rebuilding the same spec on a second machine produces an identical install hash and identical file contents, verified with ``sha256sum`` over the prefix.

Once the last item holds across a stack, independent parties can rebuild the same software and verify byte-for-byte that nothing was tampered with along the way, which is the supply-chain-security property that motivates the whole exercise.
