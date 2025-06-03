.. Copyright Spack Project Developers. See COPYRIGHT file for details.

   SPDX-License-Identifier: (Apache-2.0 OR MIT)

.. include:: common/setup.rst

.. _build-systems-tutorial:

===========================
Spack Package Build Systems
===========================

After writing a few package template files, certain recurring patterns often become apparent.  
For example, an ``install()`` method may frequently include the following steps:

- ``configure``
- ``cmake``
- ``make``
- ``make install``

It's also common to pass arguments such as ``"prefix=" + prefix`` to ``configure`` or ``cmake``.

To avoid repeating this logic across packages, Spack provides specialized build system base classes that encapsulate these common patterns.  
These classes help reduce boilerplate while still offering fine-grained control over the build process when needed.

In this section, we'll describe several of these build systems and show how they can be used to simplify and streamline package creation.


-----------------------
Package Class Hierarchy
-----------------------

.. graphviz::

    digraph G {

        node [
            shape = "record"
        ]
        edge [
            arrowhead = "empty"
        ]

        PackageBase -> Package [dir=back]
        PackageBase -> MakefilePackage [dir=back]
        PackageBase -> AutotoolsPackage [dir=back]
        PackageBase -> CMakePackage [dir=back]
        PackageBase -> PythonPackage [dir=back]
    }

The diagram above provides a high-level view of the class hierarchy and how each package class relates to the others.  
Each build system specific class inherits from the ``PackageBase`` superclass.

The bulk of the common functionality, such as fetching sources, extracting them into a staging directory, and managing the install process, is implemented in the superclass.
Each subclass then extends this base with build system specific behavior and logic.

In the following sections, we'll explore examples of how to use these subclasses in practice and demonstrate how powerful these abstractions can be when writing package definitions.


-----------------
Package
-----------------

We've already seen examples of using the generic ``Package`` class in our walkthrough for writing package files, so we won't be spending much time with it here.
Briefly, the ``Package`` class allows for arbitrary control over the build process, whereas subclasses rely on certain patterns (e.g. ``configure`` ``make`` ``make install``) to be useful.
The generic ``Package`` class is particularly useful for packages that have an unconventional build process, as it allows the packager to use Spack's helper functions to customize the building and installing of a package.

-------------------
Autotools
-------------------

As we've seen earlier, ``Autotools`` packages use ``configure``, ``make`` and ``make install`` commands to execute the build and install process.
In our ``Package`` class, typical build steps would consist of the following:

.. code-block:: python

    def install(self, spec, prefix):
        configure("--prefix=" + prefix)
        make()
        make("install")

We'll see that this looks similar to what we wrote in our packaging tutorial.

The ``AutotoolsPackage`` subclass aims to simplify writing package files for Autotools-based software and provides convenient methods to manipulate each of the different phases for an ``Autotools`` build system.

``AutotoolsPackage`` builds consist of four main phases, each cooresponding to a method that can be overridden:

1. ``autoreconf()``
2. ``configure()``
3. ``build()``
4. ``install()``


Each of these phases has sensible defaults.
Let's take a quick look at some of the internals of the ``Autotools`` class:

.. code-block:: console

    $ spack edit --build-system autotools


This will open the ``AutotoolsPackage`` file in the text editor.

.. note::
    The examples showing code for these classes are abridged to avoid having
    long examples. We only show what is relevant to the packager.


.. literalinclude:: _spack_root/lib/spack/spack/build_systems/autotools.py
    :emphasize-lines: 2,4,28-37
    :lines: 138-158,589-617
    :linenos:


Important to note are the highlighted lines.
These properties allow the packager to set build and install targets for their package.
If we wanted to add ``foo`` as our build target, then we can append to our ``build_targets`` list.

.. code-block:: python

    build_targets = ["foo"]

Which is similar to invoking ``make`` in our Package

.. code-block:: python

     make("foo")

