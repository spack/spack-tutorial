.. Copyright 2013-2019 Lawrence Livermore National Security, LLC and other
   Spack Project Developers. See the top-level COPYRIGHT file for details.

   SPDX-License-Identifier: (Apache-2.0 OR MIT)

.. _configs-tutorial:

======================
Configuration Tutorial
======================

This tutorial will guide you through various configuration options
that allow you to customize Spack's behavior with respect to
software installation. We will first cover the configuration file
hierarchy. Then, we will cover configuration options for compilers,
focusing on how they can be used to extend Spack's compiler auto-detection.
Next, we will cover the packages configuration file, focusing on
how it can be used to override default build options as well as
specify external package installations to use. Finally, we will
briefly touch on the config configuration file, which manages more
high-level Spack configuration options.

For all of these features, we will demonstrate how we build up a full
configuration file. For some, we will then demonstrate how the
configuration affects the install command, and for others we will use
the ``spack spec`` command to demonstrate how the configuration
changes have affected Spack's concretization algorithm. The provided
output is all from a server running Ubuntu version 18.04.

.. _configs-tutorial-scopes:

--------------------
Configuration Scopes
--------------------

Depending on your use case, you may want to provide configuration
settings common to everyone on your team, or you may want to set
default behaviors specific to a single user account. Spack provides
six configuration *scopes* to handle this customization. These scopes,
in order of decreasing priority, are:

============   ===================================================
Scope          Directory
============   ===================================================
Command-line   N/A
Custom         Custom directory, specified with ``--config-scope``
User           ``~/.spack/``
Site           ``$SPACK_ROOT/etc/spack/``
System         ``/etc/spack/``
Defaults       ``$SPACK_ROOT/etc/spack/defaults/``
============   ===================================================

Spack's default configuration settings reside in
``$SPACK_ROOT/etc/spack/defaults``. These are useful for reference,
but should never be directly edited. To override these settings,
create new configuration files in any of the higher-priority
configuration scopes.

A particular cluster may have multiple Spack installations associated
with different projects. To provide settings common to all Spack
installations, put your configuration files in ``/etc/spack``.
To provide settings specific to a particular Spack installation,
you can use the ``$SPACK_ROOT/etc/spack`` directory.

For settings specific to a particular user, you will want to add
configuration files to the ``~/.spack`` directory. When Spack first
checked for compilers on your system, you may have noticed that it
placed your compiler configuration in this directory.

Configuration settings can also be placed in a custom location,
which is then specified on the command line via ``--config-scope``.
An example use case is managing two sets of configurations, one for
development and another for production preferences.

Settings specified on the command line have precedence over all
other configuration scopes.

You can also use ``spack config blame <config>`` for displaying
the effective configuration. Spack will show from which scopes
the configuration has been assembled.

^^^^^^^^^^^^^^^^^^^^^^^^
Platform-specific scopes
^^^^^^^^^^^^^^^^^^^^^^^^

Some facilities manage multiple platforms from a single shared
file system. In order to handle this, each of the configuration
scopes listed above has two *sub-scopes*: platform-specific and
platform-independent. For example, compiler settings can be stored
in ``compilers.yaml`` configuration files in the following locations:

#. ``~/.spack/<platform>/compilers.yaml``
#. ``~/.spack/compilers.yaml``
#. ``$SPACK_ROOT/etc/spack/<platform>/compilers.yaml``
#. ``$SPACK_ROOT/etc/spack/compilers.yaml``
#. ``/etc/spack/<platform>/compilers.yaml``
#. ``/etc/spack/compilers.yaml``
#. ``$SPACK_ROOT/etc/defaults/<platform>/compilers.yaml``
#. ``$SPACK_ROOT/etc/defaults/compilers.yaml``

These files are listed in decreasing order of precedence, so files in
``~/.spack/<platform>`` will override settings in ``~/.spack``.

-----------
YAML Format
-----------

