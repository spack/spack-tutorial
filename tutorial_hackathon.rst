.. Copyright Spack Project Developers. See COPYRIGHT file for details.

   SPDX-License-Identifier: (Apache-2.0 OR MIT)

.. include:: common/setup.rst

.. _hackathon-tutorial:

=======================
Day 3: Open hackathon
=======================

Day 3 is unstructured: the room is open, instructors are available, and the expectation is that attendees work on their own projects or extend what was covered on Day 1 and Day 2.
The two exercises below are starting points for attendees who want a concrete task rather than open-ended exploration.
Both are designed to take roughly half a morning and to build directly on material already covered.

----------------------------------------------------
Exercise 1: Reproduce the ELPA / OpenMP fix yourself
----------------------------------------------------

The :ref:`developer-workflows-tutorial` chapter walks through a fix to Quantum ESPRESSO's ``FindELPA.cmake`` finder so that a CMake build of QE links against an OpenMP build of ELPA.
Reading that chapter once is enough to follow the reasoning.
Doing it on your own machine, from a fresh environment, is what builds the muscle memory for the ``spack develop`` / patch / ``patch()`` cycle.

The goal of this exercise is a working ``quantum-espresso +elpa %elpa +openmp build_system=cmake`` installation, built from your own clone of QE, with the fix applied as a local edit.

Set up a fresh environment:

.. code-block:: console

   $ spack env activate --create qe-hack
   $ spack config edit

with the manifest from the developer workflow chapter:

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

Clone Quantum ESPRESSO at the ``qe-7.5`` tag and create a branch for local edits:

.. code-block:: console

   $ cd ~
   $ git clone --depth 2 -c advice.detachedHead=false \
         -b qe-7.5 https://gitlab.com/QEF/q-e.git
   $ cd q-e
   $ git switch -c qe-7.5-dev

Register the clone with Spack:

.. code-block:: console

   $ spack develop --path ~/q-e quantum-espresso@7.5

Edit the recipe with ``spack edit quantum-espresso`` and relax the constraint that blocks ``build_system=cmake`` together with ``elpa+openmp``.
The final shape of the ``with when("+elpa"):`` block is documented in :ref:`developer-workflows-tutorial`.

Run ``spack install --until cmake`` to confirm the configure step fails: the relevant log line names ``ELPA_LIBRARIES``, ``ELPA_INCLUDE_DIRS``, ``ELPA_Fortran_MODS_DIR``, and ``ELPA_VERSION`` as unset.
The cause is in ``q-e/cmake/FindELPA.cmake``, which searches unconditionally for ``libelpa`` while the OpenMP build of ELPA installs as ``libelpa_openmp``.

The diff that fixes the finder is reproduced in :ref:`developer-workflows-tutorial`; transcribe it into ``cmake/FindELPA.cmake`` and rerun ``spack install``.
The configure output should now print ``Found ELPA: .../libelpa_openmp.so``.

-----------------------------------------------------
Exercise 2: Two independent builds of the same spec
-----------------------------------------------------

The :ref:`reproducible-builds-tutorial` chapter argues that a ``spack.yaml`` plus ``spack.lock`` should be enough to reproduce a build on a different machine.
This exercise tests that claim end-to-end: one attendee creates and concretizes the environment, the other rebuilds it from the lock file, and the two installs are compared after the fact.

The target spec is ``zlib-ng``: small, pure C, and built in under a minute, so any difference that does show up is the compiler wrapper's responsibility and easy to interpret.

Pair up with another attendee before starting.

**Person A** creates an environment, concretizes, and sends the resulting manifest and lock file to person B:

.. code-block:: console

   $ spack env create -d ~/repro
   $ cd ~/repro
   $ spack -e . add zlib-ng
   $ spack -e . concretize

Then send ``~/repro/spack.yaml`` and ``~/repro/spack.lock`` to person B.

**Person B** drops the two files into a fresh directory:

.. code-block:: console

   $ mkdir ~/repro && cd ~/repro
   # copy spack.yaml and spack.lock from person A into this directory

Both attendees then build, in their respective containers, with a clean shell environment:

.. code-block:: console

   $ cd ~/repro
   $ env -i \
         HOME="$HOME" \
         PATH=/usr/bin:/bin \
         SOURCE_DATE_EPOCH=1700000000 \
         TZ=UTC \
         ~/spack/bin/spack -e . install

``env -i`` clears the inherited shell environment so that loaded modules, stray ``LD_LIBRARY_PATH`` exports, and other leftovers from the outer shell cannot leak past Spack into the build.
Spack itself already clears most of the dangerous variables (``LD_LIBRARY_PATH``, ``CPATH``, ``CMAKE_PREFIX_PATH``, ``CFLAGS`` and friends, every ``*_ROOT``) and sets ``LC_ALL=C`` from ``config:build_language``, so the outer command-line only needs to add what Spack does not normalize: ``SOURCE_DATE_EPOCH`` for embedded timestamps and ``TZ=UTC`` so that any tool that formats that epoch produces the same string on both machines.

Exchange install prefixes and compare:

.. code-block:: console

   $ diff -r /a/install/prefix /b/install/prefix      # quick check
   $ diffoscope /a/install/prefix /b/install/prefix   # detailed report

``diff -r`` is enough to answer "are they the same"; ``diffoscope`` is what to reach for when they are not, because it descends into static archives, normalizes ELF metadata into a readable form, and decodes Python bytecode.

The expected result is that the installed library and headers match byte-for-byte.
The differences live under ``.spack/`` inside the prefix: install-time metadata, and the build log, which contains the same lines on both machines but interleaved differently because parallel ``make -j`` does not impose an order on its subprocesses' output.