This is useful if we have packages that ignore environment variables and need a command line argument.

Another thing to take note of is in the ``configure()`` method in ``AutotoolsPackage``.
Here we see that the ``--prefix`` argument is already included since it is a common pattern among ``Autotools`` packages.
Therefore, we typically only need to override the ``configure_args()`` method to return a list of additional arguments.
The ``configure()`` method will then append these to the standard arguments.

Packagers also have the option to run ``autoreconf`` in case a package needs to update the build system and generate a new ``configure``.
However, this is typically not necessary.

Let's look at the ``mpileaks`` package.py file we worked on earlier:

.. code-block:: console

    $ spack edit mpileaks

Notice that mpileaks was originally written as a generic ``Package``, but uses the ``Autotools`` build system.
While this would build successfully, let's use the ``AutotoolsPackage`` class to simplify it further.

.. literalinclude:: tutorial/examples/Autotools/0.package.py
   :language: python
   :emphasize-lines: 9
   :linenos:

We first inherit from the ``AutotoolsPackage`` class.


We could keep the ``install()`` method, but most of it can be handled by the ``AutotoolsPackage`` base class.
In fact, the only thing that needs to be overridden is ``configure_args()``.

.. literalinclude:: tutorial/examples/Autotools/1.package.py
   :language: python
   :emphasize-lines: 25,26,27,28,29,30,31,32
   :linenos:

Since Spack's ``AutotoolsPackage`` sets the prefix, we can exclude that as an argument to ``configure``.
Our package file looks simpler, and we don't need to worry about whether we have properly included ``configure`` and ``make``.

This version of the ``mpileaks`` package installs the same as the generic package class, but the ``AutotoolsPackage`` class allows us to leverage powerful abstractions, resulting in a simpler recipe.

-----------------
Makefile
-----------------

Packages that use ``make`` often require editing the Makefile to configure platform or compiler-specific variables.
These packages are handled by the ``MakefilePackage`` subclass, which provides convenience methods to write package definitions.

A ``MakefilePackage`` build has three phases that can be overridden by the packager:

    1. ``edit()``
    2. ``build()``
    3. ``install()``

Packagers then have the ability to control how a ``Makefile`` is edited, and the targets to include for the build or install phase.

Let's take a look inside the ``MakefilePackage`` class:

.. code-block:: console

    $ spack edit --build-system makefile

Take note of the following:


.. literalinclude:: _spack_root/lib/spack/spack/build_systems/makefile.py
   :language: python
   :emphasize-lines: 60,64,69
   :lines: 40-111
   :linenos:

Similar to ``Autotools``, the ``MakefilePackage`` class has properties that can be set by the packager.
We can also override the different methods highlighted.


Let's try to recreate the Bowtie_ package:

.. _Bowtie: http://bowtie-bio.sourceforge.net/index.shtml


.. code-block:: console

    $ spack create -f https://downloads.sourceforge.net/project/bowtie-bio/bowtie/1.2.1.1/bowtie-1.2.1.1-src.zip
    ==> This looks like a URL for bowtie
    ==> Found 1 version of bowtie:

    1.2.1.1  https://downloads.sourceforge.net/project/bowtie-bio/bowtie/1.2.1.1/bowtie-1.2.1.1-src.zip

    ==> How many would you like to checksum? (default is 1, q to abort) 1
    ==> Downloading...
    ==> Fetching https://downloads.sourceforge.net/project/bowtie-bio/bowtie/1.2.1.1/bowtie-1.2.1.1-src.zip
    ######################################################################## 100.0%
    ==> Checksummed 1 version of bowtie
    ==> This package looks like it uses the makefile build system
    ==> Created template for bowtie package
    ==> Created package file: /Users/mamelara/spack/var/spack/repos/builtin/packages/bowtie/package.py

Once the fetching is complete, Spack will open a text editor in the usual fashion and create a template of a ``MakefilePackage`` package.py.

