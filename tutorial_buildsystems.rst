.. Copyright Spack Project Developers. See COPYRIGHT file for details.

   SPDX-License-Identifier: (Apache-2.0 OR MIT)

.. include:: common/setup.rst

.. _build-systems-tutorial:

===========================
Spack Package Build Systems
===========================

You may begin to notice after writing a couple of package template files that a pattern emerges for some packages.
For example, you may find yourself writing an ``install()`` method that invokes: ``configure``, ``cmake``, ``make``, ``make install``.
You may also find yourself writing ``"prefix=" + prefix`` as an argument to ``configure`` or ``cmake``.
Rather than having you repeat these lines for all packages, Spack has classes that can take care of these patterns.
In addition, these package files allow for finer-grained control of these build systems.
In this section, we will describe each build system and give examples on how these can be used to simplify packaging.

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

The above diagram gives a high-level view of the class hierarchy and how each package relates.
Each build system specific class inherits from the ``PackageBase`` superclass.
The bulk of the common work is done in this superclass which includes fetching, extracting to a staging directory and the install process.
Each subclass then adds additional build-system-specific functionality.
In the following sections, we will go over examples of how to utilize each subclass and see how powerful these abstractions are when packaging.

-----------------
Package
-----------------

We've already seen examples of using the generic ``Package`` class in our walkthrough for writing package files, so we won't be spending much time with it here.
Briefly, the Package class allows for arbitrary control over the build process, whereas subclasses rely on certain patterns (e.g. ``configure`` ``make`` ``make install``) to be useful.
The generic ``Package`` class is particularly useful for packages that have a non-conventional build process, as it allows the packager to use Spack's helper functions to customize the building and installing of a package fully.

-------------------
Autotools
-------------------

As we have seen earlier, packages using ``Autotools`` use ``configure``, ``make`` and ``make install`` commands to execute the build and install process.
In our ``Package`` class, your typical build incantation will consist of the following:

.. code-block:: python

    def install(self, spec, prefix):
        configure("--prefix=" + prefix)
        make()
        make("install")

You'll see that this looks similar to what we wrote in our packaging tutorial.

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


This will open the ``AutotoolsPackage`` file in your text editor.

.. note::
    The examples showing code for these classes are abridged to avoid having
    long examples. We only show what is relevant to the packager.


.. literalinclude:: _spack_root/lib/spack/spack/build_systems/autotools.py
    :emphasize-lines: 2,4,28-37
    :lines: 138-158,589-617
    :linenos:


Important to note are the highlighted lines.
These properties allow the packager to set what build targets and install targets they want for their package.
If, for example, we wanted to add as our build target ``foo`` then we can append to our ``build_targets`` list:

.. code-block:: python

    build_targets = ["foo"]

Which is similar to invoking ``make`` in our Package

.. code-block:: python

     make("foo")

This is useful if we have packages that ignore environment variables and need a command-line argument.

Another thing to take note of is in the ``configure()`` method in ``AutotoolsPackage``.
Here we see that the ``--prefix`` argument is already included since it is a common pattern amongst packages using ``Autotools``.
Therefore, we typically only need to override the ``configure_args()`` method to return a list of additional arguments.
The ``configure()`` method will then append these to the standard arguments.

Packagers also have the option to run ``autoreconf`` in case a package needs to update the build system and generate a new ``configure``.
However, for the most part this will be unnecessary.

Let's look at the ``mpileaks`` package.py file that we worked on earlier:

.. code-block:: console

    $ spack edit mpileaks

Notice that mpileaks was originally written as a generic ``Package`` but uses the ``Autotools`` build system.
Although this package is acceptable, let's covert it to an ``AutotoolsPackage`` to simplify it further.

.. literalinclude:: tutorial/examples/Autotools/0.package.py
   :language: python
   :emphasize-lines: 9
   :linenos:

We first inherit from the ``AutotoolsPackage`` class.


Although we could keep the ``install()`` method, most of it can be handled by the ``AutotoolsPackage`` base class.
In fact, the only thing that needs to be overridden is ``configure_args()``.

.. literalinclude:: tutorial/examples/Autotools/1.package.py
   :language: python
   :emphasize-lines: 25,26,27,28,29,30,31,32
   :linenos:

Since Spack's ``AutotoolsPackage`` takes care of setting the prefix for us, we can exclude that as an argument to ``configure``.
Our package file looks simpler, and we don't need to worry about whether we have properly included ``configure`` and ``make``.

