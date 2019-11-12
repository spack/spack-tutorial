.. Copyright 2013-2019 Lawrence Livermore National Security, LLC and other
   Spack Project Developers. See the top-level COPYRIGHT file for details.

   SPDX-License-Identifier: (Apache-2.0 OR MIT)

.. _environments-tutorial:

=====================
Environments Tutorial
=====================

We've shown you how to install and remove packages with Spack.  You can
use `spack install <https://spack.readthedocs.io/en/latest/basic_usage.html#cmd-spack-install>`_ to install packages,
`spack uninstall <https://spack.readthedocs.io/en/latest/basic_usage.html#cmd-spack-uninstall>`_ to remove them,
and `spack find <https://spack.readthedocs.io/en/latest/basic_usage.html#cmd-spack-find>`_ to
look at and query what is installed.  We've also shown you how to
customize Spack's installation with configuration files like
`packages.yaml <https://spack.readthedocs.io/en/latest/build_settings.html#build-settings>`_.

If you build a lot of software, or if you work on multiple projects,
managing everything in one place can be overwhelming. The default ``spack
find`` output may contain many packages, but you may want to *just* focus
on packages for a particular project.  Moreover, you may want to include
special configuration with your package groups, e.g., to build all the
packages in the same group the same way.

Spack **environments** provide a way to handle these problems.

-------------------
Environment Basics
-------------------

Let's look at the output of ``spack find`` at this point in the tutorial.

.. code-block:: console

	$ spack find
	==> 62 installed packages
	-- linux-ubuntu18.04-x86_64 / clang@6.0.0 -----------------------
	tcl@8.6.8  zlib@1.2.8  zlib@1.2.11

	-- linux-ubuntu18.04-x86_64 / gcc@6.5.0 -------------------------
	zlib@1.2.11

	-- linux-ubuntu18.04-x86_64 / gcc@7.4.0 -------------------------
	autoconf@2.69    hwloc@1.11.11        mpich@3.3.1             pkgconf@1.6.3
	automake@1.16.1  hypre@2.18.1         mumps@5.2.0             readline@8.0
	boost@1.70.0     hypre@2.18.1         mumps@5.2.0             suite-sparse@5.3.0
	bzip2@1.0.8      isl@0.18             ncurses@6.1             tcl@8.6.8
	cmake@3.15.4     libiconv@1.16        netcdf@4.7.1            tcl@8.6.8
	diffutils@3.7    libpciaccess@0.13.5  netcdf@4.7.1            texinfo@6.5
	findutils@4.6.0  libsigsegv@2.12      netlib-scalapack@2.0.2  trilinos@12.14.1
	gcc@8.3.0        libtool@2.4.6        netlib-scalapack@2.0.2  trilinos@12.14.1
	gdbm@1.18.1      libxml2@2.9.9        numactl@2.0.12          util-macros@1.19.1
	glm@0.9.7.1      m4@1.4.18            openblas@0.3.7          xz@5.2.4
	gmp@6.1.2        matio@1.5.13         openmpi@3.1.4           zlib@1.2.8
	hdf5@1.10.5      matio@1.5.13         openssl@1.1.1d          zlib@1.2.8
	hdf5@1.10.5      metis@5.1.0          parmetis@4.0.3          zlib@1.2.11
	hdf5@1.10.5      mpc@1.1.0            parmetis@4.0.3
	hdf5@1.10.5      mpfr@3.1.6           perl@5.30.0

This is a complete, but cluttered view.  There are packages built with
both ``openmpi`` and ``mpich``, as well as multiple variants of other
packages, like ``zlib``.  The query mechanism we learned about in ``spack
find`` can help, but it would be nice if we could start from a clean
slate without losing what we've already done.


^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
Creating and activating environments
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

The ``spack env`` command can help.  Let's create a new environment:

.. code-block:: console

	$ spack env create myproject
	==> Updating view at /home/spack1/spack/var/spack/environments/myproject/.spack-env/view
	==> Created environment 'myproject' in /home/spack1/spack/var/spack/environments/myproject

An environment is a virtualized ``spack`` instance that you can use for a
specific purpose.  The environment also has an associated *view*, which
is a single prefix where all packages from the environment are linked.

You can see the environments we've created so far like this:

.. code-block:: console

   $ spack env list
   ==> 1 environments
       myproject

And you can **activate** an environment with ``spack env activate``:

.. code-block:: console

   $ spack env activate myproject

Once you enter an environment, ``spack find`` shows only what is in the
current environment.  We just created this environment, so we have a
clean slate -- 0 packages:

.. code-block:: console

   $ spack find
   ==> In environment myproject
   ==> No root specs
   ==> 0 installed packages

The ``spack find`` output is still *slightly* different.  It tells you
that you're in the ``myproject`` environment, so that you don't panic
when you see that there is nothing installed.  It also says that there
are *no root specs*.  We'll get back to what that means later.

If you *only* want to check what environment you are in, you can use
``spack env status``:

.. code-block:: console

   $ spack env status
   ==> In environment myproject

If you want to leave this environment and go back to normal Spack,
you can use ``spack env deactivate``.  We like to use the
``despacktivate`` alias (which Spack sets up automatically) for short:

.. code-block:: console

   $ despacktivate     # short alias for `spack env deactivate`
   $ spack env status
   ==> No active environment
   $ spack find
   ==> 62 installed packages
   -- linux-ubuntu18.04-x86_64 / clang@6.0.0 -----------------------
   tcl@8.6.8  zlib@1.2.8  zlib@1.2.11

   -- linux-ubuntu18.04-x86_64 / gcc@6.5.0 -------------------------
   zlib@1.2.11

   -- linux-ubuntu18.04-x86_64 / gcc@7.4.0 -------------------------
   autoconf@2.69    hwloc@1.11.11        mpich@3.3.1             pkgconf@1.6.3
   automake@1.16.1  hypre@2.18.1         mumps@5.2.0             readline@8.0
   boost@1.70.0     hypre@2.18.1         mumps@5.2.0             suite-sparse@5.3.0
   bzip2@1.0.8      isl@0.18             ncurses@6.1             tcl@8.6.8
   cmake@3.15.4     libiconv@1.16        netcdf@4.7.1            tcl@8.6.8
   diffutils@3.7    libpciaccess@0.13.5  netcdf@4.7.1            texinfo@6.5
   findutils@4.6.0  libsigsegv@2.12      netlib-scalapack@2.0.2  trilinos@12.14.1
   gcc@8.3.0        libtool@2.4.6        netlib-scalapack@2.0.2  trilinos@12.14.1
   gdbm@1.18.1      libxml2@2.9.9        numactl@2.0.12          util-macros@1.19.1
   glm@0.9.7.1      m4@1.4.18            openblas@0.3.7          xz@5.2.4
   gmp@6.1.2        matio@1.5.13         openmpi@3.1.4           zlib@1.2.8
   hdf5@1.10.5      matio@1.5.13         openssl@1.1.1d          zlib@1.2.8
   hdf5@1.10.5      metis@5.1.0          parmetis@4.0.3          zlib@1.2.11
   hdf5@1.10.5      mpc@1.1.0            parmetis@4.0.3
   hdf5@1.10.5      mpfr@3.1.6           perl@5.30.0

Phew -- all of our packages are still installed.

^^^^^^^^^^^^^^^^^^^
Installing packages
^^^^^^^^^^^^^^^^^^^

Ok, now that we understand how creation and activation work, let's go
back to ``myproject`` and *install* a few packages:

.. code-block:: console

   $ spack env activate myproject
   $ spack install tcl
   ==> tcl is already installed in /home/spack1/spack/opt/spack/linux-ubuntu18.04-x86_64/gcc-7.4.0/tcl-8.6.8-t3gp773osdwptcklekqkqg5742zbq42b
   ==> Updating view at /home/spack1/spack/var/spack/environments/myproject/.spack-env/view
   $ spack install trilinos
   ==> trilinos is already installed in /home/spack1/spack/opt/spack/linux-ubuntu18.04-x86_64/gcc-7.4.0/trilinos-12.14.1-mpalhktqqjjo2hayykb6ut2jyhkmow3z
   ==> Updating view at /home/spack1/spack/var/spack/environments/myproject/.spack-env/view
   $ spack find
   ==> In environment myproject
   ==> Root specs
   tcl  trilinos

   ==> 23 installed packages
   -- linux-ubuntu18.04-x86_64 / gcc@7.4.0 -------------------------
   boost@1.70.0   libiconv@1.16        netcdf@4.7.1            suite-sparse@5.3.0
   bzip2@1.0.8    libpciaccess@0.13.5  netlib-scalapack@2.0.2  tcl@8.6.8
   glm@0.9.7.1    libxml2@2.9.9        numactl@2.0.12          trilinos@12.14.1
   hdf5@1.10.5    matio@1.5.13         openblas@0.3.7          xz@5.2.4
   hwloc@1.11.11  metis@5.1.0          openmpi@3.1.4           zlib@1.2.11
   hypre@2.18.1   mumps@5.2.0          parmetis@4.0.3