Spack configurations are YAML dictionaries. Every configuration file
begins with a top-level dictionary that tells Spack which
configuration set it modifies. When Spack checks its configuration,
the configuration scopes are updated as dictionaries in increasing
order of precedence, allowing higher precedence files to override
lower. YAML dictionaries use a colon ":" to specify key-value
pairs. Spack extends YAML syntax slightly to allow a double-colon
"::" to specify a key-value pair. When a double-colon is used,
instead of adding that section, Spack replaces what was in that
section with the new value. For example, consider a user's compilers
configuration file as follows:

.. code-block:: yaml

   compilers::
   - compiler:
       spec: gcc@7.5.0
       paths:
         cc: /usr/bin/gcc
         cxx: /usr/bin/g++
         f77: /usr/bin/gfortran
         fc: /usr/bin/gfortran
       flags: {}
       operating_system: ubuntu18.04
       target: x86_64
       modules: []
       environment: {}
       extra_rpaths: []


This ensures that no other compilers are used, as the user configuration
scope is the last scope searched and the ``compilers::`` line replaces
all previous configuration files information. If the same
configuration file had a single colon instead of the double colon, it
would add the GCC version 7.5.0 compiler to whatever other compilers
were listed in other configuration files.

.. _configs-tutorial-compilers:

----------------------
Compiler Configuration
----------------------

For most tasks, we can use Spack with the compilers auto-detected the
first time Spack runs on a system. As discussed in the basic
installation tutorial, we can also tell Spack where compilers are
located using the ``spack compiler add`` command. However, in some
circumstances we want even more fine-grained control over the
compilers available. This section will teach you how to exercise that
control using the compilers configuration file.

We will start by opening the compilers configuration file:

.. code-block:: console

   $ spack config edit compilers


.. code-block:: yaml

   compilers:
   - compiler:
       spec: clang@6.0.0
       paths:
         cc: /usr/bin/clang-6.0
         cxx: /usr/bin/clang++-6.0
         f77:
         fc:
       flags: {}
       operating_system: ubuntu18.04
       target: x86_64
       modules: []
       environment: {}
       extra_rpaths: []
   - compiler:
       spec: gcc@6.5.0
       paths:
         cc: /usr/bin/gcc-6
         cxx:
         f77:
         fc:
       flags: {}
       operating_system: ubuntu18.04
       target: x86_64
       modules: []
       environment: {}
       extra_rpaths: []
   - compiler:
       spec: gcc@7.5.0
       paths:
         cc: /usr/bin/gcc-7
         cxx: /usr/bin/g++-7
         f77: /usr/bin/gfortran-7
         fc: /usr/bin/gfortran-7
       flags: {}
       operating_system: ubuntu18.04
       target: x86_64
       modules: []
       environment: {}
       extra_rpaths: []

This specifies two versions of the GCC compiler and one version of the
Clang compiler with no Flang compiler. Now suppose we have a code that
we want to compile with the Clang compiler for C/C++ code, but with
gfortran for Fortran components. We can do this by adding another entry
to the ``compilers.yaml`` file:

.. code-block:: yaml
   :emphasize-lines: 2,6-7

   - compiler:
       spec: clang@6.0.0-gfortran
       paths:
         cc: /usr/bin/clang-6.0
         cxx: /usr/bin/clang++-6.0
         f77: /usr/bin/gfortran-7
         fc: /usr/bin/gfortran-7
       flags: {}
       operating_system: ubuntu18.04
       target: x86_64
       modules: []
       environment: {}
       extra_rpaths: []


