.. Copyright Spack Project Developers. See COPYRIGHT file for details.

   SPDX-License-Identifier: (Apache-2.0 OR MIT)

.. include:: common/setup.rst

.. _configs-tutorial:

======================
Configuration Tutorial
======================

This tutorial will guide you through various configuration options that allow you to customize Spack's behavior with respect to software installation.
There are many different configuration sections.
A partial list of some key configuration sections is provided below.

.. list-table:: Spack Configuration Sections
   :widths: 15 55
   :header-rows: 1

   * - Name
     - Description
   * - config
     - General settings (install location, number of build jobs, etc)
   * - concretizer
     - Specialization of the concretizer behavior (reuse, unification, etc)
   * - Mirrors
     - Locations where spack can look for stashed source or binary distributions
   * - Packages
     - Define the compilers that Spack can use, and add rules/preferences for package concretization
   * - Modules
     - Naming, location and additional configuration of Spack generated modules

The full list of sections can be viewed with ``spack config list``.
For further education, we encourage you to explore the Spack `documentation on configuration files <https://spack.readthedocs.io/en/latest/configuration.html#configuration-files>`_.

The principle goals of this section of the tutorial are:

1. Introduce the configuration sections and scope hierarchy
2. Demonstrate how to manipulate configurations
3. Show how to configure system assets with Spack (compilers and packages)

As such, we will primarily focus on the ``compilers`` and ``packages`` configuration sections in this portion of the tutorial.

We will explain this by first covering how to manipulate configurations from the command line and then show how this impacts the configuration file hierarchy.
We will then move into compiler and package configurations to help you develop skills for getting the builds you want on your system.
Finally, we will give some brief attention to more generalized Spack configurations in the ``config`` section.

For all of these features, we will demonstrate how we build up a full configuration file.
For some, we will then demonstrate how the configuration affects the install command, and for others we will use the ``spack spec`` command to demonstrate how the configuration changes have affected Spack's concretization algorithm.
The provided output is all from a server running Ubuntu version 22.04.

-----------------------------------
Configuration from the command line
-----------------------------------

You can run ``spack config blame [section]`` at any point in time to see what your current configuration is.
If you omit the section, then spack will dump all the configurations settings to your screen.
Let's go ahead and run this for the ``concretizer`` section.

.. code-block:: console

   $ spack config blame concretizer

Notice that the ``spack:concretizer:reuse`` option is defaulted to ``true``.
For this section we'd actually like to turn reuse off so that when we demonstrate package configuration our preferences are weighted higher than available binaries for the concretizer solution selection procedure.

One of the most convenient ways to set configuration options is through the command line.

.. code-block:: console

  $ spack config add concretizer:reuse:false

If we rerun ``spack config blame concretizer`` we can see that the change was applied.

.. code-block:: console

   $ spack config blame concretizer

Notice that the reference file for this option is now different.
This indicates the scope where the configuration was set in, and we will discuss how Spack chooses the default scope shortly.
For now, it is important to note that the ``spack config`` command accepts an optional ``--scope`` flag so we can be more precise in the configuration process.
This will make more sense after the next section which provides the definition of Spack's configuration scopes and their hierarchy.

.. _configs-tutorial-scopes:

--------------------
Configuration Scopes
--------------------

Depending on your use case, you may want to provide configuration settings common to everyone on your team, or you may want to set default behaviors specific to a single user account.
Spack provides six configuration *scopes* to handle this customization.
These scopes, in order of decreasing priority, are:

============   ===================================================
Scope          Directory
============   ===================================================
Command Line   N/A
Environment    In environment base directory (in ``spack.yaml``)
Custom         Custom directory, specified with ``--config-scope``
User           ``~/.spack/``
Site           ``$SPACK_ROOT/etc/spack/``
System         ``/etc/spack/``
Defaults       ``$SPACK_ROOT/etc/spack/defaults/``
============   ===================================================

Spack's default configuration settings reside in ``$SPACK_ROOT/etc/spack/defaults``.
These are useful for reference, but should never be directly edited.
To override these settings, create new configuration files in any of the higher-priority configuration scopes.

A particular cluster may have multiple Spack installations associated with different projects.
To provide settings common to all Spack installations, put your configuration files in ``/etc/spack``.
To provide settings specific to a particular Spack installation, you can use the ``$SPACK_ROOT/etc/spack`` directory.

