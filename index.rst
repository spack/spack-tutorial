.. Copyright 2013-2023 Lawrence Livermore National Security, LLC and other
   Spack Project Developers. See the top-level COPYRIGHT file for details.

   SPDX-License-Identifier: (Apache-2.0 OR MIT)

.. _spack-101:

===================
Tutorial: Spack 101
===================

This is an introduction to Spack with lectures and live demos. It was last presented at
the `Supercomputing 2023 Conference
<https://sc23.conference-program.com/presentation/?id=tut162&sess=sess226>`_, November
12, 2023. The event was a full-day tutorial.

You can use these materials to teach a course on Spack at your own site,
or you can just skip ahead and read the live demo scripts to see how
Spack is used in practice.

.. _slides:

.. rubric:: Slides

.. image:: tutorial/images/sc23-tutorial-slide-preview.png
   :target: _static/slides/spack-sc23-tutorial-slides.pdf
   :height: 72px
   :align: left
   :alt: Slide Preview

:download:`Download Slides <_static/slides/spack-sc23-tutorial-slides.pdf>`.

**Full citation:** Todd Gamblin, Gregory Becker, Richarda Butler, Massimiliano Culpo,
Tamara Dahlgren, Adam Stewart, Luke Peyralans, and Alec Scott. Managing HPC Software
Complexity with Spack. Supercomputing 2023 (SC23), Denver, CO. November 12 2023.

.. _video:

.. rubric:: Video

For the last video of this tutorial, see the `AWS/RADIUSS 2023 version
<https://spack-tutorial.readthedocs.io/en/radiuss23/>`_

.. _live-demos:

.. rubric:: Live Demos

We provide scripts that take you step-by-step through basic Spack tasks.
They correspond to sections in the slides above.

To run through the scripts, we provide the `spack/tutorial <https://ghcr.io/spack/tutorial>`_
container image. You can invoke

.. code-block:: console

   $ docker pull ghcr.io/spack/tutorial:sc23
   $ docker run -it ghcr.io/spack/tutorial:sc23

to start using the container. You should now be ready to run through our demo scripts:

  #. :ref:`basics-tutorial`
  #. :ref:`environments-tutorial`
  #. :ref:`configs-tutorial`
  #. :ref:`packaging-tutorial`
  #. :ref:`binary-cache-tutorial`
  #. :ref:`stacks-tutorial`
  #. :ref:`developer-workflows-tutorial`
  #. :ref:`modules-tutorial`
  #. :ref:`spack-scripting-tutorial`

Other sections from past tutorials are also available, although they may
not be kept up-to-date as frequently:

  #. :ref:`build-systems-tutorial`
  #. :ref:`advanced-packaging-tutorial`

Full contents:

.. toctree::
   :maxdepth: 2
   :caption: Links

   Main Spack Documentation <https://spack.readthedocs.io>

.. toctree::
   :maxdepth: 3
   :caption: Tutorial

   tutorial_basics
   tutorial_environments
   tutorial_configuration
   tutorial_packaging
   tutorial_binary_cache
   tutorial_stacks
   tutorial_developer_workflows
   tutorial_spack_scripting
   tutorial_modules
   tutorial_buildsystems
   tutorial_advanced_packaging