Let's talk about the sections of this compiler entry that we've changed.
The biggest change we've made is to the ``paths`` section. This lists
the paths to the compilers to use for each language/specification.
In this case, we point to the Clang compiler for C/C++ and the gfortran
compiler for both specifications of Fortran. We've also changed the
``spec`` entry for this compiler. The ``spec`` entry is effectively the
name of the compiler for Spack. It consists of a name and a version
number, separated by the ``@`` sigil. The name must be one of the supported
compiler names in Spack (arm, cce, clang, fj, gcc, intel, nag, pgi, xl, xl_r).
The version number can be an arbitrary string of alphanumeric characters,
as well as ``-``, ``.``, and ``_``. The ``target`` and ``operating_system``
sections we leave unchanged. These sections specify when Spack can use
different compilers, and are primarily useful for configuration files that
will be used across multiple systems.

We can verify that our new compiler works by invoking it now:

.. code-block:: console

   $ spack install --no-cache zlib %clang@6.0.0-gfortran
   ...


This new compiler also works on Fortran codes. We'll show it by
compiling a small package using as a build dependency ``cmake%gcc@7.5.0``
since it is already available in our binary cache:

.. code-block:: console

   $ spack install cmake %gcc@7.5.0
   ...
   $ spack install --no-cache json-fortran %clang@6.0.0-gfortran ^cmake%gcc@7.5.0
   ...


^^^^^^^^^^^^^^
Compiler flags
^^^^^^^^^^^^^^

Some compilers may require specific compiler flags to work properly in
a particular computing environment. Spack provides configuration
options for setting compiler flags every time a specific compiler is
invoked. These flags become part of the package spec and therefore of
the build provenance. As on the command line, the flags are set
through the implicit build variables ``cflags``, ``cxxflags``, ``cppflags``,
``fflags``, ``ldflags``, and ``ldlibs``.

Let's open our compilers configuration file again and add a compiler flag:

.. code-block:: yaml
   :emphasize-lines: 8-9

   - compiler:
       spec: clang@6.0.0-gfortran
       paths:
         cc: /usr/bin/clang-6.0
         cxx: /usr/bin/clang++-6.0
         f77: /usr/bin/gfortran-7
         fc: /usr/bin/gfortran-7
       flags:
         cppflags: -g
       operating_system: ubuntu18.04
       target: x86_64
       modules: []
       environment: {}
       extra_rpaths: []


We can test this out using the ``spack spec`` command to show how the
spec is concretized:

.. literalinclude:: outputs/config/0.compiler_flags.out
   :language: console


We can see that ``cppflags="-g"`` has been added to every node in the DAG.

^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
Advanced compiler configuration
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

There are three fields of the compiler configuration entry that we
have not yet talked about.

The ``modules`` field of the compiler is used primarily on Cray systems,
but can be useful on any system that has compilers that are only
useful when a particular module is loaded. Any modules in the
``modules`` field of the compiler configuration will be loaded as part
of the build environment for packages using that compiler:

.. code-block:: yaml

   - compiler:
       ...
       modules:
       - PrgEnv-gnu
       - gcc/5.3.0
       ...

The ``environment`` field of the compiler configuration is used for
compilers that require environment variables to be set during build
time. For example, if your Intel compiler suite requires the
``INTEL_LICENSE_FILE`` environment variable to point to the proper
license server, you can set this in ``compilers.yaml`` as follows:

.. code-block:: yaml

   - compiler:
       ...
       environment:
         set:
           INTEL_LICENSE_FILE: 1713@license4
       ...


In addition to ``set``, ``environment`` also supports ``unset``,
``prepend_path``, and ``append_path``.

The ``extra_rpaths`` field of the compiler configuration is used for
compilers that do not rpath all of their dependencies by
default. Since compilers are often installed externally to Spack,
Spack is unable to manage compiler dependencies and enforce
rpath usage. This can lead to packages not finding link dependencies
imposed by the compiler properly. For compilers that impose link
dependencies on the resulting executables that are not rpath'ed into
the executable automatically, the ``extra_rpaths`` field of the compiler
configuration tells Spack which dependencies to rpath into every
executable created by that compiler. The executables will then be able
to find the link dependencies imposed by the compiler. As an example,
this field can be set by:

.. code-block:: yaml

   - compiler:
       ...
       extra_rpaths:
       - /apps/intel/ComposerXE2017/compilers_and_libraries_2017.5.239/linux/compiler/lib/intel64_lin
       ...


.. _configs-tutorial-package-prefs:

-------------------------------
Configuring Package Preferences
-------------------------------

Package preferences in Spack are managed through the ``packages.yaml``
configuration file. First, we will look at the default
``packages.yaml`` file.

.. code-block:: console

   $ spack config --scope defaults edit packages


.. literalinclude:: _spack_root/etc/spack/defaults/packages.yaml
   :language: yaml
   :emphasize-lines: 18,37


This sets the default preferences for compilers and for providers of
virtual dependencies. To illustrate how this works, suppose we want to
change the preferences to prefer the Clang compiler and to prefer
MPICH over OpenMPI. Currently, we prefer GCC and OpenMPI.

.. literalinclude:: outputs/config/0.prefs.out
   :language: console
   :emphasize-lines: 9


Now we will open the packages configuration file and update our
preferences.

.. code-block:: console

   $ spack config edit packages


.. code-block:: yaml

   packages:
     all:
       compiler: [clang, gcc, intel, pgi, xl, nag, fj]
       providers:
         mpi: [mpich, openmpi]


Because of the configuration scoping we discussed earlier, this
overrides the default settings just for these two items.

.. literalinclude:: outputs/config/1.prefs.out
   :language: console
   :emphasize-lines: 9


^^^^^^^^^^^^^^^^^^^
Variant preferences
^^^^^^^^^^^^^^^^^^^

The packages configuration file can also set variant preferences for
package variants. For example, let's change our preferences to build all
packages without shared libraries. We will accomplish this by turning
off the ``shared`` variant on all packages that have one.

.. code-block:: yaml
   :emphasize-lines: 6

   packages:
     all:
       compiler: [clang, gcc, intel, pgi, xl, nag]
       providers:
         mpi: [mpich, openmpi]
       variants: ~shared


We can check the effect of this command with ``spack spec hdf5`` again.

.. literalinclude:: outputs/config/2.prefs.out
   :language: console
   :emphasize-lines: 8,13,22,28


So far we have only made global changes to the package preferences. As
we've seen throughout this tutorial, HDF5 builds with MPI enabled by
default in Spack. If we were working on a project that would routinely
need serial HDF5, that might get annoying quickly, having to type
``hdf5~mpi`` all the time. Instead, we'll update our preferences for
HDF5.

.. code-block:: yaml
   :emphasize-lines: 7-8

   packages:
     all:
       compiler: [clang, gcc, intel, pgi, xl, nag]
       providers:
         mpi: [mpich, openmpi]
       variants: ~shared
     hdf5:
       variants: ~mpi


Now hdf5 will concretize without an MPI dependency by default.

.. literalinclude:: outputs/config/3.prefs.out
   :language: console
   :emphasize-lines: 8


In general, every attribute that we can set for all packages we can
set separately for an individual package.

^^^^^^^^^^^^^^^^^
External packages
^^^^^^^^^^^^^^^^^

The packages configuration file also controls when Spack will build
against an externally installed package. Spack has a
``spack external find`` command that can automatically discover and
register externally installed packages. This works for many common
build dependencies, but it's also important to know how to do this
manually for packages that Spack cannot yet detect.

On these systems we have a pre-installed zlib. Let's tell Spack about
this package and where it can be found:

.. code-block:: yaml
   :emphasize-lines: 9-11

   packages:
     all:
       compiler: [clang, gcc, intel, pgi, xl, nag]
       providers:
         mpi: [mpich, openmpi]
       variants: ~shared
     hdf5:
       variants: ~mpi
     zlib:
       paths:
         zlib@1.2.8%gcc@7.5.0: /usr