For settings specific to a particular user, you will want to add configuration files to the ``~/.spack`` directory.
When Spack first checked for compilers on your system, you may have noticed that it placed your compiler configuration in this directory.

Configuration settings can also be placed in a custom location, which is then specified on the command line via ``--config-scope``.
An example use case is managing two sets of configurations, one for development and another for production preferences.

Settings specified on the command line have precedence over all other configuration scopes.

^^^^^^^^^^^^^^^^^^^^^^^^
Platform-specific scopes
^^^^^^^^^^^^^^^^^^^^^^^^

Some facilities manage multiple platforms from a single shared file system.
In order to handle this, each of the configuration scopes listed above has two *sub-scopes*: platform-specific and platform-independent.
For example, compiler settings can be stored in the following locations:

#. ``$ENVIRONMENT_ROOT/spack.yaml``
#. ``~/.spack/<platform>/compilers.yaml``
#. ``~/.spack/compilers.yaml``
#. ``$SPACK_ROOT/etc/spack/<platform>/compilers.yaml``
#. ``$SPACK_ROOT/etc/spack/compilers.yaml``
#. ``/etc/spack/<platform>/compilers.yaml``
#. ``/etc/spack/compilers.yaml``
#. ``$SPACK_ROOT/etc/defaults/<platform>/compilers.yaml``
#. ``$SPACK_ROOT/etc/defaults/compilers.yaml``

These files are listed in decreasing order of precedence, so files in ``~/.spack/<platform>`` will override settings in ``~/.spack``.

-----------
YAML Format
-----------

Spack configurations are nested YAML dictionaries with a specified schema.
The configuration is organized into sections based on theme (e.g., a 'packages' section) and the highest-level keys of the dictionary specify the section.
Spack generally maintains a separate file for each section, although environments keep them together (in ``spack.yaml``).

When Spack checks its configuration, the configuration scopes are updated as dictionaries in increasing order of precedence, allowing higher precedence files to override lower.
YAML dictionaries use a colon ":" to specify key-value pairs.
Spack extends YAML syntax slightly to allow a double-colon "::" to specify a key-value pair.
When a double-colon is used, instead of adding that section, Spack replaces what was in that section with the new value.
For example, look at high-level config:

.. code-block:: console

   $ spack config blame config

.. code-block:: yaml

   ---                                                   config:
   /etc/spack/config.yaml:2                                suppress_gpg_warnings: True
   /home/spack/spack/etc/spack/defaults/config.yaml:19     install_tree:
   /home/spack/spack/etc/spack/defaults/config.yaml:20       root: $spack/opt/spack
   ...
   /home/spack/spack/etc/spack/defaults/config.yaml:238    aliases:
   /home/spack/spack/etc/spack/defaults/config.yaml:239      concretise: concretize
   /home/spack/spack/etc/spack/defaults/config.yaml:240      containerise: containerize
   /home/spack/spack/etc/spack/defaults/config.yaml:241      rm: remove

We can see overrides in action with:

.. code-block:: console

  $ spack config add config:aliases::{}
  $ spack config blame config

.. code-block:: yaml

   ---                                                   config:
   /home/spack/.spack/config.yaml:2                        aliases: {}

The default write scope is the user scope, which overrides the defaults.
You can undo this by editing the config section like:

.. code-block:: console

   $ spack config edit config

A configuration section appears nearly the same when managed in an environment's ``spack.yaml`` file except that the section is nested 1 level underneath the top-level 'spack' key.
For example the above ``config.yaml`` could be incorporated into an environment's ``spack.yaml`` like so:

.. code-block:: yaml

   spack:
     specs: []
     view: true
     config:
       aliases:: {}


.. _configs-tutorial-compilers:

----------------------
Compiler Configuration
----------------------

For most tasks, we can use Spack with the compilers auto-detected the first time Spack runs on a system.
As discussed in the basic installation tutorial, we can also tell Spack where compilers are located using the ``spack compiler add`` command.
However, in some circumstances, we want even more fine-grained control over the compilers available.
This section will teach you how to exercise that control using the compilers configuration.

We will start by opening the compilers configuration (which lives in the packages section):

.. code-block:: console

   $ spack config edit packages


We start with no active environment, so this will open a ``packages.yaml`` file for editing (you can also do this with an active environment):

