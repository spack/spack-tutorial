.. Copyright 2013-2023 Lawrence Livermore National Security, LLC and other
   Spack Project Developers. See the top-level COPYRIGHT file for details.

   SPDX-License-Identifier: (Apache-2.0 OR MIT)

.. include:: common/setup.rst

.. _advanced-packaging-tutorial:

============================
Advanced Topics in Packaging
============================

Spack tries to automatically configure software packages with information from
their Spack package dependencies. Ideally, you only need to list the
dependencies (using the ``depends_on`` directive) and specify the build system
(for example, by deriving from :code:`CmakePackage`).

However, there are many special cases. Often, you need to retrieve details
about dependencies to set package-specific configuration options or define
package-specific environment variables used by the software's build
system. This tutorial covers how to retrieve build information from
dependencies and how you can automatically provide important information to
dependent packages from your package.

----------------------
Setup for the Tutorial
----------------------

.. note::

  We do not recommend doing this section of the tutorial in a
  production Spack instance.

This tutorial uses custom package definitions with missing sections that
will be filled in during the exercises. These package definitions are stored
in a separate package repository, which can be enabled with:

.. code-block:: console

  $ spack repo add --scope=site var/spack/repos/tutorial

This section of the tutorial may also require a newer version of
GCC. If you have not already installed GCC @7.2.0 and added it to your
configuration, you can do so with:

.. code-block:: console

  $ spack install gcc@7.2.0 %gcc@5.4.0  # This might take a while
  $ spack compiler add --scope=site `spack location -i gcc@7.2.0 %gcc@5.4.0`

If you are using the tutorial Docker image, all dependency packages
will have been pre-installed. Otherwise, to install these packages, you can use
the following commands:

.. code-block:: console

  $ spack install openblas
  $ spack install netlib-lapack
  $ spack install mpich

Now, you are ready to set your preferred ``EDITOR`` and continue with
the rest of the tutorial.

.. note::

  Several of these packages depend on an MPI implementation. You can use
  OpenMPI if you install it from scratch, but this is slow (>10 minutes).
  A binary cache of MPICH may be provided, in which case you can force
  packages to use it and install quickly. All tutorial examples with
  packages that depend on MPICH include the spec syntax for building with it.

.. _adv_pkg_tutorial_start:

---------------------------------------
Modifying a Package's Build Environment
---------------------------------------

Spack sets up several environment variables, like ``PATH``, by default to aid
in building a software package. However, many software packages make use of
environment variables that convey specific information about their
dependencies (e.g., ``MPICC`` for an MPI library). This section covers how to
update your Spack packages so that such package-specific environment
variables are defined at build time.

^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
Set environment variables in dependent packages at build-time
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Dependencies can set environment variables that are required when their
dependent packages build. For example, when a package depends on a Python
extension like ``py-numpy``, Spack's ``python`` package will add the extension's
path to ``PYTHONPATH`` so it is available at build time. This is required
because the default setup that Spack performs is not always sufficient for
Python to import modules from dependencies.

To provide environment setup for a dependent package, a Spack package can
implement the :py:func:`setup_dependent_build_environment
<spack.package.PackageBase.setup_dependent_build_environment>`
and/or :py:func:`setup_dependent_run_environment
<spack.package.PackageBase.setup_dependent_run_environment>` methods.
These methods take an :py:class:`EnvironmentModifications
<spack.util.environment.EnvironmentModifications>` object as a parameter,
which includes convenience methods to update the environment. For example, an
MPI implementation package can set ``MPICC`` for build-time use for packages
that depend on it:

.. code-block:: python

  def setup_dependent_build_environment(self, env, dependent_spec):
      env.set('MPICC', join_path(self.prefix.bin, 'mpicc'))