This version of the ``mpileaks`` package installs the same as the previous, but the ``AutotoolsPackage`` class lets us do it with a cleaner looking package file.

-----------------
Makefile
-----------------

Packages that utilize ``Make`` or a ``Makefile`` usually require you to edit a ``Makefile`` to set up platform and compiler-specific variables.
These packages are handled by the ``MakefilePackage`` subclass which provides convenience methods to help write these types of packages.

A ``MakefilePackage`` build has three phases that can be overridden by the packager:

    1. ``edit()``
    2. ``build()``
    3. ``install()``

Packagers then have the ability to control how a ``Makefile`` is edited, and what targets to include for the build phase or install phase.

Let's also take a look inside the ``MakefilePackage`` class:

.. code-block:: console

    $ spack edit --build-system makefile

Take note of the following:


.. literalinclude:: _spack_root/lib/spack/spack/build_systems/makefile.py
   :language: python
   :emphasize-lines: 60,64,69
   :lines: 40-111
   :linenos:

Similar to ``Autotools``, ``MakefilePackage`` class has properties that can be set by the packager.
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

Once the fetching is completed, Spack will open up your text editor in the usual fashion and create a template of a ``MakefilePackage`` package.py.

.. literalinclude:: tutorial/examples/Makefile/0.package.py
   :language: python
   :linenos:

Spack was successfully able to detect that ``Bowtie`` uses ``Makefiles``.
Let's add in the rest of our details for our package:

.. literalinclude:: tutorial/examples/Makefile/1.package.py
   :language: python
   :emphasize-lines: 10,11,13,14,18,20
   :linenos:

As we mentioned earlier, most packages using a ``Makefile`` have hardcoded variables that must be edited.
These variables are fine if you happen to not care about setup or types of compilers used, but Spack is designed to work with any compiler.
The ``MakefilePackage`` subclass makes it easy to edit these ``Makefiles`` by having an ``edit()`` method that can be overridden.

Let's take a look at the default ``Makefile`` that ``Bowtie`` provides.
If we look inside, we see that ``CC`` and ``CXX`` point to our GNU compiler:

.. code-block:: console

    $ spack stage bowtie

.. note::
    As usual make sure you have shell support activated with Spack:
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
This allows us to build ``Bowtie`` with whatever compiler we specify through Spack's spec syntax.

Let's change the build and install phases of our package:

.. literalinclude:: tutorial/examples/Makefile/3.package.py
   :language: python
   :emphasize-lines: 28,29,30,31,32,35,36
   :linenos:

Here we demonstrate another strategy that we can use to manipulate our package's build.
We can provide command-line arguments to ``make()``.
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

As you may have noticed, we didn't really write anything to the ``Makefile`` but rather we set environment variables that will override variables set in the ``Makefile``.

Some packages include a configuration file that sets certain compiler variables, platform specific variables, and the location of dependencies or libraries.
If the file is simple and only requires a couple of changes, we can replace those entries with our ``FileFilter`` object.
If the configuration involves complex changes, we can write a new configuration file from scratch within the ``edit()`` method.

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

CMake_ is another common build system that has been gaining popularity.
It works in a similar manner to ``Autotools`` but with differences in variable names, the number of configuration options available, and the handling of shared libraries.
Typical build incantations look like this:

.. _CMake: https://cmake.org

.. code-block:: python

    def install(self, spec, prefix):
        cmake("-DCMAKE_INSTALL_PREFIX:PATH=/path/to/install_dir ..")
        make()
        make("install")

As you can see from the example above, it's very similar to invoking ``configure`` and ``make`` in an ``Autotools`` build system.
However, the variable names and options differ.
Most options in CMake are prefixed with a ``'-D'`` flag to indicate a configuration setting.

In the ``CMakePackage`` class, we can override the following build phases:

1. ``cmake()``
2. ``build()``
3. ``install()``

The ``CMakePackage`` class also provides sensible defaults, so often we only need to override ``cmake_args()`` to pass package-specific options.

Let's look at these defaults in the ``CMakePackage`` class in the ``_std_args()`` method:

.. code-block:: console

    $ spack edit --build-system cmake

.. literalinclude:: _spack_root/lib/spack/spack/build_systems/cmake.py
   :language: python
   :lines: 167-300
   :emphasize-lines: 87,96
   :linenos:

Some ``CMake`` packages use different generators.
Spack is able to support Unix-Makefile_ generators as well as Ninja_ generators.

.. _Unix-Makefile: https://cmake.org/cmake/help/v3.4/generator/Unix%20Makefiles.html
.. _Ninja: https://cmake.org/cmake/help/v3.4/generator/Ninja.html

If no generator is specified, Spack will default to ``Unix Makefiles``.

Next we setup the build type.
In ``CMake`` you can specify the build type that you want.
Options include:

1. ``empty``
2. ``Debug``
3. ``Release``
4. ``RelWithDebInfo``
5. ``MinSizeRel``

With these options you can specify whether you want your executable to have the debug version only, release version or the release with debug information.
Release executables tend to be more optimized than Debug versions.
In Spack, we set the default as `Release` unless otherwise specified through a variant (e.g., ``build_type=Debug``).

Spack then automatically sets up the ``-DCMAKE_INSTALL_PREFIX`` path, appends the build type (defaulting to ``RelWithDebInfo``), and enables a verbose ``Makefile`` output by default.

Next we add the ``rpaths`` to ``-DCMAKE_INSTALL_RPATH:STRING``.


Finally we add to ``-DCMAKE_PREFIX_PATH:STRING`` the locations of all our dependencies so that ``CMake`` can find them.

In the end our ``cmake`` line will look like this (example is ``xrootd``):

.. code-block:: console

    $ cmake $HOME/spack/var/spack/stage/xrootd-4.6.0-4ydm74kbrp4xmcgda5upn33co5pwddyk/xrootd-4.6.0 -G Unix Makefiles -DCMAKE_INSTALL_PREFIX:PATH=$HOME/spack/opt/spack/darwin-sierra-x86_64/clang-9.0.0-apple/xrootd-4.6.0-4ydm74kbrp4xmcgda5upn33co5pwddyk -DCMAKE_BUILD_TYPE:STRING=RelWithDebInfo -DCMAKE_VERBOSE_MAKEFILE:BOOL=ON -DCMAKE_FIND_FRAMEWORK:STRING=LAST -DCMAKE_INSTALL_RPATH_USE_LINK_PATH:BOOL=FALSE -DCMAKE_INSTALL_RPATH:STRING=$HOME/spack/opt/spack/darwin-sierra-x86_64/clang-9.0.0-apple/xrootd-4.6.0-4ydm74kbrp4xmcgda5upn33co5pwddyk/lib:$HOME/spack/opt/spack/darwin-sierra-x86_64/clang-9.0.0-apple/xrootd-4.6.0-4ydm74kbrp4xmcgda5upn33co5pwddyk/lib64 -DCMAKE_PREFIX_PATH:STRING=$HOME/spack/opt/spack/darwin-sierra-x86_64/clang-9.0.0-apple/cmake-3.9.4-hally3vnbzydiwl3skxcxcbzsscaasx5

We can see now how ``CMake`` takes care of a lot of the boilerplate code that would have to be otherwise typed in.

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

Again we fill in the details:

.. literalinclude:: tutorial/examples/Cmake/1.package.py
   :language: python
   :linenos:
   :emphasize-lines: 9,13,14,22,23,24,25,26,27

As mentioned earlier, Spack's ``CMakePackage`` uses sensible defaults to reduce boilerplate and simplify writing package files for ``CMake``-based software.

In ``callpath``, we want to control options like ``CALLPATH_WALKER`` or add specific compiler flags.
We can return these options from ``cmake_args()`` like so:

.. literalinclude:: tutorial/examples/Cmake/2.package.py
   :language: python
   :linenos:
   :emphasize-lines: 30,34

Now we can control our build options using ``cmake_args()``.
If defaults are sufficient enough for the package, we can leave this method out.

``CMakePackage`` classes allow for control of other features in the build system.
For example, you can specify the path to the "out of source" build directory and also point to the root of the ``CMakeLists.txt`` file if it is placed in a non-standard location.

A good example of a package that has its ``CMakeLists.txt`` file located at a different location is found in ``spades``.

.. code-block:: console

    $ spack edit spades

.. code-block:: python

    root_cmakelists_dir = "src"

Here ``root_cmakelists_dir`` will tell Spack where to find the location of ``CMakeLists.txt``.
In this example, it is located a directory level below in the ``src`` directory.

Some ``CMake`` packages also require the ``install`` phase to be overridden.
For example, let's take a look at ``sniffles``.