.. code-block:: yaml

   packages:
     gcc:
       externals:
       - spec: gcc@10.5.0 languages:='c,c++,fortran'
         prefix: /usr
         extra_attributes:
           compilers:
             c: /usr/bin/gcc-10
             cxx: /usr/bin/g++-10
             fortran: /usr/bin/gfortran-10
       - spec: gcc@11.4.0 languages:='c,c++,fortran'
         prefix: /usr
         extra_attributes:
           compilers:
             c: /usr/bin/gcc
             cxx: /usr/bin/g++
             fortran: /usr/bin/gfortran
     llvm:
       externals:
       - spec: llvm@14.0.0+clang~flang~lld~lldb
         prefix: /usr
         extra_attributes:
           compilers:
             c: /usr/bin/clang
             cxx: /usr/bin/clang++

This specifies two versions of the GCC compiler and one version of the Clang compiler with no Flang compiler.
Now suppose we have a code that we want to compile with the Clang compiler for C/C++ code, but with gfortran for Fortran components.
We can do this by adding creating a toolchain config:

.. code-block:: console

   $ spack config edit toolchains

.. code-block:: yaml

   toolchains:
     clang_gfortran:
     - spec: '%c=llvm@14.0.0'
       when: '%c'
     - spec: '%cxx=llvm@14.0.0'
       when: '%cxx'
     - spec: '%fortran=gcc@11.4.0'
       when: '%fortran'

We are essentially saying "use Clang for c/c++, and use GCC for Fortran".
You can use this new entry like so:

.. code-block:: console

   $ spack spec openblas %clang_gfortran