In this case, packages that depend on this ``mpi`` package will have ``MPICC``
defined in their environment when they build. This section is focused on
modifying the build-time environment, represented by ``env``. However, it's
worth noting that modifications to the runtime environment, made through the
:py:func:`setup_dependent_run_environment
<spack.package.PackageBase.setup_dependent_run_environment>` method's
``env`` parameter, are included in Spack's automatically generated
module files.

We can practice by editing the ``mpich`` package to set the ``MPICC``
environment variable in the build-time environment of dependent packages.

.. code-block:: console

  $ spack edit mpich

Once you're finished, the method should look like this:

.. code-block:: python

  def setup_dependent_environment(self, spack_env, run_env, dependent_spec):
      spack_env.set('MPICC',  join_path(self.prefix.bin, 'mpicc'))
      spack_env.set('MPICXX', join_path(self.prefix.bin, 'mpic++'))
      spack_env.set('MPIF77', join_path(self.prefix.bin, 'mpif77'))
      spack_env.set('MPIF90', join_path(self.prefix.bin, 'mpif90'))

      spack_env.set('MPICH_CC', spack_cc)
      spack_env.set('MPICH_CXX', spack_cxx)
      spack_env.set('MPICH_F77', spack_f77)
      spack_env.set('MPICH_F90', spack_fc)
      spack_env.set('MPICH_FC', spack_fc)

At this point we can, for instance, install ``netlib-scalapack`` with
``mpich``:

.. code-block:: console

  $ spack install netlib-scalapack ^mpich
  ...
  ==> Created stage in /usr/local/var/spack/stage/netlib-scalapack-2.0.2-km7tsbgoyyywonyejkjoojskhc5knz3z
  ==> No patches needed for netlib-scalapack
  ==> Building netlib-scalapack [CMakePackage]
  ==> Executing phase: 'cmake'
  ==> Executing phase: 'build'
  ==> Executing phase: 'install'
  ==> Successfully installed netlib-scalapack
    Fetch: 0.01s.  Build: 3m 59.86s.  Total: 3m 59.87s.
  [+] /usr/local/opt/spack/linux-ubuntu16.04-x86_64/gcc-5.4.0/netlib-scalapack-2.0.2-km7tsbgoyyywonyejkjoojskhc5knz3z


You can double-check the environment logs to verify that each variable was
set to the correct value.

^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
Set environment variables in your own package
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Packages can modify their own build-time environment by implementing the
:py:func:`setup_build_environment <spack.package.PackageBase.setup_build_environment>`
method and their own runtime environment by implementing the
:py:func:`setup_run_environment <spack.package.PackageBase.setup_run_environment>`
method. For the ``qt`` Spack package, this looks like:

.. code-block:: python

    def setup_build_environment(self, env):
        env.set('MAKEFLAGS', '-j{0}'.format(make_jobs))
        if self.spec.satisfies('@5.11:'):
            # QDoc uses LLVM as of 5.11; remove the LLVM_INSTALL_DIR to
            # disable
            try:
                llvm_path = self.spec['llvm'].prefix
            except KeyError:
                # Prevent possibly incompatible system LLVM from being found
                llvm_path = "/spack-disable-llvm"
            env.set('LLVM_INSTALL_DIR', llvm_path)

    def setup_run_environment(self, env):
        env.set('QTDIR', self.prefix)
        env.set('QTINC', self.prefix.inc)
        env.set('QTLIB', self.prefix.lib)
        env.prepend_path('QT_PLUGIN_PATH', self.prefix.plugins)

When ``qt`` builds, ``MAKEFLAGS`` will be defined in the environment and,
for versions from 5.11 on, ``LLVM_INSTALL_DIR`` will also be defined.