We've installed ``tcl`` and ``trilinos`` in our environment, along with
all of their dependencies.  We call ``tcl`` and ``trilinos`` the
**roots** because we asked for them explicitly.  The other 20 packages
listed under "installed packages" are present because they were needed as
dependencies.  So, these are the roots of the packages' dependency graph.

The "<package> is already installed" messages above are generated because
we already installed these packages in previous steps of the tutorial,
and we don't have to rebuild them to put them in an environment.

^^^^^^^^^^^^^^^^^^^^^
Using packages
^^^^^^^^^^^^^^^^^^^^^

When you install packages into an environment, they are linked into a
single prefix, or a *view*.  When you *activate* the environment with
``spack env activate``, Spack adds subdirectories from the view to
``PATH``, ``LD_LIBRARY_PATH``, ``CMAKE_PREFIX_PATH`` and other
environment variables.  This makes the environment easier to use.

Without environments, you need to ``spack load`` or ``module load`` a
package in order to use it.  With environments, you can simply run
``spack env activate`` to get everything in the environment on your
``PATH``.

Let's try it out.  ``myproject`` is still the active environment, and we
just installed ``tcl``.  You can see ``tclsh`` in your ``PATH``
immediately:

.. code-block:: console

   $ which tclsh
   /home/spack1/spack/var/spack/environments/myproject/.spack-env/view/bin/tclsh

And you can run it like you would any other program:

.. code-block:: console

	$ tclsh
	% echo "hello world!"
	hello world!
	% exit

Likewise, we installed Trilinos, and you can run some of its sub-programs
as well:

.. code-block:: console

	$ which algebra
	/home/spack1/spack/var/spack/environments/myproject/.spack-env/view/bin/algebra
	$ algebra

	           AAAAA   LL        GGGGG   EEEEEEE  BBBBBB   RRRRRR    AAAAA
	          AA   AA  LL       GG   GG  EE       BB   BB  RR   RR  AA   AA
	          AA   AA  LL       GG       EE       BB   BB  RR   RR  AA   AA
	          AAAAAAA  LL       GG       EEEEE    BBBBBB   RRRRRR   AAAAAAA
	          AA   AA  LL       GG  GGG  EE       BB   BB  RRRRR    AA   AA
	          AA   AA  LL       GG   GG  EE       BB   BB  RR  RR   AA   AA
	          AA   AA  LLLLLLL   GGGGG   EEEEEEE  BBBBBB   RR   RR  AA   AA


	                          *** algebra Version 1.45 ***
	                               Revised 2018/08/08

	                        AN ALGEBRAIC MANIPULATION PROGRAM
	                 FOR POST-PROCESSING OF FINITE ELEMENT ANALYSES
	                                EXODUS II VERSION

	                          Run on 2019-11-05 at 07:11:24

	               ==== Email gdsjaar@sandia.gov for support ====

	                          +++ Copyright 2008 NTESS +++
	                       +++ Under the terms of Contract +++
	                      +++ DE-NA0003525 with NTESS, the +++
	        +++ U.S. Government retains certain rights in this software. +++

        ...


^^^^^^^^^^^^^^^^^^^^^
Uninstalling packages
^^^^^^^^^^^^^^^^^^^^^

Now let's create *another* project.  We'll call this one ``myproject2``:

.. code-block:: console

   $ spack env create myproject2
   ==> Updating view at /home/spack1/spack/var/spack/environments/myproject2/.spack-env/view
   ==> Created environment 'myproject2' in /home/spack1/spack/var/spack/environments/myproject2

   $ spack env activate myproject2
   $ spack install hdf5+hl
   ==> hdf5 is already installed in /home/spack1/spack/opt/spack/linux-ubuntu18.04-x86_64/gcc-7.4.0/hdf5-1.10.5-audmuesjjp62dbn2ldwt576f3yurx5cs
   ==> Updating view at /home/spack1/spack/var/spack/environments/myproject2/.spack-env/view
   $ spack install trilinos
   ==> trilinos is already installed in /home/spack1/spack/opt/spack/linux-ubuntu18.04-x86_64/gcc-7.4.0/trilinos-12.14.1-mpalhktqqjjo2hayykb6ut2jyhkmow3z
   ==> Updating view at /home/spack1/spack/var/spack/environments/myproject2/.spack-env/view
   $ spack find
   ==> In environment myproject2
   ==> Root specs
   hdf5 +hl  trilinos

   ==> 22 installed packages
   -- linux-ubuntu18.04-x86_64 / gcc@7.4.0 -------------------------
   boost@1.70.0   hypre@2.18.1         metis@5.1.0             openblas@0.3.7      xz@5.2.4
   bzip2@1.0.8    libiconv@1.16        mumps@5.2.0             openmpi@3.1.4       zlib@1.2.11
   glm@0.9.7.1    libpciaccess@0.13.5  netcdf@4.7.1            parmetis@4.0.3
   hdf5@1.10.5    libxml2@2.9.9        netlib-scalapack@2.0.2  suite-sparse@5.3.0
   hwloc@1.11.11  matio@1.5.13         numactl@2.0.12          trilinos@12.14.1

Now we have two environments: one with ``tcl`` and ``trilinos``, and
another with ``hdf5 +hl`` and ``trilinos``.  Notice that the roots display *exactly* as
we asked for them on the command line -- the ``hdf5`` for this environemnt has an
``+hl`` requirement.

We can uninstall trilinos from ``myproject2`` as you would expect:

.. code-block:: console

   $ spack uninstall trilinos
   ==> The following packages will be uninstalled:

       -- linux-ubuntu18.04-x86_64 / gcc@7.4.0 -------------------------
       mpalhkt trilinos@12.14.1%gcc ~adios2~alloptpkgs+amesos+amesos2+anasazi+aztec+belos+boost build_type=RelWithDebInfo ~cgns~chaco~complex~debug~dtk+epetra+epetraext+exodus+explicit_template_instantiation~float+fortran~fortrilinos+gtest+hdf5+hypre+ifpack+ifpack2~intrepid~intrepid2~isorropia+kokkos+metis~minitensor+ml+muelu+mumps~nox~openmp~phalanx~piro~pnetcdf~python~rol~rythmos+sacado~shards+shared~shylu~stk+suite-sparse~superlu~superlu-dist~teko~tempus+teuchos+tpetra~x11~xsdkflags~zlib+zoltan+zoltan2
   ==> Do you want to proceed? [y/N] y
   ==> Updating view at /home/spack1/spack/var/spack/environments/myproject2/.spack-env/view
   $ spack find
   ==> In environment myproject2
   ==> Root specs
   hdf5 +hl

   ==> 9 installed packages
   -- linux-ubuntu18.04-x86_64 / gcc@7.4.0 -------------------------
   hdf5@1.10.5    libiconv@1.16        libxml2@2.9.9   openmpi@3.1.4  zlib@1.2.11
   hwloc@1.11.11  libpciaccess@0.13.5  numactl@2.0.12  xz@5.2.4

Now there is only one root spec, ``hdf5 +hl``, which requires fewer
additional dependencies.

However, we still needed ``trilinos`` for the ``myproject`` environment!
What happened to it?  Let's switch back and see.

.. code-block:: console

   $ despacktivate
   $ spack env activate myproject
   $ spack find
   ==> In environment myproject
   ==> Root specs
   tcl   trilinos

   ==> 23 installed packages
   -- linux-ubuntu18.04-x86_64 / gcc@7.4.0 -------------------------
   boost@1.70.0   hypre@2.18.1         metis@5.1.0             openblas@0.3.7      trilinos@12.14.1
   bzip2@1.0.8    libiconv@1.16        mumps@5.2.0             openmpi@3.1.4       xz@5.2.4
   glm@0.9.7.1    libpciaccess@0.13.5  netcdf@4.7.1            parmetis@4.0.3      zlib@1.2.11
   hdf5@1.10.5    libxml2@2.9.9        netlib-scalapack@2.0.2  suite-sparse@5.3.0
   hwloc@1.11.11  matio@1.5.13         numactl@2.0.12          tcl@8.6.8


Spack is smart enough to realize that ``trilinos`` is still present in
the other environment.  Trilinos won't *actually* be uninstalled unless
it is no longer needed by any environments or packages.  If it is still
needed, it is only removed from the environment.

-------------------------------
Dealing with Many Specs at Once
-------------------------------

In the above examples, we just used ``install`` and ``uninstall``.  There
are other ways to deal with groups of packages, as well.

^^^^^^^^^^^^^
Adding specs
^^^^^^^^^^^^^

While we're still in ``myproject``, let's *add* a few specs instead of installing them:

.. code-block:: console

   $ spack add hdf5+hl
   ==> Adding hdf5+hl to environment myproject
   ==> Updating view at /home/spack1/spack/var/spack/environments/myproject/.spack-env/view
   $ spack add gmp
   ==> Adding gmp to environment myproject
   ==> Updating view at /home/spack1/spack/var/spack/environments/myproject/.spack-env/view
   $ spack find
   ==> In environment myproject
   ==> Root specs
   gmp   hdf5 +hl  tcl   trilinos

   ==> 23 installed packages
   -- linux-ubuntu18.04-x86_64 / gcc@7.4.0 -------------------------
   boost@1.70.0   hypre@2.18.1         metis@5.1.0             openblas@0.3.7      trilinos@12.14.1
   bzip2@1.0.8    libiconv@1.16        mumps@5.2.0             openmpi@3.1.4       xz@5.2.4
   glm@0.9.7.1    libpciaccess@0.13.5  netcdf@4.7.1            parmetis@4.0.3      zlib@1.2.11
   hdf5@1.10.5    libxml2@2.9.9        netlib-scalapack@2.0.2  suite-sparse@5.3.0
   hwloc@1.11.11  matio@1.5.13         numactl@2.0.12          tcl@8.6.8

Let's take a close look at what happened.  The two requirements we added,
``hdf5 +hl`` and ``gmp``, are present, but they're not installed in the
environment yet.  ``spack add`` just adds *roots* to the environment, but
it does not automatically install them.

We can install *all* the as-yet uninstalled packages in an environment by
simply running ``spack install`` with no arguments:

.. code-block:: console

   $ spack install
   ==> Concretized hdf5+hl
   [+]  65cucf4  hdf5@1.10.5%gcc@7.4.0~cxx~debug~fortran+hl+mpi patches=b61e2f058964ad85be6ee5ecea10080bf79e73f83ff88d1fa4b602d00209da9c +pic+shared~szip~threadsafe arch=linux-ubuntu18.04-x86_64
   [+]  f6maodn      ^openmpi@3.1.4%gcc@7.4.0~cuda+cxx_exceptions fabrics=none ~java~legacylaunchers~memchecker~pmi schedulers=none ~sqlite3~thread_multiple+vt arch=linux-ubuntu18.04-x86_64
   [+]  xcjsxcr          ^hwloc@1.11.11%gcc@7.4.0~cairo~cuda~gl+libxml2~nvml+pci+shared arch=linux-ubuntu18.04-x86_64
   [+]  vhehc32              ^libpciaccess@0.13.5%gcc@7.4.0 arch=linux-ubuntu18.04-x86_64
   [+]  4neu5jw                  ^libtool@2.4.6%gcc@7.4.0 arch=linux-ubuntu18.04-x86_64
   [+]  ut64la6                      ^m4@1.4.18%gcc@7.4.0 patches=3877ab548f88597ab2327a2230ee048d2d07ace1062efe81fc92e91b7f39cd00,fc9b61654a3ba1a8d6cd78ce087e7c96366c290bc8d2c299f09828d793b853c8 +sigsegv arch=linux-ubuntu18.04-x86_64
   [+]  3khohgm                          ^libsigsegv@2.12%gcc@7.4.0 arch=linux-ubuntu18.04-x86_64
   [+]  eifxmps                  ^pkgconf@1.6.3%gcc@7.4.0 arch=linux-ubuntu18.04-x86_64
   [+]  a226ran                  ^util-macros@1.19.1%gcc@7.4.0 arch=linux-ubuntu18.04-x86_64
   [+]  fg5evg4              ^libxml2@2.9.9%gcc@7.4.0~python arch=linux-ubuntu18.04-x86_64
   [+]  zvmmgjb                  ^libiconv@1.16%gcc@7.4.0 arch=linux-ubuntu18.04-x86_64
   [+]  ur2jffe                  ^xz@5.2.4%gcc@7.4.0 arch=linux-ubuntu18.04-x86_64
   [+]  o2viq7y                  ^zlib@1.2.11%gcc@7.4.0+optimize+pic+shared arch=linux-ubuntu18.04-x86_64
   [+]  n6yyt2y              ^numactl@2.0.12%gcc@7.4.0 arch=linux-ubuntu18.04-x86_64
   [+]  g23qful                  ^autoconf@2.69%gcc@7.4.0 arch=linux-ubuntu18.04-x86_64
   [+]  cxcj6ei                      ^perl@5.30.0%gcc@7.4.0+cpanm+shared+threads arch=linux-ubuntu18.04-x86_64
   [+]  surdjxd                          ^gdbm@1.18.1%gcc@7.4.0 arch=linux-ubuntu18.04-x86_64
   [+]  hzwkvqa                              ^readline@8.0%gcc@7.4.0 arch=linux-ubuntu18.04-x86_64
   [+]  s4rsior                                  ^ncurses@6.1%gcc@7.4.0~symlinks~termlib arch=linux-ubuntu18.04-x86_64
   [+]  io3tplo                  ^automake@1.16.1%gcc@7.4.0 arch=linux-ubuntu18.04-x86_64

   ==> Concretized gmp
   [+]  fz3lzqi  gmp@6.1.2%gcc@7.4.0 arch=linux-ubuntu18.04-x86_64
   [+]  g23qful      ^autoconf@2.69%gcc@7.4.0 arch=linux-ubuntu18.04-x86_64
   [+]  ut64la6          ^m4@1.4.18%gcc@7.4.0 patches=3877ab548f88597ab2327a2230ee048d2d07ace1062efe81fc92e91b7f39cd00,fc9b61654a3ba1a8d6cd78ce087e7c96366c290bc8d2c299f09828d793b853c8 +sigsegv arch=linux-ubuntu18.04-x86_64
   [+]  3khohgm              ^libsigsegv@2.12%gcc@7.4.0 arch=linux-ubuntu18.04-x86_64
   [+]  cxcj6ei          ^perl@5.30.0%gcc@7.4.0+cpanm+shared+threads arch=linux-ubuntu18.04-x86_64
   [+]  surdjxd              ^gdbm@1.18.1%gcc@7.4.0 arch=linux-ubuntu18.04-x86_64
   [+]  hzwkvqa                  ^readline@8.0%gcc@7.4.0 arch=linux-ubuntu18.04-x86_64
   [+]  s4rsior                      ^ncurses@6.1%gcc@7.4.0~symlinks~termlib arch=linux-ubuntu18.04-x86_64
   [+]  eifxmps                          ^pkgconf@1.6.3%gcc@7.4.0 arch=linux-ubuntu18.04-x86_64
   [+]  io3tplo      ^automake@1.16.1%gcc@7.4.0 arch=linux-ubuntu18.04-x86_64
   [+]  4neu5jw      ^libtool@2.4.6%gcc@7.4.0 arch=linux-ubuntu18.04-x86_64

   ==> Updating view at /home/spack1/spack/var/spack/environments/myproject/.spack-env/view
   ==> Installing environment myproject
   ==> tcl is already installed in /home/spack1/spack/opt/spack/linux-ubuntu18.04-x86_64/gcc-7.4.0/tcl-8.6.8-t3gp773osdwptcklekqkqg5742zbq42b
   ==> trilinos is already installed in /home/spack1/spack/opt/spack/linux-ubuntu18.04-x86_64/gcc-7.4.0/trilinos-12.14.1-mpalhktqqjjo2hayykb6ut2jyhkmow3z
   ==> hdf5 is already installed in /home/spack1/spack/opt/spack/linux-ubuntu18.04-x86_64/gcc-7.4.0/hdf5-1.10.5-65cucf4mb2vyni6xto4me4sei6kwvjqv
   ==> gmp is already installed in /home/spack1/spack/opt/spack/linux-ubuntu18.04-x86_64/gcc-7.4.0/gmp-6.1.2-fz3lzqixnahwwqeqsxwevhek4eejmz3z
   ==> gmp@6.1.2 : marking the package explicit
   ==> Updating view at /home/spack1/spack/var/spack/environments/myproject/.spack-env/view

Spack will concretize the new roots, and install everything you added to
the environment.  Now we can see the installed roots in the output of
``spack find``:

.. code-block:: console

   $ spack find
   ==> In environment myproject
   ==> Root specs
   gmp   hdf5 +hl  tcl   trilinos

   ==> 24 installed packages
   -- linux-ubuntu18.04-x86_64 / gcc@7.4.0 -------------------------
   boost@1.70.0  hwloc@1.11.11        matio@1.5.13            numactl@2.0.12      tcl@8.6.8
   bzip2@1.0.8   hypre@2.18.1         metis@5.1.0             openblas@0.3.7      trilinos@12.14.1
   glm@0.9.7.1   libiconv@1.16        mumps@5.2.0             openmpi@3.1.4       xz@5.2.4
   gmp@6.1.2     libpciaccess@0.13.5  netcdf@4.7.1            parmetis@4.0.3      zlib@1.2.11
   hdf5@1.10.5   libxml2@2.9.9        netlib-scalapack@2.0.2  suite-sparse@5.3.0

We can build whole environments this way, by adding specs and installing
all at once, or we can install them with the usual ``install`` and
``uninstall`` portions.  The advantage to doing them all at once is that
we don't have to write a script outside of Spack to automate this, and we
can kick off a large build of many packages easily.

^^^^^^^^^^^^^
Configuration
^^^^^^^^^^^^^

So far, ``myproject`` does not have any special configuration associated
with it.  The specs concretize using Spack's defaults:

.. code-block:: console

   $ spack spec hypre
   Input spec
   --------------------------------
   hypre

   Concretized
   --------------------------------
   hypre@2.18.1%gcc@7.4.0~complex~debug~int64~internal-superlu~mixedint+mpi~openmp+shared~superlu-dist arch=linux-ubuntu18.04-x86_64
       ^openblas@0.3.7%gcc@7.4.0+avx2~avx512 cpu_target=auto ~ilp64+pic+shared threads=none ~virtual_machine arch=linux-ubuntu18.04-x86_64
       ^openmpi@3.1.4%gcc@7.4.0~cuda+cxx_exceptions fabrics=none ~java~legacylaunchers~memchecker~pmi schedulers=none ~sqlite3~thread_multiple+vt arch=linux-ubuntu18.04-x86_64
           ^hwloc@1.11.11%gcc@7.4.0~cairo~cuda~gl+libxml2~nvml+pci+shared arch=linux-ubuntu18.04-x86_64
               ^libpciaccess@0.13.5%gcc@7.4.0 arch=linux-ubuntu18.04-x86_64
                   ^libtool@2.4.6%gcc@7.4.0 arch=linux-ubuntu18.04-x86_64
                       ^m4@1.4.18%gcc@7.4.0 patches=3877ab548f88597ab2327a2230ee048d2d07ace1062efe81fc92e91b7f39cd00,fc9b61654a3ba1a8d6cd78ce087e7c96366c290bc8d2c299f09828d793b853c8 +sigsegv arch=linux-ubuntu18.04-x86_64
                           ^libsigsegv@2.12%gcc@7.4.0 arch=linux-ubuntu18.04-x86_64
                   ^pkgconf@1.6.3%gcc@7.4.0 arch=linux-ubuntu18.04-x86_64
                   ^util-macros@1.19.1%gcc@7.4.0 arch=linux-ubuntu18.04-x86_64
               ^libxml2@2.9.9%gcc@7.4.0~python arch=linux-ubuntu18.04-x86_64
                   ^libiconv@1.16%gcc@7.4.0 arch=linux-ubuntu18.04-x86_64
                   ^xz@5.2.4%gcc@7.4.0 arch=linux-ubuntu18.04-x86_64
                   ^zlib@1.2.11%gcc@7.4.0+optimize+pic+shared arch=linux-ubuntu18.04-x86_64
               ^numactl@2.0.12%gcc@7.4.0 arch=linux-ubuntu18.04-x86_64
                   ^autoconf@2.69%gcc@7.4.0 arch=linux-ubuntu18.04-x86_64
                       ^perl@5.30.0%gcc@7.4.0+cpanm+shared+threads arch=linux-ubuntu18.04-x86_64
                           ^gdbm@1.18.1%gcc@7.4.0 arch=linux-ubuntu18.04-x86_64
                               ^readline@8.0%gcc@7.4.0 arch=linux-ubuntu18.04-x86_64
                                   ^ncurses@6.1%gcc@7.4.0~symlinks~termlib arch=linux-ubuntu18.04-x86_64
                   ^automake@1.16.1%gcc@7.4.0 arch=linux-ubuntu18.04-x86_64

You may want to add extra configuration to your environment.  You can see
how your environment is configured using ``spack config get``:

.. code-block:: console

   $ spack config get
   # This is a Spack Environment file.
   #
   # It describes a set of packages to be installed, along with
   # configuration settings.
   spack:
     # add package specs to the `specs` list
     specs: [tcl, trilinos, hdf5+hl, gmp]
     view: true

It turns out that this is a special configuration format where Spack
stores the state for the environment. Currently, the file is just a
``spack:`` header and a list of ``specs``.  These are the roots.

You can edit this file to add your own custom configuration.  Spack
provides a shortcut to do that:

.. code-block:: console

   spack config edit

You should now see the same file, and edit it to look like this:

.. code-block:: yaml

   # This is a Spack Environment file.
   #
   # It describes a set of packages to be installed, along with
   # configuration settings.
   spack:
     packages:
       all:
         providers:
           mpi: [mpich]

     # add package specs to the `specs` list
     specs: [tcl, trilinos, hdf5, gmp]

Now if we run ``spack spec`` again in the environment, specs will concretize with ``mpich`` as the MPI implementation:

.. code-block:: console

   $ spack spec hypre
   Input spec
   --------------------------------
   hypre

   Concretized
   --------------------------------
   hypre@2.18.1%gcc@7.4.0~complex~debug~int64~internal-superlu~mixedint+mpi~openmp+shared~superlu-dist arch=linux-ubuntu18.04-x86_64
       ^mpich@3.3.1%gcc@7.4.0 device=ch3 +hydra netmod=tcp +pci pmi=pmi +romio~slurm~verbs+wrapperrpath arch=linux-ubuntu18.04-x86_64
           ^findutils@4.6.0%gcc@7.4.0 patches=84b916c0bf8c51b7e7b28417692f0ad3e7030d1f3c248ba77c42ede5c1c5d11e,bd9e4e5cc280f9753ae14956c4e4aa17fe7a210f55dd6c84aa60b12d106d47a2 arch=linux-ubuntu18.04-x86_64
               ^autoconf@2.69%gcc@7.4.0 arch=linux-ubuntu18.04-x86_64
                   ^m4@1.4.18%gcc@7.4.0 patches=3877ab548f88597ab2327a2230ee048d2d07ace1062efe81fc92e91b7f39cd00,fc9b61654a3ba1a8d6cd78ce087e7c96366c290bc8d2c299f09828d793b853c8 +sigsegv arch=linux-ubuntu18.04-x86_64
                       ^libsigsegv@2.12%gcc@7.4.0 arch=linux-ubuntu18.04-x86_64
                   ^perl@5.30.0%gcc@7.4.0+cpanm+shared+threads arch=linux-ubuntu18.04-x86_64
                       ^gdbm@1.18.1%gcc@7.4.0 arch=linux-ubuntu18.04-x86_64
                           ^readline@8.0%gcc@7.4.0 arch=linux-ubuntu18.04-x86_64
                               ^ncurses@6.1%gcc@7.4.0~symlinks~termlib arch=linux-ubuntu18.04-x86_64
                                   ^pkgconf@1.6.3%gcc@7.4.0 arch=linux-ubuntu18.04-x86_64
               ^automake@1.16.1%gcc@7.4.0 arch=linux-ubuntu18.04-x86_64
               ^libtool@2.4.6%gcc@7.4.0 arch=linux-ubuntu18.04-x86_64
               ^texinfo@6.5%gcc@7.4.0 arch=linux-ubuntu18.04-x86_64
           ^libpciaccess@0.13.5%gcc@7.4.0 arch=linux-ubuntu18.04-x86_64
               ^util-macros@1.19.1%gcc@7.4.0 arch=linux-ubuntu18.04-x86_64
           ^libxml2@2.9.9%gcc@7.4.0~python arch=linux-ubuntu18.04-x86_64
               ^libiconv@1.16%gcc@7.4.0 arch=linux-ubuntu18.04-x86_64
               ^xz@5.2.4%gcc@7.4.0 arch=linux-ubuntu18.04-x86_64
               ^zlib@1.2.11%gcc@7.4.0+optimize+pic+shared arch=linux-ubuntu18.04-x86_64
       ^openblas@0.3.7%gcc@7.4.0+avx2~avx512 cpu_target=auto ~ilp64+pic+shared threads=none ~virtual_machine arch=linux-ubuntu18.04-x86_64

In addition to the ``specs`` section, an environment's configuration can
contain any of the configuration options from Spack's various config
sections. You can add custom repositories, a custom install location,
custom compilers, or custom external packages, in addition to the ``package``
preferences we show here.

But now we have a problem.  We already installed part of this environment
with openmpi, but now we want to install it with ``mpich``.

You can run ``spack concretize`` inside of an environment to concretize
all of its specs.  We can run it here:

.. code-block:: console

   $ spack concretize -f
   ==> Concretized tcl
   [+]  t3gp773  tcl@8.6.8%gcc@7.4.0 arch=linux-ubuntu18.04-x86_64
   [+]  o2viq7y      ^zlib@1.2.11%gcc@7.4.0+optimize+pic+shared arch=linux-ubuntu18.04-x86_64

   ==> Concretized trilinos
   [+]  ioo4i64  trilinos@12.14.1%gcc@7.4.0~adios2~alloptpkgs+amesos+amesos2+anasazi+aztec+belos+boost build_type=RelWithDebInfo ~cgns~chaco~complex~debug~dtk+epetra+epetraext+exodus+explicit_template_instantiation~float+fortran~fortrilinos+gtest+hdf5+hypre+ifpack+ifpack2~intrepid~intrepid2~isorropia+kokkos+metis~minitensor+ml+muelu+mumps~nox~openmp~phalanx~piro~pnetcdf~python~rol~rythmos+sacado~shards+shared~shylu~stk+suite-sparse~superlu~superlu-dist~teko~tempus+teuchos+tpetra~x11~xsdkflags~zlib+zoltan+zoltan2 arch=linux-ubuntu18.04-x86_64
   [+]  d42gtzk      ^boost@1.70.0%gcc@7.4.0+atomic+chrono~clanglibcpp~context~coroutine cxxstd=98 +date_time~debug+exception~fiber+filesystem+graph~icu+iostreams+locale+log+math~mpi+multithreaded~numpy patches=2ab6c72d03dec6a4ae20220a9dfd5c8c572c5294252155b85c6874d97c323199 ~pic+program_options~python+random+regex+serialization+shared+signals~singlethreaded+system~taggedlayout+test+thread+timer~versionedlayout visibility=hidden +wave arch=linux-ubuntu18.04-x86_64
   [+]  g2ghsbb          ^bzip2@1.0.8%gcc@7.4.0+shared arch=linux-ubuntu18.04-x86_64
   [+]  vku7yph              ^diffutils@3.7%gcc@7.4.0 arch=linux-ubuntu18.04-x86_64
   [+]  zvmmgjb                  ^libiconv@1.16%gcc@7.4.0 arch=linux-ubuntu18.04-x86_64
   [+]  o2viq7y          ^zlib@1.2.11%gcc@7.4.0+optimize+pic+shared arch=linux-ubuntu18.04-x86_64
   [+]  3wkiwji      ^cmake@3.15.4%gcc@7.4.0~doc+ncurses+openssl+ownlibs~qt arch=linux-ubuntu18.04-x86_64
   [+]  s4rsior          ^ncurses@6.1%gcc@7.4.0~symlinks~termlib arch=linux-ubuntu18.04-x86_64
   [+]  eifxmps              ^pkgconf@1.6.3%gcc@7.4.0 arch=linux-ubuntu18.04-x86_64
   [+]  jujqjv5          ^openssl@1.1.1d%gcc@7.4.0+systemcerts arch=linux-ubuntu18.04-x86_64
   [+]  cxcj6ei              ^perl@5.30.0%gcc@7.4.0+cpanm+shared+threads arch=linux-ubuntu18.04-x86_64
   [+]  surdjxd                  ^gdbm@1.18.1%gcc@7.4.0 arch=linux-ubuntu18.04-x86_64
   [+]  hzwkvqa                      ^readline@8.0%gcc@7.4.0 arch=linux-ubuntu18.04-x86_64
   [+]  4zyyrqs      ^glm@0.9.7.1%gcc@7.4.0 build_type=RelWithDebInfo arch=linux-ubuntu18.04-x86_64
   [+]  c24mwwt      ^hdf5@1.10.5%gcc@7.4.0~cxx~debug~fortran+hl+mpi patches=b61e2f058964ad85be6ee5ecea10080bf79e73f83ff88d1fa4b602d00209da9c +pic+shared~szip~threadsafe arch=linux-ubuntu18.04-x86_64
   [+]  6e3rvex          ^mpich@3.3.1%gcc@7.4.0 device=ch3 +hydra netmod=tcp +pci pmi=pmi +romio~slurm~verbs+wrapperrpath arch=linux-ubuntu18.04-x86_64
   [+]  uf3gw7k              ^findutils@4.6.0%gcc@7.4.0 patches=84b916c0bf8c51b7e7b28417692f0ad3e7030d1f3c248ba77c42ede5c1c5d11e,bd9e4e5cc280f9753ae14956c4e4aa17fe7a210f55dd6c84aa60b12d106d47a2 arch=linux-ubuntu18.04-x86_64
   [+]  g23qful                  ^autoconf@2.69%gcc@7.4.0 arch=linux-ubuntu18.04-x86_64
   [+]  ut64la6                      ^m4@1.4.18%gcc@7.4.0 patches=3877ab548f88597ab2327a2230ee048d2d07ace1062efe81fc92e91b7f39cd00,fc9b61654a3ba1a8d6cd78ce087e7c96366c290bc8d2c299f09828d793b853c8 +sigsegv arch=linux-ubuntu18.04-x86_64
   [+]  3khohgm                          ^libsigsegv@2.12%gcc@7.4.0 arch=linux-ubuntu18.04-x86_64
   [+]  io3tplo                  ^automake@1.16.1%gcc@7.4.0 arch=linux-ubuntu18.04-x86_64
   [+]  4neu5jw                  ^libtool@2.4.6%gcc@7.4.0 arch=linux-ubuntu18.04-x86_64
   [+]  hyetop5                  ^texinfo@6.5%gcc@7.4.0 arch=linux-ubuntu18.04-x86_64
   [+]  vhehc32              ^libpciaccess@0.13.5%gcc@7.4.0 arch=linux-ubuntu18.04-x86_64
   [+]  a226ran                  ^util-macros@1.19.1%gcc@7.4.0 arch=linux-ubuntu18.04-x86_64
   [+]  fg5evg4              ^libxml2@2.9.9%gcc@7.4.0~python arch=linux-ubuntu18.04-x86_64
   [+]  ur2jffe                  ^xz@5.2.4%gcc@7.4.0 arch=linux-ubuntu18.04-x86_64
   [+]  ubwkr5u      ^hypre@2.18.1%gcc@7.4.0~complex~debug~int64~internal-superlu~mixedint+mpi~openmp+shared~superlu-dist arch=linux-ubuntu18.04-x86_64
   [+]  jepvsjb          ^openblas@0.3.7%gcc@7.4.0+avx2~avx512 cpu_target=auto ~ilp64+pic+shared threads=none ~virtual_machine arch=linux-ubuntu18.04-x86_64
   [+]  mexumm4      ^matio@1.5.13%gcc@7.4.0+hdf5+shared+zlib arch=linux-ubuntu18.04-x86_64
   [+]  q6wvktu      ^metis@5.1.0%gcc@7.4.0 build_type=Release ~gdb~int64 patches=4991da938c1d3a1d3dea78e49bbebecba00273f98df2a656e38b83d55b281da1,b1225da886605ea558db7ac08dd8054742ea5afe5ed61ad4d0fe7a495b1270d2 ~real64+shared arch=linux-ubuntu18.04-x86_64
   [+]  nippo7j      ^mumps@5.2.0%gcc@7.4.0+complex+double+float~int64~metis+mpi~parmetis~ptscotch~scotch+shared arch=linux-ubuntu18.04-x86_64
   [+]  tbp3lv6          ^netlib-scalapack@2.0.2%gcc@7.4.0 build_type=RelWithDebInfo patches=22ebf4e3d5a6356cd6086ea65bfdf30f9d0a2038136127590cd269d15bdb03af,e8f30dd1f26e523dfb552f8d7b8ad26ac88fc0c8d72e3d4f9a9717a3383e0b33 ~pic+shared arch=linux-ubuntu18.04-x86_64
   [+]  vx6vje7      ^netcdf@4.7.1%gcc@7.4.0~dap~hdf4 maxdims=1024 maxvars=8192 +mpi~parallel-netcdf+pic+shared arch=linux-ubuntu18.04-x86_64
   [+]  t6gxi6e      ^parmetis@4.0.3%gcc@7.4.0 build_type=RelWithDebInfo ~gdb patches=4f892531eb0a807eb1b82e683a416d3e35154a455274cf9b162fb02054d11a5b,50ed2081bc939269689789942067c58b3e522c269269a430d5d34c00edbc5870,704b84f7c7444d4372cb59cca6e1209df4ef3b033bc4ee3cf50f369bce972a9d +shared arch=linux-ubuntu18.04-x86_64
   [+]  3jghv4q      ^suite-sparse@5.3.0%gcc@7.4.0~cuda~openmp+pic~tbb arch=linux-ubuntu18.04-x86_64

   ==> Concretized hdf5+hl
   [+]  c24mwwt  hdf5@1.10.5%gcc@7.4.0~cxx~debug~fortran+hl+mpi patches=b61e2f058964ad85be6ee5ecea10080bf79e73f83ff88d1fa4b602d00209da9c +pic+shared~szip~threadsafe arch=linux-ubuntu18.04-x86_64
   [+]  6e3rvex      ^mpich@3.3.1%gcc@7.4.0 device=ch3 +hydra netmod=tcp +pci pmi=pmi +romio~slurm~verbs+wrapperrpath arch=linux-ubuntu18.04-x86_64
   [+]  uf3gw7k          ^findutils@4.6.0%gcc@7.4.0 patches=84b916c0bf8c51b7e7b28417692f0ad3e7030d1f3c248ba77c42ede5c1c5d11e,bd9e4e5cc280f9753ae14956c4e4aa17fe7a210f55dd6c84aa60b12d106d47a2 arch=linux-ubuntu18.04-x86_64
   [+]  g23qful              ^autoconf@2.69%gcc@7.4.0 arch=linux-ubuntu18.04-x86_64
   [+]  ut64la6                  ^m4@1.4.18%gcc@7.4.0 patches=3877ab548f88597ab2327a2230ee048d2d07ace1062efe81fc92e91b7f39cd00,fc9b61654a3ba1a8d6cd78ce087e7c96366c290bc8d2c299f09828d793b853c8 +sigsegv arch=linux-ubuntu18.04-x86_64
   [+]  3khohgm                      ^libsigsegv@2.12%gcc@7.4.0 arch=linux-ubuntu18.04-x86_64
   [+]  cxcj6ei                  ^perl@5.30.0%gcc@7.4.0+cpanm+shared+threads arch=linux-ubuntu18.04-x86_64
   [+]  surdjxd                      ^gdbm@1.18.1%gcc@7.4.0 arch=linux-ubuntu18.04-x86_64
   [+]  hzwkvqa                          ^readline@8.0%gcc@7.4.0 arch=linux-ubuntu18.04-x86_64
   [+]  s4rsior                              ^ncurses@6.1%gcc@7.4.0~symlinks~termlib arch=linux-ubuntu18.04-x86_64
   [+]  eifxmps                                  ^pkgconf@1.6.3%gcc@7.4.0 arch=linux-ubuntu18.04-x86_64
   [+]  io3tplo              ^automake@1.16.1%gcc@7.4.0 arch=linux-ubuntu18.04-x86_64
   [+]  4neu5jw              ^libtool@2.4.6%gcc@7.4.0 arch=linux-ubuntu18.04-x86_64
   [+]  hyetop5              ^texinfo@6.5%gcc@7.4.0 arch=linux-ubuntu18.04-x86_64
   [+]  vhehc32          ^libpciaccess@0.13.5%gcc@7.4.0 arch=linux-ubuntu18.04-x86_64
   [+]  a226ran              ^util-macros@1.19.1%gcc@7.4.0 arch=linux-ubuntu18.04-x86_64
   [+]  fg5evg4          ^libxml2@2.9.9%gcc@7.4.0~python arch=linux-ubuntu18.04-x86_64
   [+]  zvmmgjb              ^libiconv@1.16%gcc@7.4.0 arch=linux-ubuntu18.04-x86_64
   [+]  ur2jffe              ^xz@5.2.4%gcc@7.4.0 arch=linux-ubuntu18.04-x86_64
   [+]  o2viq7y              ^zlib@1.2.11%gcc@7.4.0+optimize+pic+shared arch=linux-ubuntu18.04-x86_64

   ==> Concretized gmp
   [+]  fz3lzqi  gmp@6.1.2%gcc@7.4.0 arch=linux-ubuntu18.04-x86_64
   [+]  g23qful      ^autoconf@2.69%gcc@7.4.0 arch=linux-ubuntu18.04-x86_64
   [+]  ut64la6          ^m4@1.4.18%gcc@7.4.0 patches=3877ab548f88597ab2327a2230ee048d2d07ace1062efe81fc92e91b7f39cd00,fc9b61654a3ba1a8d6cd78ce087e7c96366c290bc8d2c299f09828d793b853c8 +sigsegv arch=linux-ubuntu18.04-x86_64
   [+]  3khohgm              ^libsigsegv@2.12%gcc@7.4.0 arch=linux-ubuntu18.04-x86_64
   [+]  cxcj6ei          ^perl@5.30.0%gcc@7.4.0+cpanm+shared+threads arch=linux-ubuntu18.04-x86_64
   [+]  surdjxd              ^gdbm@1.18.1%gcc@7.4.0 arch=linux-ubuntu18.04-x86_64
   [+]  hzwkvqa                  ^readline@8.0%gcc@7.4.0 arch=linux-ubuntu18.04-x86_64
   [+]  s4rsior                      ^ncurses@6.1%gcc@7.4.0~symlinks~termlib arch=linux-ubuntu18.04-x86_64
   [+]  eifxmps                          ^pkgconf@1.6.3%gcc@7.4.0 arch=linux-ubuntu18.04-x86_64
   [+]  io3tplo      ^automake@1.16.1%gcc@7.4.0 arch=linux-ubuntu18.04-x86_64
   [+]  4neu5jw      ^libtool@2.4.6%gcc@7.4.0 arch=linux-ubuntu18.04-x86_64

   ==> Updating view at /home/spack1/spack/var/spack/environments/myproject/.spack-env/view