Note the identifier ``clang_gfortran`` is not itself a spec (you don't version it).
You reference it in other specs.
Note that without ``when: '%fortran'``, you could not use ``clang_gfortran`` with packages unless they depended on Fortran (likewise for the `when` statements on c/cxx).

.. These sections specify when Spack can use different compilers, and are primarily useful for configuration files that will be used across multiple systems.

^^^^^^^^^^^^^^
Compiler flags
^^^^^^^^^^^^^^

Some compilers may require specific compiler flags to work properly in a particular computing environment.
Spack provides configuration options for setting compiler flags every time a specific compiler is invoked.
These flags become part of the package spec and therefore of the build provenance.
As on the command line, the flags are set through the implicit build variables ``cflags``, ``cxxflags``, ``cppflags``, ``fflags``, ``ldflags``, and ``ldlibs``.

Let's open our compilers configuration file again and add a compiler flag:

.. code-block:: yaml
   :emphasize-lines: 11-12

   packages:
     gcc:
       externals:
       - spec: gcc@11.4.0 languages:='c,c++,fortran'
         prefix: /usr
         extra_attributes:
           compilers:
             c: /usr/bin/gcc
             cxx: /usr/bin/g++
             fortran: /usr/bin/gfortran
           flags:
             cppflags: -g


We can test this out using the ``spack spec`` command to show how the spec is concretized:

.. literalinclude:: outputs/config/0.compiler_flags.out
   :language: console


We can see that ``cppflags="-g"`` has been added to every node in the DAG.

.. It even added it to gcc-runtime, hmm...

^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
Advanced compiler configuration
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Some additional fields not discussed yet, in an example:

.. code-block:: yaml
   :emphasize-lines: 6-7, 15-19

   packages:
     gcc:
       externals:
       - spec: gcc@11.4.0 languages:='c,c++,fortran'
         prefix: /usr
         modules:
         - gcc/11.4.0
         extra_attributes:
           compilers:
             c: /usr/bin/gcc
             cxx: /usr/bin/g++
             fortran: /usr/bin/gfortran
           flags:
             cppflags: -g
           extra_rpaths:
           - /a/path/to/somewhere/important
           environment:
             set:
               EG_A_LICENSE_FILE: 1713@license4

.. The ``target`` field of the compiler defines the cpu architecture **family** that the compiler supports.
.. (target isn't in the compiler schema in packages anymore: how do we say "target generic x86_64 whenever you use this compiler")

The ``modules`` field of the compiler was originally designed to support older Cray systems, but can be useful on any system that has compilers that are only usable when a particular module is loaded.
Any modules in the ``modules`` field of the compiler configuration will be loaded as part of the build environment for packages using that compiler.

The ``environment`` field of the compiler configuration is used for compilers that require environment variables to be set during build time.
For example, if your Intel compiler suite requires the ``INTEL_LICENSE_FILE`` environment variable to point to the proper license server.
In addition to ``set``, ``environment`` also supports ``unset``, ``prepend_path``, and ``append_path``.

The ``extra_rpaths`` field of the compiler configuration is used for compilers that do not rpath all of their dependencies by default.
Since compilers are often installed externally to Spack, Spack is unable to manage compiler dependencies and enforce rpath usage.
This can lead to packages not finding link dependencies imposed by the compiler properly.
For compilers that impose link dependencies on the resulting executables that are not rpath'ed into the executable automatically, the ``extra_rpaths`` field of the compiler configuration tells Spack which dependencies to rpath into every executable created by that compiler.
The executables will then be able to find the link dependencies imposed by the compiler.


.. _configs-tutorial-package-prefs:

-------------------------------
Configuring Package Preferences
-------------------------------

Package preferences in Spack are managed through the ``packages`` configuration section.
First, we will look at the default ``packages.yaml`` file.

.. code-block:: console

   $ spack config --scope=defaults:base edit packages


.. literalinclude:: _spack_root/etc/spack/defaults/packages.yaml
   :language: yaml
   :emphasize-lines: 51


This sets the default preferences for providers of virtual packages.
We can edit this to change provider preferences and also to create a preference for compilers.
To illustrate how this works, suppose we want to change the preferences to prefer the Clang compiler and to prefer MPICH over OpenMPI.
Currently, we prefer GCC and OpenMPI.

.. literalinclude:: outputs/config/0.prefs.out
   :language: console
   :emphasize-lines: 15


Let's override these default preferences in an environment.
When you have an activated environment, you can edit the associated configuration with ``spack config edit`` (you don't have to provide a section name):

.. code-block:: console

   $ spack env create config-env
   $ spack env activate config-env
   $ spack config edit


.. warning::

   You will get exactly the same effects if you make these changes
   without using an environment, but you must delete the
   associated ``packages.yaml`` file after the config tutorial or
   the commands you run in later tutorial sections will not
   produce the same output (because they weren't run with the
   configuration changes made here)


.. code-block:: yaml

   spack:
     specs: []
     view: true
     concretizer:
       unify: true
     packages:
       all:
         require:
         - one_of: ["%llvm", "%gcc"]
         providers:
           mpi: [mpich, openmpi]


Because of the configuration scoping we discussed earlier, this overrides the default settings just for these two items.

.. literalinclude:: outputs/config/1.prefs.out
   :language: console
   :emphasize-lines: 16


^^^^^^^^^^^^^^^^^^^
Variant preferences
^^^^^^^^^^^^^^^^^^^

As we've seen throughout this tutorial, HDF5 builds with MPI enabled by default in Spack.
If we were working on a project that would routinely need serial HDF5, that might get annoying quickly, having to type ``hdf5~mpi`` all the time.
Instead, we'll update our config to force disable it:

.. code-block:: yaml
   :emphasize-lines: 12-13

   spack:
     specs: []
     view: true
     concretizer:
       unify: true
     packages:
       all:
         require:
         - one_of: ["%llvm", "%gcc"]
         providers:
           mpi: [mpich, openmpi]
       hdf5:
         require: ~mpi


Now hdf5 will concretize without an MPI dependency by default.

.. literalinclude:: outputs/config/3.prefs.out
   :language: console
   :emphasize-lines: 2


In general, every attribute that we can set for all packages we can set separately for an individual package.

^^^^^^^^^^^^^^^^^
External packages
^^^^^^^^^^^^^^^^^

The packages configuration file also controls when Spack will build against an externally installed package.
Spack has a ``spack external find`` command that can automatically discover and register externally installed packages.
This works for many common build dependencies, but it's also important to know how to do this manually for packages that Spack cannot yet detect.

On these systems, we have a pre-installed curl.
Let's tell Spack about this package and where it can be found:

.. code-block:: yaml
   :emphasize-lines: 14-17

   spack:
     specs: []
     view: true
     concretizer:
       unify: true
     packages:
       all:
         require:
         - one_of: ["%llvm", "%gcc"]
         providers:
           mpi: [mpich, openmpi]
       hdf5:
         require: ~mpi
       curl:
         externals:
         - spec: curl@7.81.0 %gcc@11.4.0
           prefix: /usr
         buildable: false


Here, we've told Spack that Curl 7.81.0 is installed on our system.
We've also told it the installation prefix where Curl can be found.
We don't know exactly which variants it was built with, but that's okay.
Finally, we set ``buildable: false`` to require that Spack not try to build its own.

.. The weighting/preferences dont work quite the same so I skipped right to buildable:false

.. literalinclude:: outputs/config/2.externals.out
   :language: console


This gets slightly more complicated with virtual dependencies.
Suppose we don't want to build our own MPI, but we now want a parallel version of HDF5.
Well, fortunately, we have MPICH installed on these systems.

Instead of manually configuring an external for MPICH like we did for Curl we will use the ``spack external find`` command.
For packages that support this option, this is a useful way to avoid typos and get more accurate external specs.

.. literalinclude:: outputs/config/0.external_find.out
   :language: console

To express that we don't want any other MPI installed, we can use the virtual ``mpi`` package as a key.
While we're editing the ``spack.yaml`` file, make sure to configure HDF5 to be able to build with MPI again:

.. code-block:: yaml
   :emphasize-lines: 19-24

   spack:
     specs: []
     view: true
     concretizer:
       unify: true
     packages:
       all:
         require:
         - one_of: ["%llvm", "%gcc"]
         providers:
           mpi: [mpich, openmpi]
       curl:
         externals:
         - spec: curl@7.81.0 %gcc@11.4.0
           prefix: /usr
         buildable: false
       mpich:
         externals:
         - spec: mpich@4.0+hydra device=ch4 netmod=ofi
           prefix: /usr
       mpi:
         buildable: false

.. 3.externals.out has mpich
.. The concretization result is strange and enables some qt stuff that makes it huge

If you run this as-is, you'll notice Spack still hasn't built ``hdf5`` with our external ``mpich``.
The concretizer has instead turned off ``mpi`` support in ``hdf5``.
To debug this, we will force Spack to use ``hdf5+mpi``.

.. code-block:: console

   $ spack spec hdf5+mpi
   ==> Error: failed to concretize `hdf5+mpi` for the following reasons:
        1. cannot satisfy a requirement for package 'mpich'.
        2. hdf5: '+mpi' conflicts with '^mpich@4.0:4.0.3'
        3. hdf5: '+mpi' conflicts with '^mpich@4.0:4.0.3'
           required because conflict is triggered when +mpi
             required because hdf5+mpi requested explicitly
           required because conflict constraint ^mpich@4.0:4.0.3
             required because mpich available as external when satisfying mpich@=4.0+hydra device=ch4 netmod=ofi
             required because hdf5+mpi requested explicitly

In this case, we cannot use the external mpich.
The version is incompatible with ``hdf5``.
At this point, the best option is to give up and let Spack build ``mpi`` for us.
The alternative is to try to find a version of ``hdf5`` which doesn't have this conflict.

By configuring most of our package preferences in ``packages.yaml``, we can cut down on the amount of work we need to do when specifying a spec on the command line.
In addition to compiler and variant preferences, we can specify version preferences as well.
Except for specifying dependencies via ``^``, anything that you can specify on the command line can be specified in ``packages.yaml`` with the exact same spec syntax.

^^^^^^^^^^^^^^^^^^^^^^^^
Installation permissions
^^^^^^^^^^^^^^^^^^^^^^^^

The ``packages`` configuration also controls the default permissions to use when installing a package.
You'll notice that by default, the installation prefix will be world-readable but only user-writable.

Let's say we need to install ``converge``, a licensed software package.
Since a specific research group, ``fluid_dynamics``, pays for this license, we want to ensure that only members of this group can access the software.
We can do this like so:

.. code-block:: yaml

   packages:
     converge:
       permissions:
         read: group
         group: fluid_dynamics


Now, only members of the ``fluid_dynamics`` group can use any ``converge`` installations.

At this point we want to discard the configuration changes we made in this tutorial section, so we can deactivate the environment:

.. code-block:: console

   $ spack env deactivate


.. warning::

   If you do not deactivate the ``config-env`` environment, then
   specs will be concretized differently in later tutorial sections
   and your results will not match.


-----------------
High-level Config
-----------------

In addition to compiler and package settings, Spack allows customization of several high-level settings.
These settings are managed in the ``config`` section (in ``config.yaml`` when stored as an individual file outside of an environment).
You can see the default settings by running:

.. code-block:: console

   $ spack config --scope defaults edit config


.. literalinclude:: _spack_root/etc/spack/defaults/config.yaml
   :language: yaml


As you can see, many of the directories Spack uses can be customized.
For example, you can tell Spack to install packages to a prefix outside of the ``$SPACK_ROOT`` hierarchy.
Module files can be written to a central location if you are using multiple Spack instances.
If you have a fast scratch file system, you can run builds from this file system with the following ``config.yaml``:

.. code-block:: yaml

   config:
     build_stage:
       - /scratch/$user/spack-stage


.. note::

   It is important to distinguish the build stage directory from other
   directories in your scratch space to ensure ``spack clean`` does not
   inadvertently remove unrelated files.  This can be accomplished by
   including a combination of ``spack`` and or ``stage`` in each path
   as shown in the default settings and documented examples.  See
   `Basic Settings <https://spack.readthedocs.io/en/latest/config_yaml.html#config-yaml>`_ for details.


On systems with compilers that absolutely *require* environment variables like ``LD_LIBRARY_PATH``, it is possible to prevent Spack from cleaning the build environment with the ``dirty`` setting:

.. code-block:: yaml

   config:
     dirty: true


However, this is strongly discouraged, as it can pull unwanted libraries into the build.

One last setting that may be of interest to many users is the ability to customize the parallelism of Spack builds.
By default, Spack installs all packages in parallel with the number of jobs equal to the number of cores on the node (up to a maximum of 16).
For example, on a node with 16 cores, this will look like:

.. code-block:: console

   $ spack install --no-cache --verbose --overwrite --yes-to-all zlib
   ==> Installing zlib
   ==> Executing phase: 'install'
   ==> './configure' '--prefix=/home/user/spack/opt/spack/linux-ubuntu22.04-x86_64/gcc-11.3.0/zlib-1.2.12-fntvsj6xevbz5gyq7kfa4xg7oxnaolxs'
   ...
   ==> 'make' '-j16'
   ...
   ==> 'make' '-j16' 'install'
   ...
   [+] /home/user/spack/opt/spack/linux-ubuntu22.04-x86_64/gcc-11.3.0/zlib-1.2.12-fntvsj6xevbz5gyq7kfa4xg7oxnaolxs


As you can see, we are building with all 16 cores on the node.
If you are on a shared login node, this can slow down the system for other users.
If you have a strict ulimit or restriction on the number of available licenses, you may not be able to build at all with this many cores.
To limit the number of cores our build uses, set ``build_jobs`` like so:

.. code-block:: console

   $ spack config edit config


.. code-block:: yaml

   config:
     build_jobs: 2


If we uninstall and reinstall zlib-ng, we see that it now uses only 2 cores:

.. code-block:: console

   $ spack install --no-cache --verbose --overwrite --yes-to-all zlib-ng
   ==> Installing zlib
   ==> Executing phase: 'install'
   ==> './configure' '--prefix=/home/user/spack/opt/spack/linux-ubuntu22.04...
   ...
   ==> 'make' '-j2'
   ...
   ==> 'make' '-j2' 'install'
   ...
   [+] /home/user/spack/opt/spack/linux-ubuntu22.04...


Obviously, if you want to build everything in serial for whatever reason, you would set ``build_jobs`` to 1.

Last, we'll unset ``concretizer:reuse:false`` since we'll want to enable concretizer reuse for the rest of this tutorial.

.. code-block:: yaml

  $ spack config rm concretizer:reuse

.. warning::

   If you do not do this step, the rest of the tutorial will not reuse binaries!

----------
Conclusion
----------

In this tutorial, we covered basic Spack configuration using ``compilers.yaml``, ``packages.yaml``, and ``config.yaml``.
Spack has many more configuration files, including ``modules.yaml``, which will be covered in the :ref:`modules-tutorial`.
For more detailed documentation on Spack's many configuration settings, see `the configuration section <https://spack.readthedocs.io/en/latest/configuration.html>`_ of Spack's main documentation.

For examples of how other sites configure Spack, see https://github.com/spack/spack-configs.
If you use Spack at your site and want to share your config files, feel free to submit a pull request!