Here, we've told Spack that zlib 1.2.8 is installed on our system.
We've also told it the installation prefix where zlib can be found.
We don't know exactly which variants it was built with, but that's
okay.

.. literalinclude:: outputs/config/0.externals.out
   :language: console


You'll notice that Spack is now using the external zlib installation,
but the compiler used to build zlib is now overriding our compiler
preference of clang. If we explicitly specify Clang:

.. literalinclude:: outputs/config/1.externals.out
   :language: console

Spack concretizes to both HDF5 and zlib being built with Clang.
This has a side-effect of rebuilding zlib. If we want to force
Spack to use the system zlib, we have two choices. We can either
specify it on the command line, or we can tell Spack that it's
not allowed to build its own zlib. We'll go with the latter.

.. code-block:: yaml
   :emphasize-lines: 12

   packages:
     all:
       compiler: [clang, gcc, intel, pgi, xl, nag]
       providers:
         mpi: [mpich, openmpi]
       variants: ~shared
     hdf5:
       variants: ~mpi
     zlib:
       paths:
         zlib@1.2.8%gcc@7.5.0: /usr
       buildable: false


Now Spack will be forced to choose the external zlib.

.. literalinclude:: outputs/config/2.externals.out
   :language: console


This gets slightly more complicated with virtual dependencies. Suppose
we don't want to build our own MPI, but we now want a parallel version
of HDF5. Well, fortunately we have MPICH installed on these systems.

.. code-block:: yaml
   :emphasize-lines: 13-16

   packages:
     all:
       compiler: [clang, gcc, intel, pgi, xl, nag]
       providers:
         mpi: [mpich, openmpi]
       variants: ~shared
     hdf5:
       variants: ~mpi
     zlib:
       paths:
         zlib@1.2.8%gcc@7.5.0: /usr
       buildable: false
     mpich:
       paths:
         mpich@3.3%gcc@7.5.0: /usr
       buildable: false


If we concretize ``hdf5+mpi`` with this configuration file, we will just
build with an alternate MPI implementation.

.. literalinclude:: outputs/config/3.externals.out
   :language: console
   :emphasize-lines: 9

We have only expressed a preference for MPICH over other MPI
implementations, and Spack will happily build with one we haven't
forbidden it from building. We could resolve this by requesting
``hdf5+mpi%clang^mpich`` explicitly, or we can configure Spack not to
use any other MPI implementation. Since we're focused on
configurations here and the former can get tedious, we'll need to
modify our ``packages.yaml`` file again.

While we're at it, we can configure HDF5 to build with MPI by default
again.

.. code-block:: yaml
   :emphasize-lines: 14-15

   packages:
     all:
       compiler: [clang, gcc, intel, pgi, xl, nag]
       providers:
         mpi: [mpich, openmpi]
       variants: ~shared
     zlib:
       paths:
         zlib@1.2.8%gcc@7.5.0: /usr
       buildable: false
     mpich:
       paths:
         mpich@3.3%gcc@7.5.0: /usr
     mpi:
       buildable: False


Now that we have configured Spack not to build any possible provider
for MPI, we can try again.

.. literalinclude:: outputs/config/4.externals.out
   :language: console
   :emphasize-lines: 9


By configuring most of our package preferences in ``packages.yaml``,
we can cut down on the amount of work we need to do when specifying
a spec on the command line. In addition to compiler and variant
preferences, we can specify version preferences as well. Except for
specifying dependencies via ``^``, anything that you can specify on the
command line can be specified in ``packages.yaml`` with the exact
same spec syntax.

^^^^^^^^^^^^^^^^^^^^^^^^
Installation permissions
^^^^^^^^^^^^^^^^^^^^^^^^

The ``packages.yaml`` file also controls the default permissions
to use when installing a package. You'll notice that by default,
the installation prefix will be world-readable but only user-writable.

