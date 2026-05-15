.. Copyright Spack Project Developers. See COPYRIGHT file for details.

   SPDX-License-Identifier: (Apache-2.0 OR MIT)

.. include:: common/setup.rst

.. _reproducible-builds-tutorial:

======================================
Best Practices for Reproducible Builds
======================================

Spack identifies every installation by a hash of *all its inputs*: the package recipe, the concrete spec (version, variants, compiler, target), and the hashes of every dependency, recursively.
The *hope* behind this design is that a ``spack.yaml`` and its accompanying ``spack.lock`` are enough to reproduce a build **bit-for-bit**, on a different machine, at a different time.

Bit-for-bit reproducibility of native code is often assumed to be infeasible in practice, but Debian, for example, now only ships binaries that have been independently rebuilt and verified to be identical on different machines and at different times.
Independent reproduction is a strong defense against supply-chain attacks, since a backdoored compiler or a tampered build host shows up immediately as a divergence from the reference build.
For scientific computing the motivation is closely related: a published result that depends on a specific software stack can only be trusted and re-examined later if that stack can be rebuilt exactly, by a different group, on a different machine, possibly years after the original run.
Reproducible builds turn "the same software" from a claim about labels and version numbers into a verifiable property of the bytes that actually executed.

Spack aims for the same property, but there are obvious obstacles:

* We rely on **externals** like ``glibc`` and the host's kernel headers.
* Spack's build environment is **impure**: the compiler will happily pick up headers and libraries from ``/usr`` if it finds them, and small changes to the host system can leak into the binary.
* Spack runs on top of whatever "dirty" environment the user happens to be in: loaded modules, ``LD_LIBRARY_PATH``, locale, ``umask``, you name it.

Closing this gap requires work on two sides: in Spack itself, and in the packages it builds.
This page is mostly about the latter, with a short summary of the former for context.

--------------------------------------
What Spack itself is doing (or fixing)
--------------------------------------

These are things the Spack developers are actively working on, so that the ``spack.yaml`` + ``spack.lock`` promise gets closer to reality:

a. **Deterministic compiler invocations.**
   Making sure GCC (and other compilers) run deterministically: stable temporary file names, no embedded timestamps, no host paths leaking into debug info, no random symbol ordering.
b. **A fixed, minimal environment.**
   Stripping the build environment down to a known set of environment variables.
   The build should not depend on whatever ``$PATH``, ``$LD_LIBRARY_PATH``, or ``$CFLAGS`` the user happened to have exported in their shell.
c. **Sandboxing (new in Spack v1.2, via Linux Landlock).**
   Opt-in filesystem and network sandboxing for the build, so that builds cannot accidentally read from ``/usr``, ``$HOME``, or reach out to the network.
   If a build succeeds inside the sandbox, you know its inputs really were just the declared dependencies.
d. **Source integrity, which Spack has always done.**
   Every fetched archive is validated against a ``sha256`` checksum recorded in the recipe, so the *source* side of the build is already pinned.

With these in place, the remaining sources of non-determinism live in the packages themselves, which is what the rest of this page addresses.

------------------------------------------------
What package and application authors need to do
------------------------------------------------

The recurring theme on the package side is that anything which depends on the specific CPU, kernel, hostname, user, or wall-clock of the build host will make the resulting binary non-reproducible, and usually non-portable as well.
The most common offenders are described below.

``-march=native`` and ``-mtune=native``
   These flags tell the compiler "optimize for whatever CPU I happen to be on right now".
   Two build hosts with different CPUs will produce different binaries from the same source.
   Use an *explicit* microarchitecture instead, either via Spack's ``target=`` (e.g. ``target=x86_64_v3``, ``target=zen3``) or by passing ``-march=<arch>`` directly.
   Spack already exposes the concrete target in the spec hash, so as long as you pick a named target, the build is reproducible.

Embedding build-host information
   Many build systems record where and when they were built, and the resulting metadata ends up in the installed artifacts.
   Common culprits include:

   * ``__DATE__`` / ``__TIME__`` macros in C/C++.
   * ``hostname`` or ``$USER`` baked into version strings.
   * Absolute paths from the build directory ending up in debug info or in ``__FILE__``.
   * Timestamps in archive members (``.a``, ``.tar``, ``.zip``, ``.jar``, wheels, ...).

   Strip them out at the source, or honor ``SOURCE_DATE_EPOCH`` and use deterministic archivers (``ar D``, reproducible tarballs, ``strip-nondeterminism``).

Non-deterministic build steps
   * Parallel code generators that emit symbols in hash-table order.
   * ``find`` / ``ls`` output piped into a generated file without sorting.
   * Python ``.pyc`` files compiled with a non-fixed ``PYTHONHASHSEED`` / ``SOURCE_DATE_EPOCH``.
   * Random IDs or UUIDs generated at build time.

   The fix is almost always to sort, seed, or pin: ``LC_ALL=C sort``, ``PYTHONHASHSEED=0``, explicit seeds for any code generator.

Implicit host dependencies
   * ``#include`` paths or ``-L`` paths that depend on what is installed in ``/usr/include`` or ``/usr/lib``.
   * ``pkg-config`` picking up system ``.pc`` files.
   * Optional features auto-enabled when a header happens to be present ("configure found ``libfoo``, enabling foo support").

   Make optional features **explicit** in the recipe (Spack ``variant``\ s tied to real dependencies), and pass ``--without-*`` / equivalent flags for everything you do not want.
   If sandboxing (item *c* above) is enabled, these implicit pickups become hard errors, which is what you want.

Compiler and linker flag drift
   Two builds with different ``CFLAGS`` are not the same build, so compiler flags should be pinned in the package recipe rather than read from the environment, and autotools options such as ``--enable-fast-install`` whose behavior depends on the host should be avoided.

----------------------------
A practical checklist
----------------------------

Before claiming a package builds reproducibly:

#. No ``-march=native`` / ``-mtune=native``: an explicit target is set.
#. No ``__DATE__`` / ``__TIME__`` / ``hostname`` / ``$USER`` in the binary (``strings`` on the output is a quick sanity check).
#. Build honors ``SOURCE_DATE_EPOCH`` and uses deterministic archivers.
#. All optional features are controlled by explicit variants, not autodetected.
#. The build passes inside a Spack sandbox (no implicit reads from ``/usr`` or the network).
#. Rebuilding the same spec on a second machine produces an identical install hash *and* identical file contents (compare with ``sha256sum`` over the prefix).

Once the last item holds across a stack, independent parties can rebuild the same software and verify byte-for-byte that nothing was tampered with along the way, which is the supply-chain-security property that motivates the whole exercise.
