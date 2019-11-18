.. Copyright 2013-2019 Lawrence Livermore National Security, LLC and other
   Spack Project Developers. See the top-level COPYRIGHT file for details.

   SPDX-License-Identifier: (Apache-2.0 OR MIT)

.. _spack-101:

===================
Tutorial: Spack 101
===================

This is a full-day introduction to Spack with lectures and live demos.
It was last presented at `Supercomputing 2019
<https://sc19.supercomputing.org/>`_ on November 18, 2019.

You can use these materials to teach a course on Spack at your own site,
or you can just skip ahead and read the live demo scripts to see how
Spack is used in practice.

.. _slides:

.. rubric:: Slides

.. image:: tutorial/images/pearc19-tutorial-slide-preview.png
   :height: 72px
   :align: left
   :alt: Slide Preview

:download:`Download Slides <tutorial/slides/Spack-SC19-Tutorial.pdf>`.

**Full citation:** Todd Gamblin, Gregory Becker, Massimiliano Culpo,
Mario Melara, Peter Scheibel, and Adam J. Stewart. Managing HPC Software
Complexity with Spack. Tutorial presented at Supercomputing 2019 (SC'19)
November 18, 2019. Denver, CO, USA.

.. _live-demos:

.. rubric:: Live Demos

We provide scripts that take you step-by-step through basic Spack tasks.
They correspond to sections in the slides above. You can use one of the
following methods to run through the scripts:

  1. We provide the `spack/tutorial
     <https://hub.docker.com/r/spack/tutorial>`_ container image on
     Docker Hub that you can use to do the tutorial on your local
     machine.  You can invoke ``docker run -it spack/tutorial`` to start
     using the container.

  2. When we host the tutorial, we also provision VM instances in `AWS
     <https://aws.amazon.com/>`_, so that users who are unfamiliar with
     Docker can simply log into a VPM to do the demo exercises.

You should now be ready to run through our demo scripts:

  #. :ref:`basics-tutorial`
  #. :ref:`configs-tutorial`
  #. :ref:`packaging-tutorial`
  #. :ref:`developer-workflows-tutorial`
  #. :ref:`environments-tutorial`
  #. :ref:`stacks-tutorial`
  #. :ref:`modules-tutorial`
  #. :ref:`build-systems-tutorial`
  #. :ref:`advanced-packaging-tutorial`
  #. :ref:`spack-scripting-tutorial`

Full contents:

.. toctree::
   :maxdepth: 2
   :caption: Links

   Main Spack Documentation <https://spack.readthedocs.io>

.. toctree::
   :maxdepth: 3
   :caption: Tutorial

   tutorial_basics
   tutorial_configuration
   tutorial_packaging
   tutorial_developer_workflows
   tutorial_environments
   tutorial_stacks
   tutorial_modules
   tutorial_buildsystems
   tutorial_advanced_packaging
   tutorial_spack_scripting