Let's say we need to install ``converge``, a licensed software package.
Since a specific research group, ``fluid_dynamics``, pays for this
license, we want to ensure that only members of this group can access
the software. We can do this like so:

.. code-block:: yaml

   packages:
     converge:
       permissions:
         read: group
         group: fluid_dynamics


Now, only members of the ``fluid_dynamics`` group can use any
``converge`` installations.

.. warning::

   Make sure to delete or move the ``packages.yaml`` you have been
   editing up to this point. Otherwise, it will change the hashes
   of your packages, leading to differences in the output of later
   tutorial sections.


-----------------
High-level Config
-----------------

In addition to compiler and package settings, Spack allows customization
of several high-level settings. These settings are stored in the generic
``config.yaml`` configuration file. You can see the default settings by
running:

.. code-block:: console

   $ spack config --scope defaults edit config


.. literalinclude:: _spack_root/etc/spack/defaults/config.yaml
   :language: yaml


As you can see, many of the directories Spack uses can be customized.
For example, you can tell Spack to install packages to a prefix
outside of the ``$SPACK_ROOT`` hierarchy. Module files can be
written to a central location if you are using multiple Spack
instances. If you have a fast scratch file system, you can run builds
from this file system with the following ``config.yaml``:

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


On systems with compilers that absolutely *require* environment variables
like ``LD_LIBRARY_PATH``, it is possible to prevent Spack from cleaning
the build environment with the ``dirty`` setting:

.. code-block:: yaml

   config:
     dirty: true


However, this is strongly discouraged, as it can pull unwanted libraries
into the build.

One last setting that may be of interest to many users is the ability
to customize the parallelism of Spack builds. By default, Spack
installs all packages in parallel with the number of jobs equal to the
number of cores on the node (up to a maximum of 16). For example, on a
node with 16 cores, this will look like:

.. code-block:: console

   $ spack install --no-cache --verbose --overwrite zlib
   ==> Installing zlib
   ==> Executing phase: 'install'
   ==> './configure' '--prefix=/home/user/spack/opt/spack/linux-ubuntu18.04-x86_64/gcc-7.5.0/zlib-1.2.11-smoyzzo2qhzpn6mg6rd3l2p7b23enshg'
   ...
   ==> 'make' '-j16'
   ...
   ==> 'make' '-j16' 'install'
   ...
   [+] /home/user/spack/opt/spack/linux-ubuntu18.04-x86_64/gcc-7.5.0/zlib-1.2.11-smoyzzo2qhzpn6mg6rd3l2p7b23enshg


As you can see, we are building with all 16 cores on the node. If you are
on a shared login node, this can slow down the system for other users. If
you have a strict ulimit or restriction on the number of available licenses,
you may not be able to build at all with this many cores. To limit the
number of cores our build uses, set ``build_jobs`` like so:

.. code-block:: yaml

   config:
     build_jobs: 2


If we uninstall and reinstall zlib, we see that it now uses only 2 cores:

.. code-block:: console

   $ spack install --no-cache --verbose --overwrite zlib
   ==> Installing zlib
   ==> Executing phase: 'install'
   ==> './configure' '--prefix=/home/user/spack/opt/spack/linux-ubuntu18.04-x86_64/gcc-7.5.0/zlib-1.2.11-smoyzzo2qhzpn6mg6rd3l2p7b23enshg'
   ...
   ==> 'make' '-j2'
   ...
   ==> 'make' '-j2' 'install'
   ...
   [+] /home/user/spack/opt/spack/linux-ubuntu18.04-x86_64/gcc-7.5.0/zlib-1.2.11-smoyzzo2qhzpn6mg6rd3l2p7b23enshg


Obviously, if you want to build everything in serial for whatever reason,
you would set ``build_jobs`` to 1.

--------
Examples
--------

For examples of how other sites configure Spack, see
https://github.com/spack/spack-configs. If you use Spack at your site
and want to share your config files, feel free to submit a pull request!