.. code-block:: console

    $ spack edit sniffles

In the ``install()`` method, we have to manually install our targets so we override the ``install()`` method to do it for us:

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
These modules are usually installed using the following line:

.. code-block:: console

    $ pip install .


We can write package files for Python packages using the ``Package`` class, but the class brings with it a lot of methods that are useless for Python packages.
Instead, Spack has a ``PythonPackage`` subclass that allows packagers of Python modules to be able to invoke ``pip``.

We will write a package file for Pandas_:

.. _pandas: https://pandas.pydata.org

.. code-block:: console

    $ spack create -t python -f https://pypi.io/packages/source/p/pandas/pandas-2.2.3.tar.gz
    ==> This looks like a URL for pandas
    ==> Selected 110 versions
    ...

    ==> Enter number of versions to take, or use a command:
        [c]hecksum  [e]dit  [f]ilter  [a]sk each  [n]ew only  [r]estart  [q]uit
    action> 1
    ==> Selected 1 of 110 versions
    2.2.3     https://files.pythonhosted.org/packages/9c/d6/9f8431bacc2e19dca897724cd097b1bb224a6ad5433784a44b587c7c13af/pandas-2.2.3.tar.gz#sha256=4f18ba62b61d7e192368b84517265a99b4d7ee8912f8708660fb4a366cc82667

    ==> Enter number of versions to take, or use a command:
        [c]hecksum  [e]dit  [f]ilter  [a]sk each  [n]ew only  [r]estart  [q]uit
    action> c
    ==> Fetching https://files.pythonhosted.org/packages/9c/d6/9f8431bacc2e19dca897724cd097b1bb224a6ad5433784a44b587c7c13af/pandas-2.2.3.tar.gz#sha256=4f18ba62b61d7e192368b84517265a99b4d7ee8912f8708660fb4a366cc82667
        [100%]    4.40 MB @   99.6 MB/s
    ==> Using specified package template: 'python'
    ==> Changing package name from pandas to py-pandas
    ==> Created template for py-pandas package
    ==> Created package file: /home/spack/spack/var/spack/repos/spack_repo/builtin/packages/py_pandas/package.py

And we are left with the following template:

.. literalinclude:: tutorial/examples/PyPackage/0.package.py
   :language: python
   :linenos:

As you can see this is not any different than any package template that we have written.
We have the choice of providing build options or using the sensible defaults.

Luckily for us, there is no need to provide build args.

Next we need to find the dependencies of a package.
Dependencies are usually listed in ``setup.py``.
You can find the dependencies by searching for ``install_requires`` keyword in that file.
Here it is for ``Pandas``:

.. code-block:: python

    # ... code
    if sys.version_info[0] >= 3:

    setuptools_kwargs = {
                         'zip_safe': False,
                         'install_requires': ['python-dateutil >= 2',
                                              'pytz >= 2011k',
                                              'numpy >= %s' % min_numpy_ver],
                         'setup_requires': ['numpy >= %s' % min_numpy_ver],
                         }
    if not _have_setuptools:
        sys.exit("need setuptools/distribute for Py3k"
                 "\n$ pip install distribute")

    # ... more code

You can find a more comprehensive list at the Pandas documentation_.

.. _documentation: https://pandas.pydata.org/pandas-docs/stable/install.html


By reading the documentation and ``setup.py`` we found that ``Pandas`` depends on ``python-dateutil``, ``pytz``, and ``numpy``, ``numexpr``, and finally ``bottleneck``.

Here is the completed ``Pandas`` script:

.. literalinclude:: tutorial/examples/PyPackage/1.package.py
   :language: python
   :linenos:

It is quite important to declare all the dependencies of a Python package.
Spack can "activate" Python packages to prevent the user from having to load each dependency module explicitly.
If a dependency is missed, Spack will be unable to properly activate the package and it will cause an issue.
To learn more about extensions go to `spack extensions <https://spack.readthedocs.io/en/latest/basic_usage.html#cmd-spack-extensions>`_.

From this example, you can see that building Python modules is made easy through the ``PythonPackage`` class.

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

By now, you've seen how Spack aims to make packaging both simple and robust through its build system abstractions.  
To learn more, refer to the `Overview of the installation procedure <https://spack.readthedocs.io/en/latest/packaging_guide.html#installation-procedure>`_ in the Packaging Guide.
