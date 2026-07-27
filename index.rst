.. Copyright Spack Project Developers. See COPYRIGHT file for details.

   SPDX-License-Identifier: (Apache-2.0 OR MIT)

.. _spack-101:

===================
Tutorial: Spack 101
===================

This is an introduction to Spack with lectures and live demos.
It was last presented in-person at the `Practice and Experience in Advanced Research Computing (PEARC) 26 Conference <https://pearc.acm.org/pearc26/workshop-tutorials/>`_ July 27th, 2026. The event was a full-day tutorial.

You can use these materials to teach a course on Spack at your own site, or you can just skip ahead and read the live demo scripts to see how Spack is used in practice.

.. _slides:

.. rubric:: Slides

.. image:: tutorial/images/sc25-tutorial-slide-preview.png
   :target: _static/slides/spack-pearc26-tutorial-slides.pdf
   :height: 72px
   :align: left
   :alt: Slide Preview

:download:`Download Slides <_static/slides/spack-pearc26-tutorial-slides.pdf>`.

**Full citation:** Alec Scott, Caetano Melone, and Kathleen Shea.
Managing HPC Software Complexity with Spack.
Practice and Experience in Advanced Research Computing, Minneapolis, Minnesota, July 27, 2026.

.. _video:

.. rubric:: Video

For the last recorded video of this tutorial, see the `HPCIC Tutorial 2025 version <https://spack-tutorial.readthedocs.io/en/hpcic25/>`_.

.. _live-demos:

.. rubric:: Live Demos

We provide scripts that take you step-by-step through basic Spack tasks.
They correspond to sections in the slides above.

To run through the scripts, we provide the `spack/tutorial <https://ghcr.io/spack/tutorial>`_ container image.
You can invoke

.. code-block:: console

   $ docker pull ghcr.io/spack/tutorial:pearc26
   $ docker run -it ghcr.io/spack/tutorial:pearc26

to start using the container.
You should now be ready to run through our demo scripts:

#. :ref:`basics-tutorial`
#. :ref:`environments-tutorial`
#. :ref:`configs-tutorial`
#. :ref:`stacks-tutorial`
#. :ref:`packaging-tutorial`
#. :ref:`developer-workflows-tutorial`
#. :ref:`binary-cache-tutorial`
#. :ref:`spack-scripting-tutorial`

Other sections from past tutorials are also available, although they may not be kept up-to-date as frequently:

#. :ref:`modules-tutorial`
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
   tutorial_stacks
   tutorial_packaging
   tutorial_developer_workflows
   tutorial_binary_cache
   tutorial_scripting

.. toctree::
   :maxdepth: 3
   :caption: Additional sections

   tutorial_modules
   tutorial_buildsystems
   tutorial_advanced_packaging
