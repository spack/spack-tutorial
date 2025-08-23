.. Copyright 2013-2022 Lawrence Livermore National Security, LLC and other
   Spack Project Developers. See the top-level COPYRIGHT file for details.

   SPDX-License-Identifier: (Apache-2.0 OR MIT)

.. include:: common/setup.rst

.. _testing-tutorial:

=========================
Package Testing Tutorial
=========================

Once you have a recipe in a Spack package that can successfully build
your software (see `Package Creation
<https://spack-tutorial.readthedocs.io/en/latest/tutorial_packaging.html>`_),
it's time to consider how people who use your package can gain confidence
that the software works. The package already encapsulates the installation
process, so it can do the same for testing.

Just because `spack install` completes without reporting errors does
not necessarily mean the software installed correctly or will continue
to work indefinitely. How can that be true? There are a number of possible
reasons, including:

* the installation process may not have fully installed the software;
* the installed software may not work; or
* the software may work right after it is installed but, due to system
  changes, stop working weeks or months later.

Spack provides several features for `checking installed software
<https://spack.readthedocs.io/en/latest/packaging_guide.html#checking-an-installation>`_:

* sanity checks of installed files and or directories;
* post-installation phase checks; and
* stand-alone (or smoke) tests.

This tutorial walks you through the steps for adding these types of
tests to your package and running them.

---------------
Getting started
---------------

First confirm you have three environment variables set as follows:

* ``SPACK_ROOT``: consisting of the path to your Spack installation;
* ``PATH``: including ``$SPACK_ROOT/bin`` (so calls to the ``spack``
  command work); and
* ``EDITOR``: containing the path of your preferred text editor (so
  Spack can run it when we modify the package).

The first two variables are automatically set by ``setup-env.sh`` so,
if they aren't, run the following command:

.. code-block:: console

   $ . ~/spack/share/spack/setup-env.sh

You'll also need to create the ``EDITOR`` environment variable if it is
not set.

In order to avoid modifying your Spack instance with changes from this
tutorial, let's add a **package repository** called ``spack-tests``
just for this tutorial by entering the following command:

.. literalinclude:: outputs/testing/repo-add.out
   :language: console
   :emphasize-lines: 1

Doing this ensures changes we make here do not adversely affect other
parts of the tutorial. You can find out more about repositories at
`Package Repositories
<https://spack.readthedocs.io/en/latest/repositories.html>`_.

-------------------------
Creating the package file
-------------------------

Let's start with a fairly complete ``TBD`` example from the
`Package Creation Tutorial
<https://spack-tutorial.readthedocs.io/en/latest/tutorial_packaging.html#>`_.
It is an `AutotoolsPackage
<https://spack.readthedocs.io/en/latest/build_systems/autotoolspackage.html#>`_
so there are standard features we will consider leveraging (later)
in testing.

Spack will create a suitable template when you run ``spack create``
with the software's repository URL by entering:

.. literalinclude:: outputs/testing/TBD-create.out
   :language: console
   :emphasize-lines: 1

You should now be in your text editor of choice, with the ``package.py``
file open for editing. Let's replace **all** of the templated contents
with the following:

.. literalinclude:: outputs/testing/1.package.py
   :caption: TBD/package.py (from outputs/testing/1.package.py)
   :language: python

and save the results.

-----------------------
Adding build-time tests
-----------------------

Let's first install the package before proceeding to add build-time
tests.  We'll do this by entering the ``spack install`` command:

.. literalinclude:: outputs/testing/TBD-install-1.out
   :language: console
   :emphasize-lines: 1


-------------------
More information
-------------------

This tutorial only scratches the surface of adding package tests. For
more information, take a look at the Spack resources below.

^^^^^^^^^^^^^^^^^^^^^
Package test features
^^^^^^^^^^^^^^^^^^^^^

* `Build-time tests
  <https://spack.readthedocs.io/en/latest/packaging_guide.html#build-time-tests>`_: sanity and installation phase checks
* `Built-in installation phase tests
  <https://spack.readthedocs.io/en/latest/packaging_guide.html#id22>`_: standard build-time test checks (when available)
* `Stand-alone (or smoke) tests
  <https://spack.readthedocs.io/en/latest/packaging_guide.html#stand-alone-or-smoke-tests>`_: re-using, customizing, and inheriting checks

^^^^^^^^^^^^^^
Spack commands
^^^^^^^^^^^^^^

* `spack test
  <https://spack.readthedocs.io/en/latest/command_index.html#spack-test>`_: stand-alone (or smoke test) availability and execution
* `spack repo
  <https://spack.readthedocs.io/en/latest/command_index.html#spack-test>`_: tutorial sandbox

-----------
Cleaning up
-----------

Before leaving, let's ensure what we have done does not interfere with
your Spack instance or future sections of the tutorial. Undo the work
by entering the following commands:

.. literalinclude:: outputs/testing/cleanup.out
   :language: console
   :emphasize-lines: 1,3,5