Now, all the specs in the environment are concrete and ready to be
installed with ``mpich`` as the MPI implementation.

Normally, we could just run ``spack config edit``, edit the environment
configuration, ``spack add`` some specs, and ``spack install``.

But, when we already have installed packages in the environment, we have
to force everything in the environment to be re-concretized using ``spack
concretize -f``.  *Then* we can re-run ``spack install``.


---------------------------------
Building in environments
---------------------------------

You've already learned about ``spack dev-build`` as a way to build a project
you've already checked out.  You can also use environments to set up a
development environment.  As mentioned, you can use any of the binaries in
the environment's view:

.. code-block:: console

   $ spack env status
   ==> In environment myproject
   $ which mpicc
   /home/spack1/spack/var/spack/environments/myproject/.spack-env/view/bin/mpicc

Spack also sets variables like ``CPATH``, ``LIBRARY_PATH``,
and ``LD_LIBRARY_PATH`` so that you can easily find headers and libraries in
environemnts.

.. code-block:: console

   $ env | grep PATH=
   LD_LIBRARY_PATH=/home/spack1/spack/var/spack/environments/myproject/.spack-env/view/lib:/home/spack1/spack/var/spack/environments/myproject/.spack-env/view/lib64
   CMAKE_PREFIX_PATH=/home/spack1/spack/var/spack/environments/myproject/.spack-env/view
   CPATH=/home/spack1/spack/var/spack/environments/myproject/.spack-env/view/include
   LIBRARY_PATH=/home/spack1/spack/var/spack/environments/myproject/.spack-env/view/lib:/home/spack1/spack/var/spack/environments/myproject/.spack-env/view/lib64
   ACLOCAL_PATH=/home/spack1/spack/var/spack/environments/myproject/.spack-env/view/share/aclocal
   MANPATH=/home/spack1/spack/var/spack/environments/myproject/.spack-env/view/share/man:/home/spack1/spack/var/spack/environments/myproject/.spack-env/view/man
   MODULEPATH=/home/spack1/spack/share/spack/modules/linux-ubuntu18.04-x86_64
   PATH=/home/spack1/spack/var/spack/environments/myproject/.spack-env/view/bin:/home/spack1/spack/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games:/snap/bin
   PKG_CONFIG_PATH=/home/spack1/spack/var/spack/environments/myproject/.spack-env/view/lib/pkgconfig:/home/spack1/spack/var/spack/environments/myproject/.spack-env/view/lib64/pkgconfig

We can use this to easily build programs.  Let's build a really simple MPI program
using this environment.  Make a simple test program like this one.  Call it ``mpi-hello.c``.

.. code-block:: c

	#include <stdio.h>
	#include <mpi.h>
	#include <zlib.h>

	int main(int argc, char **argv) {
	  int rank;
	  MPI_Init(&argc, &argv);

	  MPI_Comm_rank(MPI_COMM_WORLD, &rank);
	  printf("Hello world from rank %d\n", rank);

	  if (rank == 0) {
	    printf("zlib version: %s\n", ZLIB_VERSION);
	  }

	  MPI_Finalize();
	}

This program includes a header from zlib, and prints out a message from each MPI rank.
It also prints the zlib version.

All you need to do is build and run it:

.. code-block: console

    $ mpicc ./mpi-hello.c
    $ mpirun -n 4 ./a.out
    Hello world from rank 0
    zlib version: 1.2.11
    Hello world from rank 2
    Hello world from rank 1
    Hello world from rank 3

Note that we did not need to pass any special arguments to the compiler; just
the source file.  This simple example only scratches the surface, but you
can use environments to set up dependencies for a project, set up a run
environment for a user, support your usual development environment, and
many other use cases.


---------------------------------
``spack.yaml`` and ``spack.lock``
---------------------------------

So far we've shown you how to interact with environments from the command
line, but they also have a file-based interface that can be used by
developers and admins to manage workflows for projects.

In this section we'll dive a little deeper to see how environments are
implemented, and how you could use this in your day-to-day development.

^^^^^^^^^^^^^^
``spack.yaml``
^^^^^^^^^^^^^^

Earlier, we changed an environment's configuration using ``spack config
edit``.  We were actually editing a special file called ``spack.yaml``.
Let's take a look.

We can get directly to the current environment's location using ``spack cd``:

.. code-block:: console

   $ spack cd -e myproject
   $ pwd
   /home/spack1/spack/var/spack/environments/myproject
   $ ls
   spack.lock  spack.yaml

We notice two things here.  First, the environment is just a directory
inside of ``var/spack/environments`` within the Spack installation.
Second, it contains two important files: ``spack.yaml`` and
``spack.lock``.

``spack.yaml`` is the configuration file for environments that we've
already seen, but it does not *have* to live inside Spack.  If you create
an environment using ``spack env create``, it is *managed* by
Spack in the ``var/spack/environments`` directory, and you can refer to
it by name.

You can actually put a ``spack.yaml`` file *anywhere*, and you can use it
to bundle an environment, or a list of dependencies to install, with your
project.  Let's make a simple project:

.. code-block:: console

   $ cd
   $ mkdir code
   $ cd code
   $ spack env create -d .
   ==> Created environment in ~/code

Here, we made a new directory called *code*, and we used the ``-d``
option to create an environment in it.

What really happened?

.. code-block:: console

   $ ls
   spack.yaml
   $ cat spack.yaml
   # This is a Spack Environment file.
   #
   # It describes a set of packages to be installed, along with
   # configuration settings.
   spack:
     # add package specs to the `specs` list
     specs: []