.. literalinclude:: tutorial/examples/Makefile/0.package.py
   :language: python
   :linenos:

Spack successfully detected that ``Bowtie`` uses ``Makefiles``.
Let's add in the rest of the package's details:

.. literalinclude:: tutorial/examples/Makefile/1.package.py
   :language: python
   :emphasize-lines: 10,11,13,14,18,20
   :linenos:

As previously mentioned, most packages that use a ``Makefile`` include hardcoded variables that must be edited.  
While this setup may be sufficient for basic use cases, it is often inflexible, especially when different compilers or build configurations are required.  
Spack is designed to support a wide range of compilers and platforms, and the ``MakefilePackage`` subclass helps accommodate that flexibility.

The ``MakefilePackage`` class simplifies the process of editing ``Makefiles`` through its overridable ``edit()`` method, which provides a hook for making in-place changes before the build begins.

As an example, consider the default ``Makefile`` provided with ``Bowtie``.  
Inspecting its contents reveals that ``CC`` and ``CXX`` are hardcoded to the GNU compilers:

.. code-block:: console

    $ spack stage bowtie

.. note::
   Ensure Spack's shell support is active before running staging or build commands:  
   ``source /path/to/spack/share/spack/setup-env.sh``

.. code-block:: console

    $ spack cd -s bowtie
    $ cd spack-src
    $ vim Makefile


.. code-block:: make

    CPP = g++ -w
    CXX = $(CPP)
    CC = gcc
    LIBS = $(LDFLAGS) -lz
    HEADERS = $(wildcard *.h)

To fix this, we need to use the ``edit()`` method to modify the ``Makefile``.

.. literalinclude:: tutorial/examples/Makefile/2.package.py
   :language: python
   :emphasize-lines: 23,24,25
   :linenos:

Here we use a ``FileFilter`` object (a Spack utility) to edit our ``Makefile``.
It takes a regular expression to find lines (e.g., assignments to ``CC`` and ``CXX``) and then replaces them with values derived from Spack's build environment (e.g., ``self.compiler.cc`` and ``self.compiler.cxx``).
This allows us to build ``Bowtie`` with the compiler specified via Spack's spec syntax.

Let's change the build and install phases of our package:

.. literalinclude:: tutorial/examples/Makefile/3.package.py
   :language: python
   :emphasize-lines: 28,29,30,31,32,35,36
   :linenos:

Here we demonstrate another strategy we can use to manipulate our package's build.
We can provide command line arguments to ``make()``.
Since ``Bowtie`` can use ``tbb`` we can either add ``NO_TBB=1`` as a argument to prevent ``tbb`` support, or we can invoke ``make`` with no arguments if TBB is desired and found by its build system.

``Bowtie`` requires our ``install_target`` to provide a path to the install directory.
We can do this by providing ``prefix=`` as a command line argument to ``make()``.

Let's look at a couple of other examples and go through them:

.. code-block:: console

    $ spack edit esmf

Some packages allow environment variables to be set and will honor them.
Packages that use ``?=`` for assignment in their ``Makefile`` can be set using environment variables.
In our ``esmf`` example we set two environment variables in our ``edit()`` method:

.. code-block:: python

    def edit(self, spec, prefix):
        for var in os.environ:
            if var.startswith('ESMF_'):
                os.environ.pop(var)

        # More code ...

        if self.compiler.name == 'gcc':
            os.environ['ESMF_COMPILER'] = 'gfortran'
        elif self.compiler.name == 'intel':
            os.environ['ESMF_COMPILER'] = 'intel'
        elif self.compiler.name == 'clang':
            os.environ['ESMF_COMPILER'] = 'gfortranclang'
        elif self.compiler.name == 'nag':
            os.environ['ESMF_COMPILER'] = 'nag'
        elif self.compiler.name == 'pgi':
            os.environ['ESMF_COMPILER'] = 'pgi'
        else:
            msg  = "The compiler you are building with, "
            msg += "'{0}', is not supported by ESMF."
            raise InstallError(msg.format(self.compiler.name))