To contrast with ``qt``'s :py:func:`setup_dependent_build_environment
<spack.package.PackageBase.setup_dependent_build_environment>`
function:

.. code-block:: python

    def setup_dependent_build_environment(self, env, dependent_spec):
        env.set('QTDIR', self.prefix)
        env.set('QTINC', self.prefix.inc)
        env.set('QTLIB', self.prefix.lib)
        env.prepend_path('QT_PLUGIN_PATH', self.prefix.plugins)

It is not necessary to implement a ``setup_dependent_run_environment``
method for ``qt`` so one is not provided.

Let's see how it works by completing the ``elpa`` package:

.. code-block:: console

  $ spack edit elpa

In the end, your method should look like:

.. code-block:: python

  def setup_environment(self, spack_env, run_env):
      spec = self.spec

      spack_env.set('CC', spec['mpi'].mpicc)
      spack_env.set('FC', spec['mpi'].mpifc)
      spack_env.set('CXX', spec['mpi'].mpicxx)
      spack_env.set('SCALAPACK_LDFLAGS', spec['scalapack'].libs.joined())

      spack_env.append_flags('LDFLAGS', spec['lapack'].libs.search_flags)
      spack_env.append_flags('LIBS', spec['lapack'].libs.link_flags)

At this point, it's possible to proceed with the installation of ``elpa ^mpich``:

------------------------------
Retrieving Library Information
------------------------------

Although Spack attempts to help packages locate their dependency libraries
automatically (e.g., by setting ``PKG_CONFIG_PATH`` and ``CMAKE_PREFIX_PATH``),
a package may have unique configuration options that are required to locate
libraries. When a package needs information about dependency libraries, the
general approach in Spack is to query its dependencies for the locations of
their libraries and set configuration options accordingly. By default, most
Spack packages know how to automatically locate their own libraries for
dependents. This section covers how to retrieve library information from
dependencies and how to define how libraries are located when the default
logic doesn't work.

^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
Accessing dependency libraries
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

If you need to access the libraries of a dependency, you can do so
via the ``libs`` property of the spec, for example in the ``arpack-ng``
package:

.. code-block:: python

    def install(self, spec, prefix):
        lapack_libs = spec['lapack'].libs.joined(';')
        blas_libs = spec['blas'].libs.joined(';')

        cmake(*[
            '-DLAPACK_LIBRARIES={0}'.format(lapack_libs),
            '-DBLAS_LIBRARIES={0}'.format(blas_libs)
        ], '.')

Note that ``arpack-ng`` is querying virtual dependencies, which Spack
automatically resolves to the installed implementation (e.g. ``openblas``
for ``blas``).

We've started work on a package for ``armadillo``. You should open it,
read through the comment that starts with ``# TUTORIAL:`` and complete
the ``cmake_args`` section:

.. code-block:: console

  $ spack edit armadillo

If you followed the instructions in the package, when you are finished, the
``cmake_args`` method should look like:

.. code-block:: python

  def cmake_args(self):
        spec = self.spec

        return [
            # ARPACK support
            '-DARPACK_LIBRARY={0}'.format(spec['arpack-ng'].libs.joined(";")),
            # BLAS support
            '-DBLAS_LIBRARY={0}'.format(spec['blas'].libs.joined(";")),
            # LAPACK support
            '-DLAPACK_LIBRARY={0}'.format(spec['lapack'].libs.joined(";")),
            # SuperLU support
            '-DSuperLU_INCLUDE_DIR={0}'.format(spec['superlu'].prefix.include),
            '-DSuperLU_LIBRARY={0}'.format(spec['superlu'].libs.joined(";")),
            # HDF5 support
            '-DDETECT_HDF5={0}'.format('ON' if '+hdf5' in spec else 'OFF')
        ]

As you can see, getting the list of libraries that your dependencies provide
is as easy as accessing their ``libs`` attribute. Furthermore, the interface
remains the same whether you are querying regular or virtual dependencies.

At this point, you can complete the installation of ``armadillo`` using ``openblas``
as a LAPACK provider (``armadillo ^openblas ^mpich``):

.. code-block:: console

  $ spack install armadillo ^openblas ^mpich
  ==> pkg-config is already installed in /usr/local/opt/spack/linux-ubuntu16.04-x86_64/gcc-5.4.0/pkg-config-0.29.2-ae2hwm7q57byfbxtymts55xppqwk7ecj
  ...
  ==> superlu is already installed in /usr/local/opt/spack/linux-ubuntu16.04-x86_64/gcc-5.4.0/superlu-5.2.1-q2mbtw2wo4kpzis2e2n227ip2fquxrno
  ==> Installing armadillo
  ==> Using cached archive: /usr/local/var/spack/cache/armadillo/armadillo-8.100.1.tar.xz
  ==> Staging archive: /usr/local/var/spack/stage/armadillo-8.100.1-n2eojtazxbku6g4l5izucwwgnpwz77r4/armadillo-8.100.1.tar.xz
  ==> Created stage in /usr/local/var/spack/stage/armadillo-8.100.1-n2eojtazxbku6g4l5izucwwgnpwz77r4
  ==> Applied patch undef_linux.patch
  ==> Building armadillo [CMakePackage]
  ==> Executing phase: 'cmake'
  ==> Executing phase: 'build'
  ==> Executing phase: 'install'
  ==> Successfully installed armadillo
    Fetch: 0.01s.  Build: 3.96s.  Total: 3.98s.
  [+] /usr/local/opt/spack/linux-ubuntu16.04-x86_64/gcc-5.4.0/armadillo-8.100.1-n2eojtazxbku6g4l5izucwwgnpwz77r4

Hopefully, the installation went fine and the code we added expanded to the correct list
of semicolon-separated libraries (you are encouraged to open ``armadillo``'s
build logs to double-check).

^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
Providing libraries to dependents
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Spack provides a default implementation for the ``libs`` property which often
works out of the box. A user can write a package definition without having to
implement a custom ``libs`` property, and dependents can retrieve its libraries
as shown in the above section. However, the default implementation assumes that
libraries follow the naming scheme ``lib<package_name>.so`` (or e.g.,
``lib<package_name>.a`` for static libraries). Packages that don't
follow this naming scheme must implement this property themselves, e.g.,
``opencv``:

.. code-block:: python

    @property
    def libs(self):
        shared = "+shared" in self.spec
        return find_libraries(
            "libopencv_*", root=self.prefix, shared=shared, recursive=True
        )

This issue is common for packages which implement an interface (i.e.
virtual package providers in Spack). If we try to build another version of
``armadillo`` tied to ``netlib-lapack`` (``armadillo ^netlib-lapack ^mpich``),
we'll notice that this time the installation won't complete:

.. code-block:: console

  $ spack install armadillo ^netlib-lapack ^mpich
  ==> pkg-config is already installed in /usr/local/opt/spack/linux-ubuntu16.04-x86_64/gcc-5.4.0/pkg-config-0.29.2-ae2hwm7q57byfbxtymts55xppqwk7ecj
  ...
  ==> openmpi is already installed in /usr/local/opt/spack/linux-ubuntu16.04-x86_64/gcc-5.4.0/openmpi-3.0.0-yo5qkfvumpmgmvlbalqcadu46j5bd52f
  ==> Installing arpack-ng
  ==> Using cached archive: /usr/local/var/spack/cache/arpack-ng/arpack-ng-3.5.0.tar.gz
  ==> Already staged arpack-ng-3.5.0-bloz7cqirpdxj33pg7uj32zs5likz2un in /usr/local/var/spack/stage/arpack-ng-3.5.0-bloz7cqirpdxj33pg7uj32zs5likz2un
  ==> No patches needed for arpack-ng
  ==> Building arpack-ng [Package]
  ==> Executing phase: 'install'
  ==> Error: RuntimeError: Unable to recursively locate netlib-lapack libraries in /usr/local/opt/spack/linux-ubuntu16.04-x86_64/gcc-5.4.0/netlib-lapack-3.6.1-jjfe23wgt7nkjnp2adeklhseg3ftpx6z
  RuntimeError: RuntimeError: Unable to recursively locate netlib-lapack libraries in /usr/local/opt/spack/linux-ubuntu16.04-x86_64/gcc-5.4.0/netlib-lapack-3.6.1-jjfe23wgt7nkjnp2adeklhseg3ftpx6z

  /usr/local/var/spack/repos/builtin/packages/arpack-ng/package.py:105, in install:
       5             options.append('-DCMAKE_INSTALL_NAME_DIR:PATH=%s/lib' % prefix)
       6
       7             # Make sure we use Spack's blas/lapack:
    >> 8             lapack_libs = spec['lapack'].libs.joined(';')
       9             blas_libs = spec['blas'].libs.joined(';')
       10
       11            options.extend([

  See build log for details:
    /usr/local/var/spack/stage/arpack-ng-3.5.0-bloz7cqirpdxj33pg7uj32zs5likz2un/arpack-ng-3.5.0/spack-build-out.txt

Unlike ``openblas`` which provides a library named ``libopenblas.so``,
``netlib-lapack`` provides ``liblapack.so``, so it needs to implement
customized library search logic. Let's edit it:

.. code-block:: console

  $ spack edit netlib-lapack

and follow the instructions in the ``# TUTORIAL:`` comment as before.
What we need to implement is:

.. code-block:: python

  @property
  def lapack_libs(self):
      shared = '+shared' in self.spec
      return find_libraries(
          'liblapack', root=self.prefix, shared=shared, recursive=True
      )

i.e., a property that returns the correct list of libraries for the LAPACK interface.

We use the name ``lapack_libs`` rather than ``libs`` because
``netlib-lapack`` can also provide ``blas``, and when it does it is provided
as a separate library file. Using this name ensures that when
dependents ask for ``lapack`` libraries, ``netlib-lapack`` will retrieve only
the libraries associated with the ``lapack`` interface. Now we can finally
install ``armadillo ^netlib-lapack ^mpich``:

.. code-block:: console

  $ spack install armadillo ^netlib-lapack ^mpich
  ...

  ==> Building armadillo [CMakePackage]
  ==> Executing phase: 'cmake'
  ==> Executing phase: 'build'
  ==> Executing phase: 'install'
  ==> Successfully installed armadillo
    Fetch: 0.01s.  Build: 3.75s.  Total: 3.76s.
  [+] /usr/local/opt/spack/linux-ubuntu16.04-x86_64/gcc-5.4.0/armadillo-8.100.1-sxmpu5an4dshnhickh6ykchyfda7jpyn

Since each implementation of a virtual package is responsible for locating the
libraries associated with the interfaces it provides, dependents do not need
to include special-case logic for different implementations and, for example,
need only ask for :code:`spec['blas'].libs`.

----------------------
Other Packaging Topics
----------------------

^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
Attach attributes to other packages
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Build tools usually also provide a set of executables that can be used
when another package is being installed. Spack gives you the opportunity
to monkey-patch dependent package modules and attach attributes to them. This
helps make the packager's experience as similar as possible to what would
have been the manual installation of the same package.

An example here is the ``automake`` package, which overrides
:py:func:`setup_dependent_package <spack.package.PackageBase.setup_dependent_package>`:

.. code-block:: python

  def setup_dependent_package(self, module, dependent_spec):
      # Automake is very likely to be a build dependency,
      # so we add the tools it provides to the dependent module
      executables = ['aclocal', 'automake']
      for name in executables:
          setattr(module, name, self._make_executable(name))

so that every other package that depends on it can directly use ``aclocal``
and ``automake`` with the usual function call syntax of :py:class:`Executable <spack.util.executable.Executable>`:

.. code-block:: python

  aclocal('--force')

^^^^^^^^^^^^^^^^^^^^^^^
Extra Query Parameters
^^^^^^^^^^^^^^^^^^^^^^^

An advanced feature of the spec's build-interface protocol is the support
for extra parameters after the subscript key. In fact, any of the keys used
in the query can be followed by a comma-separated list of extra parameters,
which can be inspected by the package receiving the request to fine-tune the
response.

Let's look at an example and try to install ``netcdf ^mpich``:

.. code-block:: console

  $ spack install netcdf ^mpich
  ==> libsigsegv is already installed in /usr/local/opt/spack/linux-ubuntu16.04-x86_64/gcc-5.4.0/libsigsegv-2.11-fypapcprssrj3nstp6njprskeyynsgaz
  ==> m4 is already installed in /usr/local/opt/spack/linux-ubuntu16.04-x86_64/gcc-5.4.0/m4-1.4.18-r5envx3kqctwwflhd4qax4ahqtt6x43a
  ...
  ==> Error: AttributeError: 'list' object has no attribute 'search_flags'
  AttributeError: AttributeError: 'list' object has no attribute 'search_flags'

  /usr/local/var/spack/repos/builtin/packages/netcdf/package.py:207, in configure_args:
       50            # used instead.
       51            hdf5_hl = self.spec['hdf5:hl']
       52            CPPFLAGS.append(hdf5_hl.headers.cpp_flags)
    >> 53            LDFLAGS.append(hdf5_hl.libs.search_flags)
       54
       55            if '+parallel-netcdf' in self.spec:
       56                config_args.append('--enable-pnetcdf')

  See build log for details:
    /usr/local/var/spack/stage/netcdf-4.4.1.1-gk2xxhbqijnrdwicawawcll4t3c7dvoj/netcdf-4.4.1.1/spack-build-out.txt

We can see from the error that ``netcdf`` needs to know how to link the *high-level interface*
of ``hdf5``, and thus passes the extra parameter ``hl`` in the query to retrieve it.
Clearly, the implementation in the ``hdf5`` package is not complete, and we need to fix it:

.. code-block:: console

  $ spack edit hdf5

If you followed the instructions correctly, the code added to the
``libs`` property should be similar to:

.. code-block:: python
  :emphasize-lines: 1

  query_parameters = self.spec.last_query.extra_parameters
  key = tuple(sorted(query_parameters))
  libraries = query2libraries[key]
  shared = '+shared' in self.spec
  return find_libraries(
      libraries, root=self.prefix, shared=shared, recursive=True
  )

where we highlighted the line retrieving the extra parameters. Now we can successfully
complete the installation of ``netcdf ^mpich``:

.. code-block:: console

  $ spack install netcdf ^mpich
  ==> libsigsegv is already installed in /usr/local/opt/spack/linux-ubuntu16.04-x86_64/gcc-5.4.0/libsigsegv-2.11-fypapcprssrj3nstp6njprskeyynsgaz
  ==> m4 is already installed in /usr/local/opt/spack/linux-ubuntu16.04-x86_64/gcc-5.4.0/m4-1.4.18-r5envx3kqctwwflhd4qax4ahqtt6x43a
  ...
  ==> Installing netcdf
  ==> Using cached archive: /usr/local/var/spack/cache/netcdf/netcdf-4.4.1.1.tar.gz
  ==> Already staged netcdf-4.4.1.1-gk2xxhbqijnrdwicawawcll4t3c7dvoj in /usr/local/var/spack/stage/netcdf-4.4.1.1-gk2xxhbqijnrdwicawawcll4t3c7dvoj
  ==> Already patched netcdf
  ==> Building netcdf [AutotoolsPackage]
  ==> Executing phase: 'autoreconf'
  ==> Executing phase: 'configure'
  ==> Executing phase: 'build'
  ==> Executing phase: 'install'
  ==> Successfully installed netcdf
    Fetch: 0.01s.  Build: 24.61s.  Total: 24.62s.
  [+] /usr/local/opt/spack/linux-ubuntu16.04-x86_64/gcc-5.4.0/netcdf-4.4.1.1-gk2xxhbqijnrdwicawawcll4t3c7dvoj