Spack just created a ``spack.yaml`` file in the code directory, with an
empty list of root specs.  Now we have a Spack environment, *in a
directory*, that we can use to manage dependencies.  Suppose your project
depends on ``boost``, ``trilinos``, and ``openmpi``.  You can add these
to your spec list:

.. code-block:: yaml

   # This is a Spack Environment file.
   #
   # It describes a set of packages to be installed, along with
   # configuration settings.
   spack:
     # add package specs to the `specs` list
     specs:
     - boost
     - trilinos
     - openmpi

And now *anyone* who uses the *code* repository can use this format to
install the project's dependencies.  They need only clone the repository,
``cd`` into it, and type ``spack install``:

.. code-block:: console

   $ spack install
   ==> Concretized boost
   [+]  d42gtzk  boost@1.70.0%gcc@7.4.0+atomic+chrono~clanglibcpp~context~coroutine cxxstd=98 +date_time~debug+exception~fiber+filesystem+graph~icu+iostreams+locale+log+math~mpi+multithreaded~numpy patches=2ab6c72d03dec6a4ae20220a9dfd5c8c572c5294252155b85c6874d97c323199 ~pic+program_options~python+random+regex+serialization+shared+signals~singlethreaded+system~taggedlayout+test+thread+timer~versionedlayout visibility=hidden +wave arch=linux-ubuntu18.04-x86_64
   [+]  g2ghsbb      ^bzip2@1.0.8%gcc@7.4.0+shared arch=linux-ubuntu18.04-x86_64
   [+]  vku7yph          ^diffutils@3.7%gcc@7.4.0 arch=linux-ubuntu18.04-x86_64
   [+]  zvmmgjb              ^libiconv@1.16%gcc@7.4.0 arch=linux-ubuntu18.04-x86_64
   [+]  o2viq7y      ^zlib@1.2.11%gcc@7.4.0+optimize+pic+shared arch=linux-ubuntu18.04-x86_64

   ==> Concretized trilinos
   [+]  mpalhkt  trilinos@12.14.1%gcc@7.4.0~adios2~alloptpkgs+amesos+amesos2+anasazi+aztec+belos+boost build_type=RelWithDebInfo ~cgns~chaco~complex~debug~dtk+epetra+epetraext+exodus+explicit_template_instantiation~float+fortran~fortrilinos+gtest+hdf5+hypre+ifpack+ifpack2~intrepid~intrepid2~isorropia+kokkos+metis~minitensor+ml+muelu+mumps~nox~openmp~phalanx~piro~pnetcdf~python~rol~rythmos+sacado~shards+shared~shylu~stk+suite-sparse~superlu~superlu-dist~teko~tempus+teuchos+tpetra~x11~xsdkflags~zlib+zoltan+zoltan2 arch=linux-ubuntu18.04-x86_64
   [+]  d42gtzk      ^boost@1.70.0%gcc@7.4.0+atomic+chrono~clanglibcpp~context~coroutine cxxstd=98 +date_time~debug+exception~fiber+filesystem+graph~icu+iostreams+locale+log+math~mpi+multithreaded~numpy patches=2ab6c72d03dec6a4ae20220a9dfd5c8c572c5294252155b85c6874d97c323199 ~pic+program_options~python+random+regex+serialization+shared+signals~singlethreaded+system~taggedlayout+test+thread+timer~versionedlayout visibility=hidden +wave arch=linux-ubuntu18.04-x86_64
   [+]  g2ghsbb          ^bzip2@1.0.8%gcc@7.4.0+shared arch=linux-ubuntu18.04-x86_64
   [+]  vku7yph              ^diffutils@3.7%gcc@7.4.0 arch=linux-ubuntu18.04-x86_64
   [+]  zvmmgjb                  ^libiconv@1.16%gcc@7.4.0 arch=linux-ubuntu18.04-x86_64
   [+]  o2viq7y          ^zlib@1.2.11%gcc@7.4.0+optimize+pic+shared arch=linux-ubuntu18.04-x86_64
   [+]  3wkiwji      ^cmake@3.15.4%gcc@7.4.0~doc+ncurses+openssl+ownlibs~qt arch=linux-ubuntu18.04-x86_64
   [+]  s4rsior          ^ncurses@6.1%gcc@7.4.0~symlinks~termlib arch=linux-ubuntu18.04-x86_64
   [+]  eifxmps              ^pkgconf@1.6.3%gcc@7.4.0 arch=linux-ubuntu18.04-x86_64
   [+]  jujqjv5          ^openssl@1.1.1d%gcc@7.4.0+systemcerts arch=linux-ubuntu18.04-x86_64
   [+]  cxcj6ei              ^perl@5.30.0%gcc@7.4.0+cpanm+shared+threads arch=linux-ubuntu18.04-x86_64
   [+]  surdjxd                  ^gdbm@1.18.1%gcc@7.4.0 arch=linux-ubuntu18.04-x86_64
   [+]  hzwkvqa                      ^readline@8.0%gcc@7.4.0 arch=linux-ubuntu18.04-x86_64
   [+]  4zyyrqs      ^glm@0.9.7.1%gcc@7.4.0 build_type=RelWithDebInfo arch=linux-ubuntu18.04-x86_64
   [+]  65cucf4      ^hdf5@1.10.5%gcc@7.4.0~cxx~debug~fortran+hl+mpi patches=b61e2f058964ad85be6ee5ecea10080bf79e73f83ff88d1fa4b602d00209da9c +pic+shared~szip~threadsafe arch=linux-ubuntu18.04-x86_64
   [+]  f6maodn          ^openmpi@3.1.4%gcc@7.4.0~cuda+cxx_exceptions fabrics=none ~java~legacylaunchers~memchecker~pmi schedulers=none ~sqlite3~thread_multiple+vt arch=linux-ubuntu18.04-x86_64
   [+]  xcjsxcr              ^hwloc@1.11.11%gcc@7.4.0~cairo~cuda~gl+libxml2~nvml+pci+shared arch=linux-ubuntu18.04-x86_64
   [+]  vhehc32                  ^libpciaccess@0.13.5%gcc@7.4.0 arch=linux-ubuntu18.04-x86_64
   [+]  4neu5jw                      ^libtool@2.4.6%gcc@7.4.0 arch=linux-ubuntu18.04-x86_64
   [+]  ut64la6                          ^m4@1.4.18%gcc@7.4.0 patches=3877ab548f88597ab2327a2230ee048d2d07ace1062efe81fc92e91b7f39cd00,fc9b61654a3ba1a8d6cd78ce087e7c96366c290bc8d2c299f09828d793b853c8 +sigsegv arch=linux-ubuntu18.04-x86_64
   [+]  3khohgm                              ^libsigsegv@2.12%gcc@7.4.0 arch=linux-ubuntu18.04-x86_64
   [+]  a226ran                      ^util-macros@1.19.1%gcc@7.4.0 arch=linux-ubuntu18.04-x86_64
   [+]  fg5evg4                  ^libxml2@2.9.9%gcc@7.4.0~python arch=linux-ubuntu18.04-x86_64
   [+]  ur2jffe                      ^xz@5.2.4%gcc@7.4.0 arch=linux-ubuntu18.04-x86_64
   [+]  n6yyt2y                  ^numactl@2.0.12%gcc@7.4.0 arch=linux-ubuntu18.04-x86_64
   [+]  g23qful                      ^autoconf@2.69%gcc@7.4.0 arch=linux-ubuntu18.04-x86_64
   [+]  io3tplo                      ^automake@1.16.1%gcc@7.4.0 arch=linux-ubuntu18.04-x86_64
   [+]  gsuceum      ^hypre@2.18.1%gcc@7.4.0~complex~debug~int64~internal-superlu~mixedint+mpi~openmp+shared~superlu-dist arch=linux-ubuntu18.04-x86_64
   [+]  jepvsjb          ^openblas@0.3.7%gcc@7.4.0+avx2~avx512 cpu_target=auto ~ilp64+pic+shared threads=none ~virtual_machine arch=linux-ubuntu18.04-x86_64
   [+]  7643xwi      ^matio@1.5.13%gcc@7.4.0+hdf5+shared+zlib arch=linux-ubuntu18.04-x86_64
   [+]  q6wvktu      ^metis@5.1.0%gcc@7.4.0 build_type=Release ~gdb~int64 patches=4991da938c1d3a1d3dea78e49bbebecba00273f98df2a656e38b83d55b281da1,b1225da886605ea558db7ac08dd8054742ea5afe5ed61ad4d0fe7a495b1270d2 ~real64+shared arch=linux-ubuntu18.04-x86_64
   [+]  s2ezmwe      ^mumps@5.2.0%gcc@7.4.0+complex+double+float~int64~metis+mpi~parmetis~ptscotch~scotch+shared arch=linux-ubuntu18.04-x86_64
   [+]  gfcwr4d          ^netlib-scalapack@2.0.2%gcc@7.4.0 build_type=RelWithDebInfo patches=22ebf4e3d5a6356cd6086ea65bfdf30f9d0a2038136127590cd269d15bdb03af,e8f30dd1f26e523dfb552f8d7b8ad26ac88fc0c8d72e3d4f9a9717a3383e0b33 ~pic+shared arch=linux-ubuntu18.04-x86_64
   [+]  t6uuk2x      ^netcdf@4.7.1%gcc@7.4.0~dap~hdf4 maxdims=1024 maxvars=8192 +mpi~parallel-netcdf+pic+shared arch=linux-ubuntu18.04-x86_64
   [+]  khzaszh      ^parmetis@4.0.3%gcc@7.4.0 build_type=RelWithDebInfo ~gdb patches=4f892531eb0a807eb1b82e683a416d3e35154a455274cf9b162fb02054d11a5b,50ed2081bc939269689789942067c58b3e522c269269a430d5d34c00edbc5870,704b84f7c7444d4372cb59cca6e1209df4ef3b033bc4ee3cf50f369bce972a9d +shared arch=linux-ubuntu18.04-x86_64
   [+]  3jghv4q      ^suite-sparse@5.3.0%gcc@7.4.0~cuda~openmp+pic~tbb arch=linux-ubuntu18.04-x86_64

   ==> Concretized openmpi
   [+]  f6maodn  openmpi@3.1.4%gcc@7.4.0~cuda+cxx_exceptions fabrics=none ~java~legacylaunchers~memchecker~pmi schedulers=none ~sqlite3~thread_multiple+vt arch=linux-ubuntu18.04-x86_64
   [+]  xcjsxcr      ^hwloc@1.11.11%gcc@7.4.0~cairo~cuda~gl+libxml2~nvml+pci+shared arch=linux-ubuntu18.04-x86_64
   [+]  vhehc32          ^libpciaccess@0.13.5%gcc@7.4.0 arch=linux-ubuntu18.04-x86_64
   [+]  4neu5jw              ^libtool@2.4.6%gcc@7.4.0 arch=linux-ubuntu18.04-x86_64
   [+]  ut64la6                  ^m4@1.4.18%gcc@7.4.0 patches=3877ab548f88597ab2327a2230ee048d2d07ace1062efe81fc92e91b7f39cd00,fc9b61654a3ba1a8d6cd78ce087e7c96366c290bc8d2c299f09828d793b853c8 +sigsegv arch=linux-ubuntu18.04-x86_64
   [+]  3khohgm                      ^libsigsegv@2.12%gcc@7.4.0 arch=linux-ubuntu18.04-x86_64
   [+]  eifxmps              ^pkgconf@1.6.3%gcc@7.4.0 arch=linux-ubuntu18.04-x86_64
   [+]  a226ran              ^util-macros@1.19.1%gcc@7.4.0 arch=linux-ubuntu18.04-x86_64
   [+]  fg5evg4          ^libxml2@2.9.9%gcc@7.4.0~python arch=linux-ubuntu18.04-x86_64
   [+]  zvmmgjb              ^libiconv@1.16%gcc@7.4.0 arch=linux-ubuntu18.04-x86_64
   [+]  ur2jffe              ^xz@5.2.4%gcc@7.4.0 arch=linux-ubuntu18.04-x86_64
   [+]  o2viq7y              ^zlib@1.2.11%gcc@7.4.0+optimize+pic+shared arch=linux-ubuntu18.04-x86_64
   [+]  n6yyt2y          ^numactl@2.0.12%gcc@7.4.0 arch=linux-ubuntu18.04-x86_64
   [+]  g23qful              ^autoconf@2.69%gcc@7.4.0 arch=linux-ubuntu18.04-x86_64
   [+]  cxcj6ei                  ^perl@5.30.0%gcc@7.4.0+cpanm+shared+threads arch=linux-ubuntu18.04-x86_64
   [+]  surdjxd                      ^gdbm@1.18.1%gcc@7.4.0 arch=linux-ubuntu18.04-x86_64
   [+]  hzwkvqa                          ^readline@8.0%gcc@7.4.0 arch=linux-ubuntu18.04-x86_64
   [+]  s4rsior                              ^ncurses@6.1%gcc@7.4.0~symlinks~termlib arch=linux-ubuntu18.04-x86_64
   [+]  io3tplo              ^automake@1.16.1%gcc@7.4.0 arch=linux-ubuntu18.04-x86_64

   ==> Updating view at /home/spack1/code/.spack-env/view
   ==> Installing environment /home/spack1/code
   ==> boost is already installed in /home/spack1/spack/opt/spack/linux-ubuntu18.04-x86_64/gcc-7.4.0/boost-1.70.0-d42gtzk7f4chkyjqyqbg5c7tkd3r375y
   ==> boost@1.70.0 : marking the package explicit
   ==> trilinos is already installed in /home/spack1/spack/opt/spack/linux-ubuntu18.04-x86_64/gcc-7.4.0/trilinos-12.14.1-mpalhktqqjjo2hayykb6ut2jyhkmow3z
   ==> openmpi is already installed in /home/spack1/spack/opt/spack/linux-ubuntu18.04-x86_64/gcc-7.4.0/openmpi-3.1.4-f6maodnm53tkmchq5woe33nt5wbt2tel
   ==> openmpi@3.1.4 : marking the package explicit
   ==> Updating view at /home/spack1/code/.spack-env/view