In this example, nothing was written directly to the Makefile. Instead, environment variables were set to override those defined within the Makefile.

Some packages include a configuration file that sets certain compiler variables, platform specific variables, and the location of dependencies or libraries.
If the file is simple and only requires a couple changes, we can replace those entries with our ``FileFilter`` object.
If the changes will be more complex, we can write a new configuration file from scratch within the ``edit()`` method.

Let's look at an example of this in the ``elk`` package:

.. code-block:: console

    $ spack edit elk

.. code-block:: python

        def edit(self, spec, prefix):
            # Dictionary of configuration options
            config = {
                'MAKE': 'make',
                'AR':   'ar'
            }

            # Compiler-specific flags
            flags = ''
            if self.compiler.name == 'intel':
                flags = '-O3 -ip -unroll -no-prec-div'
            elif self.compiler.name == 'gcc':
                flags = '-O3 -ffast-math -funroll-loops'
            elif self.compiler.name == 'pgi':
                flags = '-O3 -lpthread'
            elif self.compiler.name == 'g95':
                flags = '-O3 -fno-second-underscore'
            elif self.compiler.name == 'nag':
                flags = '-O4 -kind=byte -dusty -dcfuns'
            elif self.compiler.name == 'xl':
                flags = '-O3'
            config['F90_OPTS'] = flags
            config['F77_OPTS'] = flags

            # BLAS/LAPACK support
            # Note: BLAS/LAPACK must be compiled with OpenMP support
            # if the +openmp variant is chosen
            blas = 'blas.a'
            lapack = 'lapack.a'
            if '+blas' in spec:
                blas = spec['blas'].libs.joined()
            if '+lapack' in spec:
                lapack = spec['lapack'].libs.joined()
            # lapack must come before blas
            config['LIB_LPK'] = ' '.join([lapack, blas])

            # FFT support
            if '+fft' in spec:
                config['LIB_FFT'] = join_path(spec['fftw'].prefix.lib,
                                            'libfftw3.so')
                config['SRC_FFT'] = 'zfftifc_fftw.f90'
            else:
                config['LIB_FFT'] = 'fftlib.a'
                config['SRC_FFT'] = 'zfftifc.f90'

            # MPI support
            if '+mpi' in spec:
                config['F90'] = spec['mpi'].mpifc
                config['F77'] = spec['mpi'].mpif77
            else:
                config['F90'] = spack_fc
                config['F77'] = spack_f77
                config['SRC_MPI'] = 'mpi_stub.f90'

            # OpenMP support
            if '+openmp' in spec:
                config['F90_OPTS'] += ' ' + self.compiler.openmp_flag
                config['F77_OPTS'] += ' ' + self.compiler.openmp_flag
            else:
                config['SRC_OMP'] = 'omp_stub.f90'

            # Libxc support
            if '+libxc' in spec:
                config['LIB_libxc'] = ' '.join([
                    join_path(spec['libxc'].prefix.lib, 'libxcf90.so'),
                    join_path(spec['libxc'].prefix.lib, 'libxc.so')
                ])
                config['SRC_libxc'] = ' '.join([
                    'libxc_funcs.f90',
                    'libxc.f90',
                    'libxcifc.f90'
                ])
            else:
                config['SRC_libxc'] = 'libxcifc_stub.f90'

            # Write configuration options to include file
            with open('make.inc', 'w') as inc:
                for key in config:
                    inc.write('{0} = {1}\n'.format(key, config[key]))

``config`` is just a Python dictionary that we populate with key-value pairs.
By the end of the ``edit()`` method, we write the contents of our dictionary to the ``make.inc`` file, which the package's ``Makefile`` then includes.

---------------
CMake
---------------

CMake_ is another popular build system.
It works in a similar manner to ``Autotools`` but with differences in variable names, configuration options, and handling of shared libraries.
Typical build steps look like this:

.. _CMake: https://cmake.org

.. code-block:: python

    def install(self, spec, prefix):
        cmake("-DCMAKE_INSTALL_PREFIX:PATH=/path/to/install_dir ..")
        make()
        make("install")

As shown in the example above, the process is very similar to invoking ``configure`` and ``make`` in an ``Autotools`` build system.
However, the variable names and options differ.
Most options in CMake are prefixed with a ``'-D'`` flag to indicate a configuration setting.

In the ``CMakePackage`` class, we can override the following build phases:

1. ``cmake()``
2. ``build()``
3. ``install()``

The ``CMakePackage`` class provides sensible defaults, so we only need to override ``cmake_args()`` to pass package-specific options.

Let's look at these defaults in the ``_std_args()`` method of the ``CMakePackage`` class.

.. code-block:: console

    $ spack edit --build-system cmake

.. literalinclude:: _spack_root/lib/spack/spack/build_systems/cmake.py
   :language: python
   :lines: 167-300
   :emphasize-lines: 87,96
   :linenos:

Some ``CMake`` packages use different generators.
Spack is able to support Unix-Makefile_ generators as well as Ninja_ generators.

.. _Unix-Makefile: https://cmake.org/cmake/help/latest/generator/Unix%20Makefiles.html
.. _Ninja: https://cmake.org/cmake/help/latest/generator/Ninja.html

If no generator is specified, Spack will default to ``Unix Makefiles``.

Next, we'll set up the build type.
In ``CMake``, we can specify the build type.
Options include:

1. ``empty``
2. ``Debug``
3. ``Release``
4. ``RelWithDebInfo``
5. ``MinSizeRel``

Release executables tend to be more optimized than Debug versions.
In Spack, we set the default as `Release` unless otherwise specified through a variant (e.g., ``build_type=Debug``).

Spack then automatically sets the ``-DCMAKE_INSTALL_PREFIX`` path, appends the build type (defaulting to ``RelWithDebInfo``), and enables a verbose ``Makefile`` output by default.

Next, we add the ``rpaths`` to ``-DCMAKE_INSTALL_RPATH:STRING``.

Finally, we add the locations of our dependencies to ``-DCMAKE_PREFIX_PATH:STRING`` so ``CMake`` can find them.

The Spack-generated ``cmake`` line will look like this (example is ``xrootd``):

.. code-block:: console

    $ cmake $HOME/spack/var/spack/stage/xrootd-4.6.0-4ydm74kbrp4xmcgda5upn33co5pwddyk/xrootd-4.6.0 -G Unix Makefiles -DCMAKE_INSTALL_PREFIX:PATH=$HOME/spack/opt/spack/darwin-sierra-x86_64/clang-9.0.0-apple/xrootd-4.6.0-4ydm74kbrp4xmcgda5upn33co5pwddyk -DCMAKE_BUILD_TYPE:STRING=RelWithDebInfo -DCMAKE_VERBOSE_MAKEFILE:BOOL=ON -DCMAKE_FIND_FRAMEWORK:STRING=LAST -DCMAKE_INSTALL_RPATH_USE_LINK_PATH:BOOL=FALSE -DCMAKE_INSTALL_RPATH:STRING=$HOME/spack/opt/spack/darwin-sierra-x86_64/clang-9.0.0-apple/xrootd-4.6.0-4ydm74kbrp4xmcgda5upn33co5pwddyk/lib:$HOME/spack/opt/spack/darwin-sierra-x86_64/clang-9.0.0-apple/xrootd-4.6.0-4ydm74kbrp4xmcgda5upn33co5pwddyk/lib64 -DCMAKE_PREFIX_PATH:STRING=$HOME/spack/opt/spack/darwin-sierra-x86_64/clang-9.0.0-apple/cmake-3.9.4-hally3vnbzydiwl3skxcxcbzsscaasx5

