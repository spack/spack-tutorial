.. Copyright 2013-2021 Lawrence Livermore National Security, LLC and other
   Spack Project Developers. See the top-level COPYRIGHT file for details.

   SPDX-License-Identifier: (Apache-2.0 OR MIT)

.. include:: common/setup.rst

.. _testing-tutorial:

=========================
Package Testing Tutorial
=========================

This tutorial walks you through the steps for adding and running Spack
package tests during and after the software installation process. A package
that *appears* to install successfully may not actually be installed
correctly or continue to work indefinitely. There are a number of possible
reasons. For example, the installation process may not have fully installed
the software. The installed software may not work. Or the software may
work right after it is installed but, due to system changes, it stops
working days, weeks, or months later. So Spack provides features for
`checking installed software
<https://spack-tutorial.readthedocs.io/en/latest/tutorial_packaging.html>`_

Recall from `Package Creation
<https://spack-tutorial.readthedocs.io/en/latest/tutorial_packaging.html>`_
that Spack packages are installation scripts, or recipes, for building
software. As such, they are well suited for also encapsulating recipes
for testing the installed software.

Tests can be performed at two points in the life of an installed 
package:  build-time and stand-alone. **Build-time** tests run as
part of the package installation process. **Stand-alone** tests run
at any point after the software is installed.

---------------
Getting started
---------------

In order to avoid modifying your Spack instance with changes from this
tutorial, let's add a package repository called ``spack-tests``:

.. literalinclude:: outputs/testing/repo-add.out
   :language: console

Doing this ensures changes we make here do not adversely affect other
parts of the tutorial. You can find out more about repositories at
`Package Repositories <https://spack.readthedocs.io/en/latest/repositories.html>`_.

-----------
Cleaning up
-----------

Before leaving, let's ensure what we have done does not interfere with your
Spack instance or future sections of the tutorial. Undo the work by entering
the following commands:

.. literalinclude:: outputs/testing/cleanup.out
   :language: console