Spack concretizes the specs in the ``spack.yaml`` file and installs them.

What happened here?  If you ``cd`` into a directory that has a
``spack.yaml`` file in it, Spack considers this directory's environment
to be activated.  The directory does not have to live within Spack; it
can be anywhere.

So, from ``~/code``, we can actually manipulate ``spack.yaml`` using
``spack add`` and ``spack remove`` (just like managed environments):

.. code-block:: console

   $ spack add hdf5@5.5.1
   ==> Adding hdf5@5.5.1 to environment /home/spack1/code
   ==> Updating view at /home/spack1/code/.spack-env/view
   $ cat spack.yaml
   # This is a Spack Environment file.
   #
   # It describes a set of packages to be installed, along with
   # configuration settings.
   spack:
     # add package specs to the `specs` list
     specs:
     - boost
     - trilinos
     - openmpi
     - hdf5@5.5.1

   $ spack remove hdf5
   ==> Removing hdf5 from environment /home/spack1/code
   ==> Updating view at /home/spack1/code/.spack-env/view
   $ cat spack.yaml
   # This is a Spack Environment file.
   #
   # It describes a set of packages to be installed, along with
   # configuration settings.
   spack:
     # add package specs to the `specs` list
     specs:
     - boost
     - trilinos
     - openmpi


^^^^^^^^^^^^^^
``spack.lock``
^^^^^^^^^^^^^^

Okay, we've covered managed environments, environments in directories, and
the last thing we'll cover is ``spack.lock``. You may remember that when
we ran ``spack install``, Spack concretized all the specs in the
``spack.yaml`` file and installed them.

Whenever we concretize Specs in an environment, all concrete specs in the
environment are written out to a ``spack.lock`` file *alongside*
``spack.yaml``.  The ``spack.lock`` file is not really human-readable
like the ``spack.yaml`` file.  It is a ``json`` format that contains all
the information that we need to *reproduce* the build of an
environment:

.. code-block:: console

   $ head -30 spack.lock
   {
    "_meta": {
     "file-type": "spack-lockfile",
     "lockfile-version": 2
    },
    "roots": [
     {
      "hash": "wi3sbffok5yxurb26b72pvyzs2mqt4ys",
      "spec": "boost"
     },
     {
      "hash": "y6px5eztobm2igeebvnro447ye3btcgz",
      "spec": "trilinos"
     },
     {
      "hash": "piivh3gomhqjl6cudoevh76xvmrnkenj",
      "spec": "openmpi"
     }
    ],
    "concrete_specs": {
     "wi3sbffok5yxurb26b72pvyzs2mqt4ys": {
      "boost": {
       "version": "1.70.0",
       "arch": {
        "platform": "linux",
        "platform_os": "ubuntu18.04",
        "target": "x86_64"
       },
       "compiler": {
        "name": "gcc",
    ...

``spack.yaml`` and ``spack.lock`` correspond to two fundamental concepts
in Spack, but for environments:

  * ``spack.yaml`` is the set of *abstract* specs and configuration that
    you want to install.
  * ``spack.lock`` is the set of all fully *concretized* specs generated
    from concretizing ``spack.yaml``

Using either of these, you can recreate an environment that someone else
built.  ``spack env create`` takes an extra optional argument, which can
be either a ``spack.yaml`` or a ``spack.lock`` file:

.. code-block:: console

   $ spack env create my-project spack.yaml

   $ spack env create my-project spack.lock

Both of these create a new environment called ``my-project``, but which
one you choose to use depends on your needs:

#. copying the yaml file allows someone else to build your *requirements*,
   potentially a different way.

#. copying the lock file allows someone else to rebuild your
   *installation* exactly as you built it.

The first use case can *re-concretize* the same specs on new platforms in
order to build, but it will preserve the abstract requirements.  The
second use case (currently) requires you to be on the same machine, but
it retains all decisions made during concretization and is faithful to a
prior install.