We'll now explore how ``CMake`` takes care of the boilerplate code that would otherwise be manually written.

Let's try to recreate callpath_:

.. _callpath: https://github.com/LLNL/callpath.git

.. code-block:: console

    $ spack create -f https://github.com/llnl/callpath/archive/v1.0.3.tar.gz
    ==> This looks like a URL for callpath
    ==> Fetching https://github.com/llnl/callpath/archive/v1.0.3.tar.gz
        [100%]   47.00 KB @  916.6 KB/s
    ==> This package looks like it uses the cmake build system
    ==> Created template for callpath package
    ==> Created package file: /home/spack/spack/var/spack/repos/spack_repo/builtin/packages/callpath/package.py


which then produces the following template:

.. literalinclude:: tutorial/examples/Cmake/0.package.py
   :language: python
   :linenos:

We'll fill in the details:

.. literalinclude:: tutorial/examples/Cmake/1.package.py
   :language: python
   :linenos:
   :emphasize-lines: 9,13,14,22,23,24,25,26,27

In ``callpath``, we want to control options like ``CALLPATH_WALKER`` and add compiler flags.
We can return these options from ``cmake_args()``:

.. literalinclude:: tutorial/examples/Cmake/2.package.py
   :language: python
   :linenos:
   :emphasize-lines: 30,34

We can now control our build options using ``cmake_args()``. If defaults are sufficient for this package, this method can be left out.

``CMakePackage`` classes allow for control of other features in the build system.
For example, it is possible to specify the path to an out-of-source build directory and indicate the location of the ``CMakeLists.txt`` file if it resides in a non-standard location.

``spades`` has its ``CMakeLists.txt`` file located outside of the standard path.

.. code-block:: console

    $ spack edit spades

.. code-block:: python

    root_cmakelists_dir = "src"

``root_cmakelists_dir`` will tell Spack where to find the location of ``CMakeLists.txt``.

Some packages, like ``sniffles``, require the ``install`` phase to be overridden.

.. code-block:: console

    $ spack edit sniffles

In the ``install()`` method, the targets are manually installed, so we override the method to do it for us:

.. code-block:: python

    # the build process doesn't actually install anything, do it by hand
    def install(self, spec, prefix):
        mkdir(prefix.bin)
        src = "bin/sniffles-core-{0}".format(spec.version.dotted)
        binaries = ['sniffles', 'sniffles-debug']
        for b in binaries:
            install(join_path(src, b), join_path(prefix.bin, b))


--------------
PythonPackage
--------------

Python extensions and modules are built differently from source than most applications.
These modules are usually installed by running ``pip install .``.

Package definitions for Python packages can be written using the ``Package`` class, but it contains many methods that are not useful for this use case.

Spack provides a ``PythonPackage`` subclass to allow for easier installation of Python modules.

We will write a package file for dateutil_:

.. _dateutil: https://dateutil.readthedocs.io/en/stable/

.. code-block:: console

    $ spack create -f https://pypi.io/packages/source/p/python-dateutil/python-dateutil-2.9.0.post0.tar.gz
    ==> This looks like a URL for python-dateutil
    ==> Selected 26 versions
    2.9.0.post0  https://files.pythonhosted.org/packages/66/c0/0c8b6ad9f17a802ee498c46e004a0eb49bc148f2fd230864601a86dcf6db/python-dateutil-2.9.0.post0.tar.gz#sha256=37dd54208da7e1cd875388217d5e00ebd4179249f90fb72437e91a35459a0ad3
    ...
    
    ==> Enter number of versions to take, or use a command:
        [c]hecksum  [e]dit  [f]ilter  [a]sk each  [n]ew only  [r]estart  [q]uit
    action> 1
    ==> Selected 1 of 26 versions
    2.9.0.post0  https://files.pythonhosted.org/packages/66/c0/0c8b6ad9f17a802ee498c46e004a0eb49bc148f2fd230864601a86dcf6db/python-dateutil-2.9.0.post0.tar.gz#sha256=37dd54208da7e1cd875388217d5e00ebd4179249f90fb72437e91a35459a0ad3

    ==> Enter number of versions to take, or use a command:
        [c]hecksum  [e]dit  [f]ilter  [a]sk each  [n]ew only  [r]estart  [q]uit
    action> c
    ==> Fetching https://files.pythonhosted.org/packages/66/c0/0c8b6ad9f17a802ee498c46e004a0eb49bc148f2fd230864601a86dcf6db/python-dateutil-2.9.0.post0.tar.gz#sha256=37dd54208da7e1cd875388217d5e00ebd4179249f90fb72437e91a35459a0ad3
        [100%]  342.43 KB @   35.9 MB/s
    ==> This package looks like it uses the python build system
    ==> Changing package name from python-dateutil to py-python-dateutil
    ==> Created template for py-python-dateutil package
    ==> Created package file: /home/spack/spack/var/spack/repos/spack_repo/builtin/packages/py_python_dateutil/package.py


Spack generates the following template:

.. literalinclude:: tutorial/examples/PyPackage/0.package.py
   :language: python
   :linenos:

This is similar to other package templates; we have the choice to provide build options or use sensible defaults.

Next, we'll need to find the dependencies for ``dateutil``.
Dependencies are usually listed in ``pyproject.toml``, ``setup.py``, ``setup.cfg``, or ``requirements.txt``.

Here are the relevant blocks for ``dateutil``:

.. code-block:: python
    # pyproject.toml
    [build-system]
    requires = [
        "setuptools; python_version != '3.3'",
        "setuptools<40.0; python_version == '3.3'",
        "wheel",
        "setuptools_scm<8.0"
    ]

    # setup.cfg

    [options]
    zip_safe = True
    setup_requires = setuptools_scm
    install_requires = six >= 1.5

These files indicate that ``dateutil`` depends on ``setuptools``, ``setuptools-scm``, ``wheel`, and `six`.

Here's the completed package definition:

.. literalinclude:: tutorial/examples/PyPackage/1.package.py
   :language: python
   :linenos:

It's important to declare all dependencies of a Python package.
Spack "activates" Python packages in order to avoid loading of each dependency explicitly.
If a dependency is missing, Spack will be unable to properly activate the package.

For more information about leveraging ``PythonPackage``, see the `docs <https://spack.readthedocs.io/en/latest/build_systems/pythonpackage.html>`_.

-------------------
Other Build Systems
-------------------

While we won't go in depth on the other build systems that Spack supports, it's worth noting that Spack provides support for many specialized build systems beyond the ones covered in this tutorial.

Some examples include:

1. `RPackage <https://spack.readthedocs.io/en/latest/build_systems/rpackage.html>`_
2. `MesonPackage <https://spack.readthedocs.io/en/latest/build_systems/mesonpackage.html>`_
3. `PerlPackage <https://spack.readthedocs.io/en/latest/build_systems/perlpackage.html>`_
4. `CUDAPackage <https://spack.readthedocs.io/en/latest/build_systems/cudapackage.html>`_
5. `ROCmPackage <https://spack.readthedocs.io/en/latest/build_systems/rocmpackage.html>`_

...and `many more <https://spack.readthedocs.io/en/latest/build_systems.html>`_!

Each of these build system classes provides abstractions to simplify and standardize the process of writing package recipes.
They help manage common build logic and reduce duplication across packages in the same ecosystem.

For packages that don't align well with any specific build system, Spack also provides a generic ``Package`` base class that gives full control over the build process.

By now, we've seen how Spack aims to make packaging both simple and robust through its build system abstractions.
To learn more, refer to the `Overview of the installation procedure <https://spack.readthedocs.io/en/latest/packaging_guide.html#installation-procedure>`_ in the Packaging Guide.
