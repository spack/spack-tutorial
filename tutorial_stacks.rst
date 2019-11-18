.. Copyright 2013-2019 Lawrence Livermore National Security, LLC and other
   Spack Project Developers. See the top-level COPYRIGHT file for details.

   SPDX-License-Identifier: (Apache-2.0 OR MIT)

.. _stacks-tutorial:

===============
Stacks Tutorial
===============

So far, we've talked about Spack environments in the context of a
unified user environment or development environment. But environments
in Spack have much broader capabilities. In this tutorial we will
consider how to use a specialized sort of Spack environment, that we
call a Spack stack, to manage large deployments of software using
Spack.

------------
Spec matrics
------------

In a typical Spack environment for a single user, a simple list of
specs is sufficient. For software deployment, however, we often have a
set of packages we want to install across a wide range of
compilers. The simplest way to express this in Spack is through a
matrix. Let's edit our ``spack.yaml`` file again.

.. code-block:: yaml
  :emphasize-lines: 8-10,12

  # This is a Spack Environment file.
  #
  # It describes a set of packages to be installed, along with
  # configuration setings.
  spack:
    # add package specs to the `specs` list
    specs:
      - matrix:
          - [boost, trilinos, openmpi]
          - ['%gcc', '%clang']

    view: False

For now, we'll avoid the view directive. We'll come back to this
later.

This would lead to a lot of install time, so for the sake of time
we'll just concretize and look at the concrete specs for the rest of
this section.

.. code-block:: console

  $ spack concretize
  ==> Concretized boost%gcc
   -   d42gtzk  boost@1.70.0%gcc@7.4.0+atomic+chrono~clanglibcpp~context~coroutine cxxstd=98 +date_time~debug+exception~fiber+filesystem+graph~icu+iostreams+locale+log+math~mpi+multithreaded~numpy patches=2ab6c72d03dec6a4ae20220a9dfd5c8c572c5294252155b85c6874d97c323199 ~pic+program_options~python+random+regex+serialization+shared+signals~singlethreaded+system~taggedlayout+test+thread+timer~versionedlayout visibility=hidden +wave arch=linux-ubuntu18.04-x86_64
   -   g2ghsbb      ^bzip2@1.0.8%gcc@7.4.0+shared arch=linux-ubuntu18.04-x86_64
   -   vku7yph          ^diffutils@3.7%gcc@7.4.0 arch=linux-ubuntu18.04-x86_64
   -   zvmmgjb              ^libiconv@1.16%gcc@7.4.0 arch=linux-ubuntu18.04-x86_64
  [+]  o2viq7y      ^zlib@1.2.11%gcc@7.4.0+optimize+pic+shared arch=linux-ubuntu18.04-x86_64

  ==> Concretized boost%clang
   -   v232ezh  boost@1.70.0%clang@6.0.0+atomic+chrono~clanglibcpp~context~coroutine cxxstd=98 +date_time~debug+exception~fiber+filesystem+graph~icu+iostreams+locale+log+math~mpi+multithreaded~numpy patches=2ab6c72d03dec6a4ae20220a9dfd5c8c572c5294252155b85c6874d97c323199 ~pic+program_options~python+random+regex+serialization+shared+signals~singlethreaded+system~taggedlayout+test+thread+timer~versionedlayout visibility=hidden +wave arch=linux-ubuntu18.04-x86_64
   -   qxfbjyc      ^bzip2@1.0.8%clang@6.0.0+shared arch=linux-ubuntu18.04-x86_64
   -   sdvt7ef          ^diffutils@3.7%clang@6.0.0 arch=linux-ubuntu18.04-x86_64
   -   3fxiwph              ^libiconv@1.16%clang@6.0.0 arch=linux-ubuntu18.04-x86_64
   -   5qffmms      ^zlib@1.2.11%clang@6.0.0+optimize+pic+shared arch=linux-ubuntu18.04-x86_64

  ==> Concretized trilinos%gcc
   -   mpalhkt  trilinos@12.14.1%gcc@7.4.0~adios2~alloptpkgs+amesos+amesos2+anasazi+aztec+belos+boost build_type=RelWithDebInfo ~cgns~chaco~complex~debug~dtk+epetra+epetraext+exodus+explicit_template_instantiation~float+fortran~fortrilinos+gtest+hdf5+hypre+ifpack+ifpack2~intrepid~intrepid2~isorropia+kokkos+metis~minitensor+ml+muelu+mumps~nox~openmp~phalanx~piro~pnetcdf~python~rol~rythmos+sacado~shards+shared~shylu~stk+suite-sparse~superlu~superlu-dist~teko~tempus+teuchos+tpetra~x11~xsdkflags~zlib+zoltan+zoltan2 arch=linux-ubuntu18.04-x86_64
   -   d42gtzk      ^boost@1.70.0%gcc@7.4.0+atomic+chrono~clanglibcpp~context~coroutine cxxstd=98 +date_time~debug+exception~fiber+filesystem+graph~icu+iostreams+locale+log+math~mpi+multithreaded~numpy patches=2ab6c72d03dec6a4ae20220a9dfd5c8c572c5294252155b85c6874d97c323199 ~pic+program_options~python+random+regex+serialization+shared+signals~singlethreaded+system~taggedlayout+test+thread+timer~versionedlayout visibility=hidden +wave arch=linux-ubuntu18.04-x86_64
   -   g2ghsbb          ^bzip2@1.0.8%gcc@7.4.0+shared arch=linux-ubuntu18.04-x86_64
   -   vku7yph              ^diffutils@3.7%gcc@7.4.0 arch=linux-ubuntu18.04-x86_64
   -   zvmmgjb                  ^libiconv@1.16%gcc@7.4.0 arch=linux-ubuntu18.04-x86_64
  [+]  o2viq7y          ^zlib@1.2.11%gcc@7.4.0+optimize+pic+shared arch=linux-ubuntu18.04-x86_64
   -   3wkiwji      ^cmake@3.15.4%gcc@7.4.0~doc+ncurses+openssl+ownlibs~qt arch=linux-ubuntu18.04-x86_64
  [+]  s4rsior          ^ncurses@6.1%gcc@7.4.0~symlinks~termlib arch=linux-ubuntu18.04-x86_64
  [+]  eifxmps              ^pkgconf@1.6.3%gcc@7.4.0 arch=linux-ubuntu18.04-x86_64
   -   jujqjv5          ^openssl@1.1.1d%gcc@7.4.0+systemcerts arch=linux-ubuntu18.04-x86_64
  [+]  cxcj6ei              ^perl@5.30.0%gcc@7.4.0+cpanm+shared+threads arch=linux-ubuntu18.04-x86_64
  [+]  surdjxd                  ^gdbm@1.18.1%gcc@7.4.0 arch=linux-ubuntu18.04-x86_64
  [+]  hzwkvqa                      ^readline@8.0%gcc@7.4.0 arch=linux-ubuntu18.04-x86_64
   -   4zyyrqs      ^glm@0.9.7.1%gcc@7.4.0 build_type=RelWithDebInfo arch=linux-ubuntu18.04-x86_64
   -   65cucf4      ^hdf5@1.10.5%gcc@7.4.0~cxx~debug~fortran+hl+mpi patches=b61e2f058964ad85be6ee5ecea10080bf79e73f83ff88d1fa4b602d00209da9c +pic+shared~szip~threadsafe arch=linux-ubuntu18.04-x86_64
   -   f6maodn          ^openmpi@3.1.4%gcc@7.4.0~cuda+cxx_exceptions fabrics=none ~java~legacylaunchers~memchecker~pmi schedulers=none ~sqlite3~thread_multiple+vt arch=linux-ubuntu18.04-x86_64
   -   xcjsxcr              ^hwloc@1.11.11%gcc@7.4.0~cairo~cuda~gl+libxml2~nvml+pci+shared arch=linux-ubuntu18.04-x86_64
   -   vhehc32                  ^libpciaccess@0.13.5%gcc@7.4.0 arch=linux-ubuntu18.04-x86_64
  [+]  4neu5jw                      ^libtool@2.4.6%gcc@7.4.0 arch=linux-ubuntu18.04-x86_64
  [+]  ut64la6                          ^m4@1.4.18%gcc@7.4.0 patches=3877ab548f88597ab2327a2230ee048d2d07ace1062efe81fc92e91b7f39cd00,fc9b61654a3ba1a8d6cd78ce087e7c96366c290bc8d2c299f09828d793b853c8 +sigsegv arch=linux-ubuntu18.04-x86_64
  [+]  3khohgm                              ^libsigsegv@2.12%gcc@7.4.0 arch=linux-ubuntu18.04-x86_64
   -   a226ran                      ^util-macros@1.19.1%gcc@7.4.0 arch=linux-ubuntu18.04-x86_64
   -   fg5evg4                  ^libxml2@2.9.9%gcc@7.4.0~python arch=linux-ubuntu18.04-x86_64
   -   ur2jffe                      ^xz@5.2.4%gcc@7.4.0 arch=linux-ubuntu18.04-x86_64
   -   n6yyt2y                  ^numactl@2.0.12%gcc@7.4.0 arch=linux-ubuntu18.04-x86_64
  [+]  g23qful                      ^autoconf@2.69%gcc@7.4.0 arch=linux-ubuntu18.04-x86_64
  [+]  io3tplo                      ^automake@1.16.1%gcc@7.4.0 arch=linux-ubuntu18.04-x86_64
   -   gsuceum      ^hypre@2.18.1%gcc@7.4.0~complex~debug~int64~internal-superlu~mixedint+mpi~openmp+shared~superlu-dist arch=linux-ubuntu18.04-x86_64
   -   jepvsjb          ^openblas@0.3.7%gcc@7.4.0+avx2~avx512 cpu_target=auto ~ilp64+pic+shared threads=none ~virtual_machine arch=linux-ubuntu18.04-x86_64
   -   7643xwi      ^matio@1.5.13%gcc@7.4.0+hdf5+shared+zlib arch=linux-ubuntu18.04-x86_64
   -   q6wvktu      ^metis@5.1.0%gcc@7.4.0 build_type=Release ~gdb~int64 patches=4991da938c1d3a1d3dea78e49bbebecba00273f98df2a656e38b83d55b281da1,b1225da886605ea558db7ac08dd8054742ea5afe5ed61ad4d0fe7a495b1270d2 ~real64+shared arch=linux-ubuntu18.04-x86_64
   -   s2ezmwe      ^mumps@5.2.0%gcc@7.4.0+complex+double+float~int64~metis+mpi~parmetis~ptscotch~scotch+shared arch=linux-ubuntu18.04-x86_64
   -   gfcwr4d          ^netlib-scalapack@2.0.2%gcc@7.4.0 build_type=RelWithDebInfo patches=22ebf4e3d5a6356cd6086ea65bfdf30f9d0a2038136127590cd269d15bdb03af,e8f30dd1f26e523dfb552f8d7b8ad26ac88fc0c8d72e3d4f9a9717a3383e0b33 ~pic+shared arch=linux-ubuntu18.04-x86_64
   -   t6uuk2x      ^netcdf@4.7.1%gcc@7.4.0~dap~hdf4 maxdims=1024 maxvars=8192 +mpi~parallel-netcdf+pic+shared arch=linux-ubuntu18.04-x86_64
   -   khzaszh      ^parmetis@4.0.3%gcc@7.4.0 build_type=RelWithDebInfo ~gdb patches=4f892531eb0a807eb1b82e683a416d3e35154a455274cf9b162fb02054d11a5b,50ed2081bc939269689789942067c58b3e522c269269a430d5d34c00edbc5870,704b84f7c7444d4372cb59cca6e1209df4ef3b033bc4ee3cf50f369bce972a9d +shared arch=linux-ubuntu18.04-x86_64
   -   3jghv4q      ^suite-sparse@5.3.0%gcc@7.4.0~cuda~openmp+pic~tbb arch=linux-ubuntu18.04-x86_64

  ==> Concretized trilinos%clang
   -   wslff5u  trilinos@12.14.1%clang@6.0.0~adios2~alloptpkgs+amesos+amesos2+anasazi+aztec+belos+boost build_type=RelWithDebInfo ~cgns~chaco~complex~debug~dtk+epetra+epetraext+exodus+explicit_template_instantiation~float+fortran~fortrilinos+gtest+hdf5+hypre+ifpack+ifpack2~intrepid~intrepid2~isorropia+kokkos+metis~minitensor+ml+muelu+mumps~nox~openmp~phalanx~piro~pnetcdf~python~rol~rythmos+sacado~shards+shared~shylu~stk+suite-sparse~superlu~superlu-dist~teko~tempus+teuchos+tpetra~x11~xsdkflags~zlib+zoltan+zoltan2 arch=linux-ubuntu18.04-x86_64
   -   v232ezh      ^boost@1.70.0%clang@6.0.0+atomic+chrono~clanglibcpp~context~coroutine cxxstd=98 +date_time~debug+exception~fiber+filesystem+graph~icu+iostreams+locale+log+math~mpi+multithreaded~numpy patches=2ab6c72d03dec6a4ae20220a9dfd5c8c572c5294252155b85c6874d97c323199 ~pic+program_options~python+random+regex+serialization+shared+signals~singlethreaded+system~taggedlayout+test+thread+timer~versionedlayout visibility=hidden +wave arch=linux-ubuntu18.04-x86_64
   -   qxfbjyc          ^bzip2@1.0.8%clang@6.0.0+shared arch=linux-ubuntu18.04-x86_64
   -   sdvt7ef              ^diffutils@3.7%clang@6.0.0 arch=linux-ubuntu18.04-x86_64
   -   3fxiwph                  ^libiconv@1.16%clang@6.0.0 arch=linux-ubuntu18.04-x86_64
   -   5qffmms          ^zlib@1.2.11%clang@6.0.0+optimize+pic+shared arch=linux-ubuntu18.04-x86_64
   -   xcjcc4g      ^cmake@3.15.4%clang@6.0.0~doc+ncurses+openssl+ownlibs~qt arch=linux-ubuntu18.04-x86_64
   -   r37jihi          ^ncurses@6.1%clang@6.0.0~symlinks~termlib arch=linux-ubuntu18.04-x86_64
   -   t2l6efn              ^pkgconf@1.6.3%clang@6.0.0 arch=linux-ubuntu18.04-x86_64
   -   zpcl6yd          ^openssl@1.1.1d%clang@6.0.0+systemcerts arch=linux-ubuntu18.04-x86_64
   -   nbiong2              ^perl@5.30.0%clang@6.0.0+cpanm+shared+threads arch=linux-ubuntu18.04-x86_64
   -   dbulgup                  ^gdbm@1.18.1%clang@6.0.0 arch=linux-ubuntu18.04-x86_64
   -   qmomdcr                      ^readline@8.0%clang@6.0.0 arch=linux-ubuntu18.04-x86_64
   -   czhoguz      ^glm@0.9.7.1%clang@6.0.0 build_type=RelWithDebInfo arch=linux-ubuntu18.04-x86_64
   -   jjfa3wh      ^hdf5@1.10.5%clang@6.0.0~cxx~debug~fortran+hl+mpi patches=b61e2f058964ad85be6ee5ecea10080bf79e73f83ff88d1fa4b602d00209da9c +pic+shared~szip~threadsafe arch=linux-ubuntu18.04-x86_64
   -   skp3fn3          ^openmpi@3.1.4%clang@6.0.0~cuda+cxx_exceptions fabrics=none ~java~legacylaunchers~memchecker~pmi schedulers=none ~sqlite3~thread_multiple+vt arch=linux-ubuntu18.04-x86_64
   -   vaxjnb5              ^hwloc@1.11.11%clang@6.0.0~cairo~cuda~gl+libxml2~nvml+pci+shared arch=linux-ubuntu18.04-x86_64
   -   azzjaku                  ^libpciaccess@0.13.5%clang@6.0.0 arch=linux-ubuntu18.04-x86_64
   -   s2dxedn                      ^libtool@2.4.6%clang@6.0.0 arch=linux-ubuntu18.04-x86_64
   -   ebsmave                          ^m4@1.4.18%clang@6.0.0 patches=3877ab548f88597ab2327a2230ee048d2d07ace1062efe81fc92e91b7f39cd00,fc9b61654a3ba1a8d6cd78ce087e7c96366c290bc8d2c299f09828d793b853c8 +sigsegv arch=linux-ubuntu18.04-x86_64
   -   dfd6u7k                              ^libsigsegv@2.12%clang@6.0.0 arch=linux-ubuntu18.04-x86_64
   -   yzzs2pw                      ^util-macros@1.19.1%clang@6.0.0 arch=linux-ubuntu18.04-x86_64
   -   5ejde3i                  ^libxml2@2.9.9%clang@6.0.0~python arch=linux-ubuntu18.04-x86_64
   -   s4ehs7e                      ^xz@5.2.4%clang@6.0.0 arch=linux-ubuntu18.04-x86_64
   -   lic4g5m                  ^numactl@2.0.12%clang@6.0.0 arch=linux-ubuntu18.04-x86_64
   -   lj6tu4n                      ^autoconf@2.69%clang@6.0.0 arch=linux-ubuntu18.04-x86_64
   -   7jcnfoe                      ^automake@1.16.1%clang@6.0.0 arch=linux-ubuntu18.04-x86_64
   -   6c3ky7m      ^hypre@2.18.1%clang@6.0.0~complex~debug~int64~internal-superlu~mixedint+mpi~openmp+shared~superlu-dist arch=linux-ubuntu18.04-x86_64
   -   xagenrn          ^openblas@0.3.7%clang@6.0.0+avx2~avx512 cpu_target=auto ~ilp64+pic+shared threads=none ~virtual_machine arch=linux-ubuntu18.04-x86_64
   -   ynlminp      ^matio@1.5.13%clang@6.0.0+hdf5+shared+zlib arch=linux-ubuntu18.04-x86_64
   -   5dhwwts      ^metis@5.1.0%clang@6.0.0 build_type=Release ~gdb~int64 patches=4991da938c1d3a1d3dea78e49bbebecba00273f98df2a656e38b83d55b281da1 ~real64+shared arch=linux-ubuntu18.04-x86_64
   -   lldnbya      ^mumps@5.2.0%clang@6.0.0+complex+double+float~int64~metis+mpi~parmetis~ptscotch~scotch+shared arch=linux-ubuntu18.04-x86_64
   -   qn5k7ek          ^netlib-scalapack@2.0.2%clang@6.0.0 build_type=RelWithDebInfo patches=22ebf4e3d5a6356cd6086ea65bfdf30f9d0a2038136127590cd269d15bdb03af,e8f30dd1f26e523dfb552f8d7b8ad26ac88fc0c8d72e3d4f9a9717a3383e0b33 ~pic+shared arch=linux-ubuntu18.04-x86_64
   -   u5dejg5      ^netcdf@4.7.1%clang@6.0.0~dap~hdf4 maxdims=1024 maxvars=8192 +mpi~parallel-netcdf+pic+shared arch=linux-ubuntu18.04-x86_64
   -   pjq7mac      ^parmetis@4.0.3%clang@6.0.0 build_type=RelWithDebInfo ~gdb patches=4f892531eb0a807eb1b82e683a416d3e35154a455274cf9b162fb02054d11a5b,50ed2081bc939269689789942067c58b3e522c269269a430d5d34c00edbc5870,704b84f7c7444d4372cb59cca6e1209df4ef3b033bc4ee3cf50f369bce972a9d +shared arch=linux-ubuntu18.04-x86_64
   -   kzk6soz      ^suite-sparse@5.3.0%clang@6.0.0~cuda~openmp+pic~tbb arch=linux-ubuntu18.04-x86_64

  ==> Concretized openmpi%gcc
   -   f6maodn  openmpi@3.1.4%gcc@7.4.0~cuda+cxx_exceptions fabrics=none ~java~legacylaunchers~memchecker~pmi schedulers=none ~sqlite3~thread_multiple+vt arch=linux-ubuntu18.04-x86_64
   -   xcjsxcr      ^hwloc@1.11.11%gcc@7.4.0~cairo~cuda~gl+libxml2~nvml+pci+shared arch=linux-ubuntu18.04-x86_64
   -   vhehc32          ^libpciaccess@0.13.5%gcc@7.4.0 arch=linux-ubuntu18.04-x86_64
  [+]  4neu5jw              ^libtool@2.4.6%gcc@7.4.0 arch=linux-ubuntu18.04-x86_64
  [+]  ut64la6                  ^m4@1.4.18%gcc@7.4.0 patches=3877ab548f88597ab2327a2230ee048d2d07ace1062efe81fc92e91b7f39cd00,fc9b61654a3ba1a8d6cd78ce087e7c96366c290bc8d2c299f09828d793b853c8 +sigsegv arch=linux-ubuntu18.04-x86_64
  [+]  3khohgm                      ^libsigsegv@2.12%gcc@7.4.0 arch=linux-ubuntu18.04-x86_64
  [+]  eifxmps              ^pkgconf@1.6.3%gcc@7.4.0 arch=linux-ubuntu18.04-x86_64
   -   a226ran              ^util-macros@1.19.1%gcc@7.4.0 arch=linux-ubuntu18.04-x86_64
   -   fg5evg4          ^libxml2@2.9.9%gcc@7.4.0~python arch=linux-ubuntu18.04-x86_64
   -   zvmmgjb              ^libiconv@1.16%gcc@7.4.0 arch=linux-ubuntu18.04-x86_64
   -   ur2jffe              ^xz@5.2.4%gcc@7.4.0 arch=linux-ubuntu18.04-x86_64
  [+]  o2viq7y              ^zlib@1.2.11%gcc@7.4.0+optimize+pic+shared arch=linux-ubuntu18.04-x86_64
   -   n6yyt2y          ^numactl@2.0.12%gcc@7.4.0 arch=linux-ubuntu18.04-x86_64
  [+]  g23qful              ^autoconf@2.69%gcc@7.4.0 arch=linux-ubuntu18.04-x86_64
  [+]  cxcj6ei                  ^perl@5.30.0%gcc@7.4.0+cpanm+shared+threads arch=linux-ubuntu18.04-x86_64
  [+]  surdjxd                      ^gdbm@1.18.1%gcc@7.4.0 arch=linux-ubuntu18.04-x86_64
  [+]  hzwkvqa                          ^readline@8.0%gcc@7.4.0 arch=linux-ubuntu18.04-x86_64
  [+]  s4rsior                              ^ncurses@6.1%gcc@7.4.0~symlinks~termlib arch=linux-ubuntu18.04-x86_64
  [+]  io3tplo              ^automake@1.16.1%gcc@7.4.0 arch=linux-ubuntu18.04-x86_64

  ==> Concretized openmpi%clang
   -   skp3fn3  openmpi@3.1.4%clang@6.0.0~cuda+cxx_exceptions fabrics=none ~java~legacylaunchers~memchecker~pmi schedulers=none ~sqlite3~thread_multiple+vt arch=linux-ubuntu18.04-x86_64
   -   vaxjnb5      ^hwloc@1.11.11%clang@6.0.0~cairo~cuda~gl+libxml2~nvml+pci+shared arch=linux-ubuntu18.04-x86_64
   -   azzjaku          ^libpciaccess@0.13.5%clang@6.0.0 arch=linux-ubuntu18.04-x86_64
   -   s2dxedn              ^libtool@2.4.6%clang@6.0.0 arch=linux-ubuntu18.04-x86_64
   -   ebsmave                  ^m4@1.4.18%clang@6.0.0 patches=3877ab548f88597ab2327a2230ee048d2d07ace1062efe81fc92e91b7f39cd00,fc9b61654a3ba1a8d6cd78ce087e7c96366c290bc8d2c299f09828d793b853c8 +sigsegv arch=linux-ubuntu18.04-x86_64
   -   dfd6u7k                      ^libsigsegv@2.12%clang@6.0.0 arch=linux-ubuntu18.04-x86_64
   -   t2l6efn              ^pkgconf@1.6.3%clang@6.0.0 arch=linux-ubuntu18.04-x86_64
   -   yzzs2pw              ^util-macros@1.19.1%clang@6.0.0 arch=linux-ubuntu18.04-x86_64
   -   5ejde3i          ^libxml2@2.9.9%clang@6.0.0~python arch=linux-ubuntu18.04-x86_64
   -   3fxiwph              ^libiconv@1.16%clang@6.0.0 arch=linux-ubuntu18.04-x86_64
   -   s4ehs7e              ^xz@5.2.4%clang@6.0.0 arch=linux-ubuntu18.04-x86_64
   -   5qffmms              ^zlib@1.2.11%clang@6.0.0+optimize+pic+shared arch=linux-ubuntu18.04-x86_64
   -   lic4g5m          ^numactl@2.0.12%clang@6.0.0 arch=linux-ubuntu18.04-x86_64
   -   lj6tu4n              ^autoconf@2.69%clang@6.0.0 arch=linux-ubuntu18.04-x86_64
   -   nbiong2                  ^perl@5.30.0%clang@6.0.0+cpanm+shared+threads arch=linux-ubuntu18.04-x86_64
   -   dbulgup                      ^gdbm@1.18.1%clang@6.0.0 arch=linux-ubuntu18.04-x86_64
   -   qmomdcr                          ^readline@8.0%clang@6.0.0 arch=linux-ubuntu18.04-x86_64
   -   r37jihi                              ^ncurses@6.1%clang@6.0.0~symlinks~termlib arch=linux-ubuntu18.04-x86_64
   -   7jcnfoe              ^automake@1.16.1%clang@6.0.0 arch=linux-ubuntu18.04-x86_64

  $ spack find -c
  ==> In environment /home/spack/dev
  ==> Root specs
  -- no arch / clang ----------------------------------------------
  boost  openmpi  trilinos

  -- no arch / gcc ------------------------------------------------
  boost  openmpi  trilinos

  ==> Concretized roots
  -- linux-ubuntu18.04-x86_64 / clang@6.0.0 -----------------------
  boost@1.70.0  openmpi@3.1.4  trilinos@12.14.1

  -- linux-ubuntu18.04-x86_64 / gcc@7.4.0 -------------------------
  boost@1.70.0  openmpi@3.1.4  trilinos@12.14.1

  ==> 1 installed package
  -- linux-ubuntu18.04-x86_64 / gcc@7.4.0 -------------------------
  zlib@1.2.11

The matrix operation does exactly what it looks like it does. It takes
the spec constraints in any number of lists and takes their inner
product. Here, we get ``boost``, ``trilinos``, and ``openmpi``, each
compiled with both ``gcc`` and ``clang``. Note that the compiler
constraints are prefaced with the ``%`` sigil, as they would be on the
command line.

There are a couple special things to note about how constraints are
resolved for matrices. Dependencies and variants can be used in a
matrix regardless of whether they apply to every package in the
matrix. Let's edit our file again.

.. code-block:: yaml
  :emphasize-lines: 10

  # This is a Spack Environment file.
  #
  # It describes a set of packages to be installed, along with
  # configuration setings.
  spack:
    # add package specs to the `specs` list
    specs:
      - matrix:
          - [boost, trilinos, openmpi]
          - [^mpich, ^mvapich2 fabrics=mrail]
          - ['%gcc', '%clang']

    view: False

What we will see here is that Spack applies the mpi constraints to
boost and trilinos, which depend on mpi, and not to openmpi, which
does not.

.. code-block:: console

  $ spack concretize -f
  ==> Concretized boost%gcc ^mpich
   -   d42gtzk  boost@1.70.0%gcc@7.4.0+atomic+chrono~clanglibcpp~context~coroutine cxxstd=98 +date_time~debug+exception~fiber+filesystem+graph~icu+iostreams+locale+log+math~mpi+multithreaded~numpy patches=2ab6c72d03dec6a4ae20220a9dfd5c8c572c5294252155b85c6874d97c323199 ~pic+program_options~python+random+regex+serialization+shared+signals~singlethreaded+system~taggedlayout+test+thread+timer~versionedlayout visibility=hidden +wave arch=linux-ubuntu18.04-x86_64
   -   g2ghsbb      ^bzip2@1.0.8%gcc@7.4.0+shared arch=linux-ubuntu18.04-x86_64
   -   vku7yph          ^diffutils@3.7%gcc@7.4.0 arch=linux-ubuntu18.04-x86_64
   -   zvmmgjb              ^libiconv@1.16%gcc@7.4.0 arch=linux-ubuntu18.04-x86_64
  [+]  o2viq7y      ^zlib@1.2.11%gcc@7.4.0+optimize+pic+shared arch=linux-ubuntu18.04-x86_64

  ==> Concretized boost%clang ^mpich
   -   v232ezh  boost@1.70.0%clang@6.0.0+atomic+chrono~clanglibcpp~context~coroutine cxxstd=98 +date_time~debug+exception~fiber+filesystem+graph~icu+iostreams+locale+log+math~mpi+multithreaded~numpy patches=2ab6c72d03dec6a4ae20220a9dfd5c8c572c5294252155b85c6874d97c323199 ~pic+program_options~python+random+regex+serialization+shared+signals~singlethreaded+system~taggedlayout+test+thread+timer~versionedlayout visibility=hidden +wave arch=linux-ubuntu18.04-x86_64
   -   qxfbjyc      ^bzip2@1.0.8%clang@6.0.0+shared arch=linux-ubuntu18.04-x86_64
   -   sdvt7ef          ^diffutils@3.7%clang@6.0.0 arch=linux-ubuntu18.04-x86_64
   -   3fxiwph              ^libiconv@1.16%clang@6.0.0 arch=linux-ubuntu18.04-x86_64
   -   5qffmms      ^zlib@1.2.11%clang@6.0.0+optimize+pic+shared arch=linux-ubuntu18.04-x86_64

  ==> Concretized boost%gcc ^mvapich2 fabrics=mrail
   -   d42gtzk  boost@1.70.0%gcc@7.4.0+atomic+chrono~clanglibcpp~context~coroutine cxxstd=98 +date_time~debug+exception~fiber+filesystem+graph~icu+iostreams+locale+log+math~mpi+multithreaded~numpy patches=2ab6c72d03dec6a4ae20220a9dfd5c8c572c5294252155b85c6874d97c323199 ~pic+program_options~python+random+regex+serialization+shared+signals~singlethreaded+system~taggedlayout+test+thread+timer~versionedlayout visibility=hidden +wave arch=linux-ubuntu18.04-x86_64
   -   g2ghsbb      ^bzip2@1.0.8%gcc@7.4.0+shared arch=linux-ubuntu18.04-x86_64
   -   vku7yph          ^diffutils@3.7%gcc@7.4.0 arch=linux-ubuntu18.04-x86_64
   -   zvmmgjb              ^libiconv@1.16%gcc@7.4.0 arch=linux-ubuntu18.04-x86_64
  [+]  o2viq7y      ^zlib@1.2.11%gcc@7.4.0+optimize+pic+shared arch=linux-ubuntu18.04-x86_64

  ==> Concretized boost%clang ^mvapich2 fabrics=mrail
   -   v232ezh  boost@1.70.0%clang@6.0.0+atomic+chrono~clanglibcpp~context~coroutine cxxstd=98 +date_time~debug+exception~fiber+filesystem+graph~icu+iostreams+locale+log+math~mpi+multithreaded~numpy patches=2ab6c72d03dec6a4ae20220a9dfd5c8c572c5294252155b85c6874d97c323199 ~pic+program_options~python+random+regex+serialization+shared+signals~singlethreaded+system~taggedlayout+test+thread+timer~versionedlayout visibility=hidden +wave arch=linux-ubuntu18.04-x86_64
   -   qxfbjyc      ^bzip2@1.0.8%clang@6.0.0+shared arch=linux-ubuntu18.04-x86_64
   -   sdvt7ef          ^diffutils@3.7%clang@6.0.0 arch=linux-ubuntu18.04-x86_64
   -   3fxiwph              ^libiconv@1.16%clang@6.0.0 arch=linux-ubuntu18.04-x86_64
   -   5qffmms      ^zlib@1.2.11%clang@6.0.0+optimize+pic+shared arch=linux-ubuntu18.04-x86_64

  ==> Concretized trilinos%gcc ^mpich
   -   ioo4i64  trilinos@12.14.1%gcc@7.4.0~adios2~alloptpkgs+amesos+amesos2+anasazi+aztec+belos+boost build_type=RelWithDebInfo ~cgns~chaco~complex~debug~dtk+epetra+epetraext+exodus+explicit_template_instantiation~float+fortran~fortrilinos+gtest+hdf5+hypre+ifpack+ifpack2~intrepid~intrepid2~isorropia+kokkos+metis~minitensor+ml+muelu+mumps~nox~openmp~phalanx~piro~pnetcdf~python~rol~rythmos+sacado~shards+shared~shylu~stk+suite-sparse~superlu~superlu-dist~teko~tempus+teuchos+tpetra~x11~xsdkflags~zlib+zoltan+zoltan2 arch=linux-ubuntu18.04-x86_64
   -   d42gtzk      ^boost@1.70.0%gcc@7.4.0+atomic+chrono~clanglibcpp~context~coroutine cxxstd=98 +date_time~debug+exception~fiber+filesystem+graph~icu+iostreams+locale+log+math~mpi+multithreaded~numpy patches=2ab6c72d03dec6a4ae20220a9dfd5c8c572c5294252155b85c6874d97c323199 ~pic+program_options~python+random+regex+serialization+shared+signals~singlethreaded+system~taggedlayout+test+thread+timer~versionedlayout visibility=hidden +wave arch=linux-ubuntu18.04-x86_64
   -   g2ghsbb          ^bzip2@1.0.8%gcc@7.4.0+shared arch=linux-ubuntu18.04-x86_64
   -   vku7yph              ^diffutils@3.7%gcc@7.4.0 arch=linux-ubuntu18.04-x86_64
   -   zvmmgjb                  ^libiconv@1.16%gcc@7.4.0 arch=linux-ubuntu18.04-x86_64
  [+]  o2viq7y          ^zlib@1.2.11%gcc@7.4.0+optimize+pic+shared arch=linux-ubuntu18.04-x86_64
   -   3wkiwji      ^cmake@3.15.4%gcc@7.4.0~doc+ncurses+openssl+ownlibs~qt arch=linux-ubuntu18.04-x86_64
  [+]  s4rsior          ^ncurses@6.1%gcc@7.4.0~symlinks~termlib arch=linux-ubuntu18.04-x86_64
  [+]  eifxmps              ^pkgconf@1.6.3%gcc@7.4.0 arch=linux-ubuntu18.04-x86_64
   -   jujqjv5          ^openssl@1.1.1d%gcc@7.4.0+systemcerts arch=linux-ubuntu18.04-x86_64
  [+]  cxcj6ei              ^perl@5.30.0%gcc@7.4.0+cpanm+shared+threads arch=linux-ubuntu18.04-x86_64
  [+]  surdjxd                  ^gdbm@1.18.1%gcc@7.4.0 arch=linux-ubuntu18.04-x86_64
  [+]  hzwkvqa                      ^readline@8.0%gcc@7.4.0 arch=linux-ubuntu18.04-x86_64
   -   4zyyrqs      ^glm@0.9.7.1%gcc@7.4.0 build_type=RelWithDebInfo arch=linux-ubuntu18.04-x86_64
   -   c24mwwt      ^hdf5@1.10.5%gcc@7.4.0~cxx~debug~fortran+hl+mpi patches=b61e2f058964ad85be6ee5ecea10080bf79e73f83ff88d1fa4b602d00209da9c +pic+shared~szip~threadsafe arch=linux-ubuntu18.04-x86_64
   -   6e3rvex          ^mpich@3.3.1%gcc@7.4.0 device=ch3 +hydra netmod=tcp +pci pmi=pmi +romio~slurm~verbs+wrapperrpath arch=linux-ubuntu18.04-x86_64
   -   uf3gw7k              ^findutils@4.6.0%gcc@7.4.0 patches=84b916c0bf8c51b7e7b28417692f0ad3e7030d1f3c248ba77c42ede5c1c5d11e,bd9e4e5cc280f9753ae14956c4e4aa17fe7a210f55dd6c84aa60b12d106d47a2 arch=linux-ubuntu18.04-x86_64
  [+]  g23qful                  ^autoconf@2.69%gcc@7.4.0 arch=linux-ubuntu18.04-x86_64
  [+]  ut64la6                      ^m4@1.4.18%gcc@7.4.0 patches=3877ab548f88597ab2327a2230ee048d2d07ace1062efe81fc92e91b7f39cd00,fc9b61654a3ba1a8d6cd78ce087e7c96366c290bc8d2c299f09828d793b853c8 +sigsegv arch=linux-ubuntu18.04-x86_64
  [+]  3khohgm                          ^libsigsegv@2.12%gcc@7.4.0 arch=linux-ubuntu18.04-x86_64
  [+]  io3tplo                  ^automake@1.16.1%gcc@7.4.0 arch=linux-ubuntu18.04-x86_64
  [+]  4neu5jw                  ^libtool@2.4.6%gcc@7.4.0 arch=linux-ubuntu18.04-x86_64
   -   hyetop5                  ^texinfo@6.5%gcc@7.4.0 arch=linux-ubuntu18.04-x86_64
   -   vhehc32              ^libpciaccess@0.13.5%gcc@7.4.0 arch=linux-ubuntu18.04-x86_64
   -   a226ran                  ^util-macros@1.19.1%gcc@7.4.0 arch=linux-ubuntu18.04-x86_64
   -   fg5evg4              ^libxml2@2.9.9%gcc@7.4.0~python arch=linux-ubuntu18.04-x86_64
   -   ur2jffe                  ^xz@5.2.4%gcc@7.4.0 arch=linux-ubuntu18.04-x86_64
   -   ubwkr5u      ^hypre@2.18.1%gcc@7.4.0~complex~debug~int64~internal-superlu~mixedint+mpi~openmp+shared~superlu-dist arch=linux-ubuntu18.04-x86_64
   -   jepvsjb          ^openblas@0.3.7%gcc@7.4.0+avx2~avx512 cpu_target=auto ~ilp64+pic+shared threads=none ~virtual_machine arch=linux-ubuntu18.04-x86_64
   -   mexumm4      ^matio@1.5.13%gcc@7.4.0+hdf5+shared+zlib arch=linux-ubuntu18.04-x86_64
   -   q6wvktu      ^metis@5.1.0%gcc@7.4.0 build_type=Release ~gdb~int64 patches=4991da938c1d3a1d3dea78e49bbebecba00273f98df2a656e38b83d55b281da1,b1225da886605ea558db7ac08dd8054742ea5afe5ed61ad4d0fe7a495b1270d2 ~real64+shared arch=linux-ubuntu18.04-x86_64
   -   nippo7j      ^mumps@5.2.0%gcc@7.4.0+complex+double+float~int64~metis+mpi~parmetis~ptscotch~scotch+shared arch=linux-ubuntu18.04-x86_64
   -   tbp3lv6          ^netlib-scalapack@2.0.2%gcc@7.4.0 build_type=RelWithDebInfo patches=22ebf4e3d5a6356cd6086ea65bfdf30f9d0a2038136127590cd269d15bdb03af,e8f30dd1f26e523dfb552f8d7b8ad26ac88fc0c8d72e3d4f9a9717a3383e0b33 ~pic+shared arch=linux-ubuntu18.04-x86_64
   -   vx6vje7      ^netcdf@4.7.1%gcc@7.4.0~dap~hdf4 maxdims=1024 maxvars=8192 +mpi~parallel-netcdf+pic+shared arch=linux-ubuntu18.04-x86_64
   -   t6gxi6e      ^parmetis@4.0.3%gcc@7.4.0 build_type=RelWithDebInfo ~gdb patches=4f892531eb0a807eb1b82e683a416d3e35154a455274cf9b162fb02054d11a5b,50ed2081bc939269689789942067c58b3e522c269269a430d5d34c00edbc5870,704b84f7c7444d4372cb59cca6e1209df4ef3b033bc4ee3cf50f369bce972a9d +shared arch=linux-ubuntu18.04-x86_64
   -   3jghv4q      ^suite-sparse@5.3.0%gcc@7.4.0~cuda~openmp+pic~tbb arch=linux-ubuntu18.04-x86_64

  ==> Concretized trilinos%clang ^mpich
   -   vgdly2b  trilinos@12.14.1%clang@6.0.0~adios2~alloptpkgs+amesos+amesos2+anasazi+aztec+belos+boost build_type=RelWithDebInfo ~cgns~chaco~complex~debug~dtk+epetra+epetraext+exodus+explicit_template_instantiation~float+fortran~fortrilinos+gtest+hdf5+hypre+ifpack+ifpack2~intrepid~intrepid2~isorropia+kokkos+metis~minitensor+ml+muelu+mumps~nox~openmp~phalanx~piro~pnetcdf~python~rol~rythmos+sacado~shards+shared~shylu~stk+suite-sparse~superlu~superlu-dist~teko~tempus+teuchos+tpetra~x11~xsdkflags~zlib+zoltan+zoltan2 arch=linux-ubuntu18.04-x86_64
   -   v232ezh      ^boost@1.70.0%clang@6.0.0+atomic+chrono~clanglibcpp~context~coroutine cxxstd=98 +date_time~debug+exception~fiber+filesystem+graph~icu+iostreams+locale+log+math~mpi+multithreaded~numpy patches=2ab6c72d03dec6a4ae20220a9dfd5c8c572c5294252155b85c6874d97c323199 ~pic+program_options~python+random+regex+serialization+shared+signals~singlethreaded+system~taggedlayout+test+thread+timer~versionedlayout visibility=hidden +wave arch=linux-ubuntu18.04-x86_64
   -   qxfbjyc          ^bzip2@1.0.8%clang@6.0.0+shared arch=linux-ubuntu18.04-x86_64
   -   sdvt7ef              ^diffutils@3.7%clang@6.0.0 arch=linux-ubuntu18.04-x86_64
   -   3fxiwph                  ^libiconv@1.16%clang@6.0.0 arch=linux-ubuntu18.04-x86_64
   -   5qffmms          ^zlib@1.2.11%clang@6.0.0+optimize+pic+shared arch=linux-ubuntu18.04-x86_64
   -   xcjcc4g      ^cmake@3.15.4%clang@6.0.0~doc+ncurses+openssl+ownlibs~qt arch=linux-ubuntu18.04-x86_64
   -   r37jihi          ^ncurses@6.1%clang@6.0.0~symlinks~termlib arch=linux-ubuntu18.04-x86_64
   -   t2l6efn              ^pkgconf@1.6.3%clang@6.0.0 arch=linux-ubuntu18.04-x86_64
   -   zpcl6yd          ^openssl@1.1.1d%clang@6.0.0+systemcerts arch=linux-ubuntu18.04-x86_64
   -   nbiong2              ^perl@5.30.0%clang@6.0.0+cpanm+shared+threads arch=linux-ubuntu18.04-x86_64
   -   dbulgup                  ^gdbm@1.18.1%clang@6.0.0 arch=linux-ubuntu18.04-x86_64
   -   qmomdcr                      ^readline@8.0%clang@6.0.0 arch=linux-ubuntu18.04-x86_64
   -   czhoguz      ^glm@0.9.7.1%clang@6.0.0 build_type=RelWithDebInfo arch=linux-ubuntu18.04-x86_64
   -   guruzoh      ^hdf5@1.10.5%clang@6.0.0~cxx~debug~fortran+hl+mpi patches=b61e2f058964ad85be6ee5ecea10080bf79e73f83ff88d1fa4b602d00209da9c +pic+shared~szip~threadsafe arch=linux-ubuntu18.04-x86_64
   -   2pha4ul          ^mpich@3.3.1%clang@6.0.0 device=ch3 +hydra netmod=tcp +pci pmi=pmi +romio~slurm~verbs+wrapperrpath arch=linux-ubuntu18.04-x86_64
   -   jsefksx              ^findutils@4.6.0%clang@6.0.0 patches=84b916c0bf8c51b7e7b28417692f0ad3e7030d1f3c248ba77c42ede5c1c5d11e,bd9e4e5cc280f9753ae14956c4e4aa17fe7a210f55dd6c84aa60b12d106d47a2 arch=linux-ubuntu18.04-x86_64
   -   lj6tu4n                  ^autoconf@2.69%clang@6.0.0 arch=linux-ubuntu18.04-x86_64
   -   ebsmave                      ^m4@1.4.18%clang@6.0.0 patches=3877ab548f88597ab2327a2230ee048d2d07ace1062efe81fc92e91b7f39cd00,fc9b61654a3ba1a8d6cd78ce087e7c96366c290bc8d2c299f09828d793b853c8 +sigsegv arch=linux-ubuntu18.04-x86_64
   -   dfd6u7k                          ^libsigsegv@2.12%clang@6.0.0 arch=linux-ubuntu18.04-x86_64
   -   7jcnfoe                  ^automake@1.16.1%clang@6.0.0 arch=linux-ubuntu18.04-x86_64
   -   s2dxedn                  ^libtool@2.4.6%clang@6.0.0 arch=linux-ubuntu18.04-x86_64
   -   tcq4tkc                  ^texinfo@6.5%clang@6.0.0 arch=linux-ubuntu18.04-x86_64
   -   azzjaku              ^libpciaccess@0.13.5%clang@6.0.0 arch=linux-ubuntu18.04-x86_64
   -   yzzs2pw                  ^util-macros@1.19.1%clang@6.0.0 arch=linux-ubuntu18.04-x86_64
   -   5ejde3i              ^libxml2@2.9.9%clang@6.0.0~python arch=linux-ubuntu18.04-x86_64
   -   s4ehs7e                  ^xz@5.2.4%clang@6.0.0 arch=linux-ubuntu18.04-x86_64
   -   rgwj32u      ^hypre@2.18.1%clang@6.0.0~complex~debug~int64~internal-superlu~mixedint+mpi~openmp+shared~superlu-dist arch=linux-ubuntu18.04-x86_64
   -   xagenrn          ^openblas@0.3.7%clang@6.0.0+avx2~avx512 cpu_target=auto ~ilp64+pic+shared threads=none ~virtual_machine arch=linux-ubuntu18.04-x86_64
   -   kl5yia2      ^matio@1.5.13%clang@6.0.0+hdf5+shared+zlib arch=linux-ubuntu18.04-x86_64
   -   5dhwwts      ^metis@5.1.0%clang@6.0.0 build_type=Release ~gdb~int64 patches=4991da938c1d3a1d3dea78e49bbebecba00273f98df2a656e38b83d55b281da1 ~real64+shared arch=linux-ubuntu18.04-x86_64
   -   afvzkfz      ^mumps@5.2.0%clang@6.0.0+complex+double+float~int64~metis+mpi~parmetis~ptscotch~scotch+shared arch=linux-ubuntu18.04-x86_64
   -   2jvxthp          ^netlib-scalapack@2.0.2%clang@6.0.0 build_type=RelWithDebInfo patches=22ebf4e3d5a6356cd6086ea65bfdf30f9d0a2038136127590cd269d15bdb03af,e8f30dd1f26e523dfb552f8d7b8ad26ac88fc0c8d72e3d4f9a9717a3383e0b33 ~pic+shared arch=linux-ubuntu18.04-x86_64
   -   nwcwlt5      ^netcdf@4.7.1%clang@6.0.0~dap~hdf4 maxdims=1024 maxvars=8192 +mpi~parallel-netcdf+pic+shared arch=linux-ubuntu18.04-x86_64
   -   cy36wk7      ^parmetis@4.0.3%clang@6.0.0 build_type=RelWithDebInfo ~gdb patches=4f892531eb0a807eb1b82e683a416d3e35154a455274cf9b162fb02054d11a5b,50ed2081bc939269689789942067c58b3e522c269269a430d5d34c00edbc5870,704b84f7c7444d4372cb59cca6e1209df4ef3b033bc4ee3cf50f369bce972a9d +shared arch=linux-ubuntu18.04-x86_64
   -   kzk6soz      ^suite-sparse@5.3.0%clang@6.0.0~cuda~openmp+pic~tbb arch=linux-ubuntu18.04-x86_64
  ==> Concretized trilinos%gcc ^mvapich2 fabrics=mrail
   -   kr6f4va  trilinos@12.14.1%gcc@7.4.0~adios2~alloptpkgs+amesos+amesos2+anasazi+aztec+belos+boost build_type=RelWithDebInfo ~cgns~chaco~complex~debug~dtk+epetra+epetraext+exodus+explicit_template_instantiation~float+fortran~fortrilinos+gtest+hdf5+hypre+ifpack+ifpack2~intrepid~intrepid2~isorropia+kokkos+metis~minitensor+ml+muelu+mumps~nox~openmp~phalanx~piro~pnetcdf~python~rol~rythmos+sacado~shards+shared~shylu~stk+suite-sparse~superlu~superlu-dist~teko~tempus+teuchos+tpetra~x11~xsdkflags~zlib+zoltan+zoltan2 arch=linux-ubuntu18.04-x86_64
   -   d42gtzk      ^boost@1.70.0%gcc@7.4.0+atomic+chrono~clanglibcpp~context~coroutine cxxstd=98 +date_time~debug+exception~fiber+filesystem+graph~icu+iostreams+locale+log+math~mpi+multithreaded~numpy patches=2ab6c72d03dec6a4ae20220a9dfd5c8c572c5294252155b85c6874d97c323199 ~pic+program_options~python+random+regex+serialization+shared+signals~singlethreaded+system~taggedlayout+test+thread+timer~versionedlayout visibility=hidden +wave arch=linux-ubuntu18.04-x86_64
   -   g2ghsbb          ^bzip2@1.0.8%gcc@7.4.0+shared arch=linux-ubuntu18.04-x86_64
   -   vku7yph              ^diffutils@3.7%gcc@7.4.0 arch=linux-ubuntu18.04-x86_64
   -   zvmmgjb                  ^libiconv@1.16%gcc@7.4.0 arch=linux-ubuntu18.04-x86_64
  [+]  o2viq7y          ^zlib@1.2.11%gcc@7.4.0+optimize+pic+shared arch=linux-ubuntu18.04-x86_64
   -   3wkiwji      ^cmake@3.15.4%gcc@7.4.0~doc+ncurses+openssl+ownlibs~qt arch=linux-ubuntu18.04-x86_64
  [+]  s4rsior          ^ncurses@6.1%gcc@7.4.0~symlinks~termlib arch=linux-ubuntu18.04-x86_64
  [+]  eifxmps              ^pkgconf@1.6.3%gcc@7.4.0 arch=linux-ubuntu18.04-x86_64
   -   jujqjv5          ^openssl@1.1.1d%gcc@7.4.0+systemcerts arch=linux-ubuntu18.04-x86_64
  [+]  cxcj6ei              ^perl@5.30.0%gcc@7.4.0+cpanm+shared+threads arch=linux-ubuntu18.04-x86_64
  [+]  surdjxd                  ^gdbm@1.18.1%gcc@7.4.0 arch=linux-ubuntu18.04-x86_64
  [+]  hzwkvqa                      ^readline@8.0%gcc@7.4.0 arch=linux-ubuntu18.04-x86_64
   -   4zyyrqs      ^glm@0.9.7.1%gcc@7.4.0 build_type=RelWithDebInfo arch=linux-ubuntu18.04-x86_64
   -   7uofzwm      ^hdf5@1.10.5%gcc@7.4.0~cxx~debug~fortran+hl+mpi patches=b61e2f058964ad85be6ee5ecea10080bf79e73f83ff88d1fa4b602d00209da9c +pic+shared~szip~threadsafe arch=linux-ubuntu18.04-x86_64
   -   vam4bay          ^mvapich2@2.3.1%gcc@7.4.0~alloca ch3_rank_bits=32 ~cuda~debug fabrics=mrail file_systems=auto process_managers=auto +regcache threads=multiple arch=linux-ubuntu18.04-x86_64
   -   nohorrb              ^bison@3.4.2%gcc@7.4.0 patches=89aa362716d898edd0b5c6ae4208dc1b6992887774848a09e8021afd676f7d61 arch=linux-ubuntu18.04-x86_64
   -   4kei2q5                  ^help2man@1.47.11%gcc@7.4.0 arch=linux-ubuntu18.04-x86_64
   -   4uqpp5g                      ^gettext@0.20.1%gcc@7.4.0+bzip2+curses+git~libunistring+libxml2+tar+xz arch=linux-ubuntu18.04-x86_64
   -   fg5evg4                          ^libxml2@2.9.9%gcc@7.4.0~python arch=linux-ubuntu18.04-x86_64
   -   ur2jffe                              ^xz@5.2.4%gcc@7.4.0 arch=linux-ubuntu18.04-x86_64
   -   iyu6ntr                          ^tar@1.32%gcc@7.4.0 arch=linux-ubuntu18.04-x86_64
  [+]  ut64la6                  ^m4@1.4.18%gcc@7.4.0 patches=3877ab548f88597ab2327a2230ee048d2d07ace1062efe81fc92e91b7f39cd00,fc9b61654a3ba1a8d6cd78ce087e7c96366c290bc8d2c299f09828d793b853c8 +sigsegv arch=linux-ubuntu18.04-x86_64
  [+]  3khohgm                      ^libsigsegv@2.12%gcc@7.4.0 arch=linux-ubuntu18.04-x86_64
   -   uf3gw7k              ^findutils@4.6.0%gcc@7.4.0 patches=84b916c0bf8c51b7e7b28417692f0ad3e7030d1f3c248ba77c42ede5c1c5d11e,bd9e4e5cc280f9753ae14956c4e4aa17fe7a210f55dd6c84aa60b12d106d47a2 arch=linux-ubuntu18.04-x86_64
  [+]  g23qful                  ^autoconf@2.69%gcc@7.4.0 arch=linux-ubuntu18.04-x86_64
  [+]  io3tplo                  ^automake@1.16.1%gcc@7.4.0 arch=linux-ubuntu18.04-x86_64
  [+]  4neu5jw                  ^libtool@2.4.6%gcc@7.4.0 arch=linux-ubuntu18.04-x86_64
   -   hyetop5                  ^texinfo@6.5%gcc@7.4.0 arch=linux-ubuntu18.04-x86_64
   -   vhehc32              ^libpciaccess@0.13.5%gcc@7.4.0 arch=linux-ubuntu18.04-x86_64
   -   a226ran                  ^util-macros@1.19.1%gcc@7.4.0 arch=linux-ubuntu18.04-x86_64
   -   qmc5ln7              ^rdma-core@20%gcc@7.4.0 build_type=RelWithDebInfo arch=linux-ubuntu18.04-x86_64
   -   iznz4py                  ^libnl@3.3.0%gcc@7.4.0 arch=linux-ubuntu18.04-x86_64
   -   uaftpqq                      ^flex@2.6.4%gcc@7.4.0+lex patches=09c22e5c6fef327d3e48eb23f0d610dcd3a35ab9207f12e0f875701c677978d3 arch=linux-ubuntu18.04-x86_64
   -   5x3rj3i      ^hypre@2.18.1%gcc@7.4.0~complex~debug~int64~internal-superlu~mixedint+mpi~openmp+shared~superlu-dist arch=linux-ubuntu18.04-x86_64
   -   jepvsjb          ^openblas@0.3.7%gcc@7.4.0+avx2~avx512 cpu_target=auto ~ilp64+pic+shared threads=none ~virtual_machine arch=linux-ubuntu18.04-x86_64
   -   6yq3jb3      ^matio@1.5.13%gcc@7.4.0+hdf5+shared+zlib arch=linux-ubuntu18.04-x86_64
   -   q6wvktu      ^metis@5.1.0%gcc@7.4.0 build_type=Release ~gdb~int64 patches=4991da938c1d3a1d3dea78e49bbebecba00273f98df2a656e38b83d55b281da1,b1225da886605ea558db7ac08dd8054742ea5afe5ed61ad4d0fe7a495b1270d2 ~real64+shared arch=linux-ubuntu18.04-x86_64
   -   z4zx2b4      ^mumps@5.2.0%gcc@7.4.0+complex+double+float~int64~metis+mpi~parmetis~ptscotch~scotch+shared arch=linux-ubuntu18.04-x86_64
   -   yp3mdxd          ^netlib-scalapack@2.0.2%gcc@7.4.0 build_type=RelWithDebInfo patches=22ebf4e3d5a6356cd6086ea65bfdf30f9d0a2038136127590cd269d15bdb03af,e8f30dd1f26e523dfb552f8d7b8ad26ac88fc0c8d72e3d4f9a9717a3383e0b33 ~pic+shared arch=linux-ubuntu18.04-x86_64
   -   jc4xpmf      ^netcdf@4.7.1%gcc@7.4.0~dap~hdf4 maxdims=1024 maxvars=8192 +mpi~parallel-netcdf+pic+shared arch=linux-ubuntu18.04-x86_64
   -   jxb3hww      ^parmetis@4.0.3%gcc@7.4.0 build_type=RelWithDebInfo ~gdb patches=4f892531eb0a807eb1b82e683a416d3e35154a455274cf9b162fb02054d11a5b,50ed2081bc939269689789942067c58b3e522c269269a430d5d34c00edbc5870,704b84f7c7444d4372cb59cca6e1209df4ef3b033bc4ee3cf50f369bce972a9d +shared arch=linux-ubuntu18.04-x86_64
   -   3jghv4q      ^suite-sparse@5.3.0%gcc@7.4.0~cuda~openmp+pic~tbb arch=linux-ubuntu18.04-x86_64

  ==> Concretized trilinos%clang ^mvapich2 fabrics=mrail
   -   gsx2i6z  trilinos@12.14.1%clang@6.0.0~adios2~alloptpkgs+amesos+amesos2+anasazi+aztec+belos+boost build_type=RelWithDebInfo ~cgns~chaco~complex~debug~dtk+epetra+epetraext+exodus+explicit_template_instantiation~float+fortran~fortrilinos+gtest+hdf5+hypre+ifpack+ifpack2~intrepid~intrepid2~isorropia+kokkos+metis~minitensor+ml+muelu+mumps~nox~openmp~phalanx~piro~pnetcdf~python~rol~rythmos+sacado~shards+shared~shylu~stk+suite-sparse~superlu~superlu-dist~teko~tempus+teuchos+tpetra~x11~xsdkflags~zlib+zoltan+zoltan2 arch=linux-ubuntu18.04-x86_64
   -   v232ezh      ^boost@1.70.0%clang@6.0.0+atomic+chrono~clanglibcpp~context~coroutine cxxstd=98 +date_time~debug+exception~fiber+filesystem+graph~icu+iostreams+locale+log+math~mpi+multithreaded~numpy patches=2ab6c72d03dec6a4ae20220a9dfd5c8c572c5294252155b85c6874d97c323199 ~pic+program_options~python+random+regex+serialization+shared+signals~singlethreaded+system~taggedlayout+test+thread+timer~versionedlayout visibility=hidden +wave arch=linux-ubuntu18.04-x86_64
   -   qxfbjyc          ^bzip2@1.0.8%clang@6.0.0+shared arch=linux-ubuntu18.04-x86_64
   -   sdvt7ef              ^diffutils@3.7%clang@6.0.0 arch=linux-ubuntu18.04-x86_64
   -   3fxiwph                  ^libiconv@1.16%clang@6.0.0 arch=linux-ubuntu18.04-x86_64
   -   5qffmms          ^zlib@1.2.11%clang@6.0.0+optimize+pic+shared arch=linux-ubuntu18.04-x86_64
   -   xcjcc4g      ^cmake@3.15.4%clang@6.0.0~doc+ncurses+openssl+ownlibs~qt arch=linux-ubuntu18.04-x86_64
   -   r37jihi          ^ncurses@6.1%clang@6.0.0~symlinks~termlib arch=linux-ubuntu18.04-x86_64
   -   t2l6efn              ^pkgconf@1.6.3%clang@6.0.0 arch=linux-ubuntu18.04-x86_64
   -   zpcl6yd          ^openssl@1.1.1d%clang@6.0.0+systemcerts arch=linux-ubuntu18.04-x86_64
   -   nbiong2              ^perl@5.30.0%clang@6.0.0+cpanm+shared+threads arch=linux-ubuntu18.04-x86_64
   -   dbulgup                  ^gdbm@1.18.1%clang@6.0.0 arch=linux-ubuntu18.04-x86_64
   -   qmomdcr                      ^readline@8.0%clang@6.0.0 arch=linux-ubuntu18.04-x86_64
   -   czhoguz      ^glm@0.9.7.1%clang@6.0.0 build_type=RelWithDebInfo arch=linux-ubuntu18.04-x86_64
   -   kws7zsn      ^hdf5@1.10.5%clang@6.0.0~cxx~debug~fortran+hl+mpi patches=b61e2f058964ad85be6ee5ecea10080bf79e73f83ff88d1fa4b602d00209da9c +pic+shared~szip~threadsafe arch=linux-ubuntu18.04-x86_64
   -   6audvv3          ^mvapich2@2.3.1%clang@6.0.0~alloca ch3_rank_bits=32 ~cuda~debug fabrics=mrail file_systems=auto process_managers=auto +regcache threads=multiple arch=linux-ubuntu18.04-x86_64
   -   ybdnsj3              ^bison@3.4.2%clang@6.0.0 patches=89aa362716d898edd0b5c6ae4208dc1b6992887774848a09e8021afd676f7d61 arch=linux-ubuntu18.04-x86_64
   -   lrqwvnr                  ^help2man@1.47.11%clang@6.0.0 arch=linux-ubuntu18.04-x86_64
   -   botnk7f                      ^gettext@0.20.1%clang@6.0.0+bzip2+curses+git~libunistring+libxml2+tar+xz arch=linux-ubuntu18.04-x86_64
   -   5ejde3i                          ^libxml2@2.9.9%clang@6.0.0~python arch=linux-ubuntu18.04-x86_64
   -   s4ehs7e                              ^xz@5.2.4%clang@6.0.0 arch=linux-ubuntu18.04-x86_64
   -   vuc6wgn                          ^tar@1.32%clang@6.0.0 arch=linux-ubuntu18.04-x86_64
   -   ebsmave                  ^m4@1.4.18%clang@6.0.0 patches=3877ab548f88597ab2327a2230ee048d2d07ace1062efe81fc92e91b7f39cd00,fc9b61654a3ba1a8d6cd78ce087e7c96366c290bc8d2c299f09828d793b853c8 +sigsegv arch=linux-ubuntu18.04-x86_64
   -   dfd6u7k                      ^libsigsegv@2.12%clang@6.0.0 arch=linux-ubuntu18.04-x86_64
   -   jsefksx              ^findutils@4.6.0%clang@6.0.0 patches=84b916c0bf8c51b7e7b28417692f0ad3e7030d1f3c248ba77c42ede5c1c5d11e,bd9e4e5cc280f9753ae14956c4e4aa17fe7a210f55dd6c84aa60b12d106d47a2 arch=linux-ubuntu18.04-x86_64
   -   lj6tu4n                  ^autoconf@2.69%clang@6.0.0 arch=linux-ubuntu18.04-x86_64
   -   7jcnfoe                  ^automake@1.16.1%clang@6.0.0 arch=linux-ubuntu18.04-x86_64
   -   s2dxedn                  ^libtool@2.4.6%clang@6.0.0 arch=linux-ubuntu18.04-x86_64
   -   tcq4tkc                  ^texinfo@6.5%clang@6.0.0 arch=linux-ubuntu18.04-x86_64
   -   azzjaku              ^libpciaccess@0.13.5%clang@6.0.0 arch=linux-ubuntu18.04-x86_64
   -   yzzs2pw                  ^util-macros@1.19.1%clang@6.0.0 arch=linux-ubuntu18.04-x86_64
   -   mhitav2              ^rdma-core@20%clang@6.0.0 build_type=RelWithDebInfo arch=linux-ubuntu18.04-x86_64
   -   fo7zfqe                  ^libnl@3.3.0%clang@6.0.0 arch=linux-ubuntu18.04-x86_64
   -   dcwuy4i                      ^flex@2.6.4%clang@6.0.0+lex patches=09c22e5c6fef327d3e48eb23f0d610dcd3a35ab9207f12e0f875701c677978d3 arch=linux-ubuntu18.04-x86_64
   -   wwc3epe      ^hypre@2.18.1%clang@6.0.0~complex~debug~int64~internal-superlu~mixedint+mpi~openmp+shared~superlu-dist arch=linux-ubuntu18.04-x86_64
   -   xagenrn          ^openblas@0.3.7%clang@6.0.0+avx2~avx512 cpu_target=auto ~ilp64+pic+shared threads=none ~virtual_machine arch=linux-ubuntu18.04-x86_64
   -   fhvet3a      ^matio@1.5.13%clang@6.0.0+hdf5+shared+zlib arch=linux-ubuntu18.04-x86_64
   -   5dhwwts      ^metis@5.1.0%clang@6.0.0 build_type=Release ~gdb~int64 patches=4991da938c1d3a1d3dea78e49bbebecba00273f98df2a656e38b83d55b281da1 ~real64+shared arch=linux-ubuntu18.04-x86_64
   -   tnkmerd      ^mumps@5.2.0%clang@6.0.0+complex+double+float~int64~metis+mpi~parmetis~ptscotch~scotch+shared arch=linux-ubuntu18.04-x86_64
   -   e2waq2e          ^netlib-scalapack@2.0.2%clang@6.0.0 build_type=RelWithDebInfo patches=22ebf4e3d5a6356cd6086ea65bfdf30f9d0a2038136127590cd269d15bdb03af,e8f30dd1f26e523dfb552f8d7b8ad26ac88fc0c8d72e3d4f9a9717a3383e0b33 ~pic+shared arch=linux-ubuntu18.04-x86_64
   -   lllgi7a      ^netcdf@4.7.1%clang@6.0.0~dap~hdf4 maxdims=1024 maxvars=8192 +mpi~parallel-netcdf+pic+shared arch=linux-ubuntu18.04-x86_64
   -   2yzrsje      ^parmetis@4.0.3%clang@6.0.0 build_type=RelWithDebInfo ~gdb patches=4f892531eb0a807eb1b82e683a416d3e35154a455274cf9b162fb02054d11a5b,50ed2081bc939269689789942067c58b3e522c269269a430d5d34c00edbc5870,704b84f7c7444d4372cb59cca6e1209df4ef3b033bc4ee3cf50f369bce972a9d +shared arch=linux-ubuntu18.04-x86_64
   -   kzk6soz      ^suite-sparse@5.3.0%clang@6.0.0~cuda~openmp+pic~tbb arch=linux-ubuntu18.04-x86_64

  ==> Concretized openmpi%gcc ^mpich
   -   f6maodn  openmpi@3.1.4%gcc@7.4.0~cuda+cxx_exceptions fabrics=none ~java~legacylaunchers~memchecker~pmi schedulers=none ~sqlite3~thread_multiple+vt arch=linux-ubuntu18.04-x86_64
   -   xcjsxcr      ^hwloc@1.11.11%gcc@7.4.0~cairo~cuda~gl+libxml2~nvml+pci+shared arch=linux-ubuntu18.04-x86_64
   -   vhehc32          ^libpciaccess@0.13.5%gcc@7.4.0 arch=linux-ubuntu18.04-x86_64
  [+]  4neu5jw              ^libtool@2.4.6%gcc@7.4.0 arch=linux-ubuntu18.04-x86_64
  [+]  ut64la6                  ^m4@1.4.18%gcc@7.4.0 patches=3877ab548f88597ab2327a2230ee048d2d07ace1062efe81fc92e91b7f39cd00,fc9b61654a3ba1a8d6cd78ce087e7c96366c290bc8d2c299f09828d793b853c8 +sigsegv arch=linux-ubuntu18.04-x86_64
  [+]  3khohgm                      ^libsigsegv@2.12%gcc@7.4.0 arch=linux-ubuntu18.04-x86_64
  [+]  eifxmps              ^pkgconf@1.6.3%gcc@7.4.0 arch=linux-ubuntu18.04-x86_64
   -   a226ran              ^util-macros@1.19.1%gcc@7.4.0 arch=linux-ubuntu18.04-x86_64
   -   fg5evg4          ^libxml2@2.9.9%gcc@7.4.0~python arch=linux-ubuntu18.04-x86_64
   -   zvmmgjb              ^libiconv@1.16%gcc@7.4.0 arch=linux-ubuntu18.04-x86_64
   -   ur2jffe              ^xz@5.2.4%gcc@7.4.0 arch=linux-ubuntu18.04-x86_64
  [+]  o2viq7y              ^zlib@1.2.11%gcc@7.4.0+optimize+pic+shared arch=linux-ubuntu18.04-x86_64
   -   n6yyt2y          ^numactl@2.0.12%gcc@7.4.0 arch=linux-ubuntu18.04-x86_64
  [+]  g23qful              ^autoconf@2.69%gcc@7.4.0 arch=linux-ubuntu18.04-x86_64
  [+]  cxcj6ei                  ^perl@5.30.0%gcc@7.4.0+cpanm+shared+threads arch=linux-ubuntu18.04-x86_64
  [+]  surdjxd                      ^gdbm@1.18.1%gcc@7.4.0 arch=linux-ubuntu18.04-x86_64
  [+]  hzwkvqa                          ^readline@8.0%gcc@7.4.0 arch=linux-ubuntu18.04-x86_64
  [+]  s4rsior                              ^ncurses@6.1%gcc@7.4.0~symlinks~termlib arch=linux-ubuntu18.04-x86_64
  [+]  io3tplo              ^automake@1.16.1%gcc@7.4.0 arch=linux-ubuntu18.04-x86_64

  ==> Concretized openmpi%clang ^mpich
   -   skp3fn3  openmpi@3.1.4%clang@6.0.0~cuda+cxx_exceptions fabrics=none ~java~legacylaunchers~memchecker~pmi schedulers=none ~sqlite3~thread_multiple+vt arch=linux-ubuntu18.04-x86_64
   -   vaxjnb5      ^hwloc@1.11.11%clang@6.0.0~cairo~cuda~gl+libxml2~nvml+pci+shared arch=linux-ubuntu18.04-x86_64
   -   azzjaku          ^libpciaccess@0.13.5%clang@6.0.0 arch=linux-ubuntu18.04-x86_64
   -   s2dxedn              ^libtool@2.4.6%clang@6.0.0 arch=linux-ubuntu18.04-x86_64
   -   ebsmave                  ^m4@1.4.18%clang@6.0.0 patches=3877ab548f88597ab2327a2230ee048d2d07ace1062efe81fc92e91b7f39cd00,fc9b61654a3ba1a8d6cd78ce087e7c96366c290bc8d2c299f09828d793b853c8 +sigsegv arch=linux-ubuntu18.04-x86_64
   -   dfd6u7k                      ^libsigsegv@2.12%clang@6.0.0 arch=linux-ubuntu18.04-x86_64
   -   t2l6efn              ^pkgconf@1.6.3%clang@6.0.0 arch=linux-ubuntu18.04-x86_64
   -   yzzs2pw              ^util-macros@1.19.1%clang@6.0.0 arch=linux-ubuntu18.04-x86_64
   -   5ejde3i          ^libxml2@2.9.9%clang@6.0.0~python arch=linux-ubuntu18.04-x86_64
   -   3fxiwph              ^libiconv@1.16%clang@6.0.0 arch=linux-ubuntu18.04-x86_64
   -   s4ehs7e              ^xz@5.2.4%clang@6.0.0 arch=linux-ubuntu18.04-x86_64
   -   5qffmms              ^zlib@1.2.11%clang@6.0.0+optimize+pic+shared arch=linux-ubuntu18.04-x86_64
   -   lic4g5m          ^numactl@2.0.12%clang@6.0.0 arch=linux-ubuntu18.04-x86_64
   -   lj6tu4n              ^autoconf@2.69%clang@6.0.0 arch=linux-ubuntu18.04-x86_64
   -   nbiong2                  ^perl@5.30.0%clang@6.0.0+cpanm+shared+threads arch=linux-ubuntu18.04-x86_64
   -   dbulgup                      ^gdbm@1.18.1%clang@6.0.0 arch=linux-ubuntu18.04-x86_64
   -   qmomdcr                          ^readline@8.0%clang@6.0.0 arch=linux-ubuntu18.04-x86_64
   -   r37jihi                              ^ncurses@6.1%clang@6.0.0~symlinks~termlib arch=linux-ubuntu18.04-x86_64
   -   7jcnfoe              ^automake@1.16.1%clang@6.0.0 arch=linux-ubuntu18.04-x86_64

  ==> Concretized openmpi%gcc ^mvapich2 fabrics=mrail
   -   f6maodn  openmpi@3.1.4%gcc@7.4.0~cuda+cxx_exceptions fabrics=none ~java~legacylaunchers~memchecker~pmi schedulers=none ~sqlite3~thread_multiple+vt arch=linux-ubuntu18.04-x86_64
   -   xcjsxcr      ^hwloc@1.11.11%gcc@7.4.0~cairo~cuda~gl+libxml2~nvml+pci+shared arch=linux-ubuntu18.04-x86_64
   -   vhehc32          ^libpciaccess@0.13.5%gcc@7.4.0 arch=linux-ubuntu18.04-x86_64
  [+]  4neu5jw              ^libtool@2.4.6%gcc@7.4.0 arch=linux-ubuntu18.04-x86_64
  [+]  ut64la6                  ^m4@1.4.18%gcc@7.4.0 patches=3877ab548f88597ab2327a2230ee048d2d07ace1062efe81fc92e91b7f39cd00,fc9b61654a3ba1a8d6cd78ce087e7c96366c290bc8d2c299f09828d793b853c8 +sigsegv arch=linux-ubuntu18.04-x86_64
  [+]  3khohgm                      ^libsigsegv@2.12%gcc@7.4.0 arch=linux-ubuntu18.04-x86_64
  [+]  eifxmps              ^pkgconf@1.6.3%gcc@7.4.0 arch=linux-ubuntu18.04-x86_64
   -   a226ran              ^util-macros@1.19.1%gcc@7.4.0 arch=linux-ubuntu18.04-x86_64
   -   fg5evg4          ^libxml2@2.9.9%gcc@7.4.0~python arch=linux-ubuntu18.04-x86_64
   -   zvmmgjb              ^libiconv@1.16%gcc@7.4.0 arch=linux-ubuntu18.04-x86_64
   -   ur2jffe              ^xz@5.2.4%gcc@7.4.0 arch=linux-ubuntu18.04-x86_64
  [+]  o2viq7y              ^zlib@1.2.11%gcc@7.4.0+optimize+pic+shared arch=linux-ubuntu18.04-x86_64
   -   n6yyt2y          ^numactl@2.0.12%gcc@7.4.0 arch=linux-ubuntu18.04-x86_64
  [+]  g23qful              ^autoconf@2.69%gcc@7.4.0 arch=linux-ubuntu18.04-x86_64
  [+]  cxcj6ei                  ^perl@5.30.0%gcc@7.4.0+cpanm+shared+threads arch=linux-ubuntu18.04-x86_64
  [+]  surdjxd                      ^gdbm@1.18.1%gcc@7.4.0 arch=linux-ubuntu18.04-x86_64
  [+]  hzwkvqa                          ^readline@8.0%gcc@7.4.0 arch=linux-ubuntu18.04-x86_64
  [+]  s4rsior                              ^ncurses@6.1%gcc@7.4.0~symlinks~termlib arch=linux-ubuntu18.04-x86_64
  [+]  io3tplo              ^automake@1.16.1%gcc@7.4.0 arch=linux-ubuntu18.04-x86_64

  ==> Concretized openmpi%clang ^mvapich2 fabrics=mrail
   -   skp3fn3  openmpi@3.1.4%clang@6.0.0~cuda+cxx_exceptions fabrics=none ~java~legacylaunchers~memchecker~pmi schedulers=none ~sqlite3~thread_multiple+vt arch=linux-ubuntu18.04-x86_64
   -   vaxjnb5      ^hwloc@1.11.11%clang@6.0.0~cairo~cuda~gl+libxml2~nvml+pci+shared arch=linux-ubuntu18.04-x86_64
   -   azzjaku          ^libpciaccess@0.13.5%clang@6.0.0 arch=linux-ubuntu18.04-x86_64
   -   s2dxedn              ^libtool@2.4.6%clang@6.0.0 arch=linux-ubuntu18.04-x86_64
   -   ebsmave                  ^m4@1.4.18%clang@6.0.0 patches=3877ab548f88597ab2327a2230ee048d2d07ace1062efe81fc92e91b7f39cd00,fc9b61654a3ba1a8d6cd78ce087e7c96366c290bc8d2c299f09828d793b853c8 +sigsegv arch=linux-ubuntu18.04-x86_64
   -   dfd6u7k                      ^libsigsegv@2.12%clang@6.0.0 arch=linux-ubuntu18.04-x86_64
   -   t2l6efn              ^pkgconf@1.6.3%clang@6.0.0 arch=linux-ubuntu18.04-x86_64
   -   yzzs2pw              ^util-macros@1.19.1%clang@6.0.0 arch=linux-ubuntu18.04-x86_64
   -   5ejde3i          ^libxml2@2.9.9%clang@6.0.0~python arch=linux-ubuntu18.04-x86_64
   -   3fxiwph              ^libiconv@1.16%clang@6.0.0 arch=linux-ubuntu18.04-x86_64
   -   s4ehs7e              ^xz@5.2.4%clang@6.0.0 arch=linux-ubuntu18.04-x86_64
   -   5qffmms              ^zlib@1.2.11%clang@6.0.0+optimize+pic+shared arch=linux-ubuntu18.04-x86_64
   -   lic4g5m          ^numactl@2.0.12%clang@6.0.0 arch=linux-ubuntu18.04-x86_64
   -   lj6tu4n              ^autoconf@2.69%clang@6.0.0 arch=linux-ubuntu18.04-x86_64
   -   nbiong2                  ^perl@5.30.0%clang@6.0.0+cpanm+shared+threads arch=linux-ubuntu18.04-x86_64
   -   dbulgup                      ^gdbm@1.18.1%clang@6.0.0 arch=linux-ubuntu18.04-x86_64
   -   qmomdcr                          ^readline@8.0%clang@6.0.0 arch=linux-ubuntu18.04-x86_64
   -   r37jihi                              ^ncurses@6.1%clang@6.0.0~symlinks~termlib arch=linux-ubuntu18.04-x86_64
   -   7jcnfoe              ^automake@1.16.1%clang@6.0.0 arch=linux-ubuntu18.04-x86_64

  $ spack find -c
  ==> In environment /home/spack/dev
  ==> Root specs
  -- no arch / clang ----------------------------------------------
  boost  boost  openmpi  openmpi  trilinos  trilinos

  -- no arch / gcc ------------------------------------------------
  boost  boost  openmpi  openmpi  trilinos  trilinos

  ==> Concretized roots
  -- linux-ubuntu18.04-x86_64 / clang@6.0.0 -----------------------
  boost@1.70.0  openmpi@3.1.4  trilinos@12.14.1  trilinos@12.14.1

  -- linux-ubuntu18.04-x86_64 / gcc@7.4.0 -------------------------
  boost@1.70.0  openmpi@3.1.4  trilinos@12.14.1  trilinos@12.14.1

  ==> 1 installed package
  -- linux-ubuntu18.04-x86_64 / gcc@7.4.0 -------------------------
  zlib@1.2.11

This allows us to construct our matrices in a more general manner.

We can also exclude some values from a matrix.

.. code-block:: yaml
  :emphasize-lines: 12,13

  # This is a Spack Environment file.
  #
  # It describes a set of packages to be installed, along with
  # configuration setings.
  spack:
    # add package specs to the `specs` list
    specs:
      - matrix:
          - [boost, trilinos, openmpi]
          - [^mpich, ^mvapich2 fabrics=mrail]
          - ['%gcc', '%clang']
        exclude:
          - '%clang ^mvapich2'

    view: False

This will exclude all specs built with clang that depend on
mvapich2. We will now see 3 configurations of ``trilinos``.

.. code-block:: console

  $ spack concretize -f
  ...
  $ spack find -c
  ==> In environment /home/spack/dev
  ==> Root specs
  -- no arch / clang ----------------------------------------------
  boost  openmpi  trilinos

  -- no arch / gcc ------------------------------------------------
  boost  boost  openmpi  openmpi  trilinos  trilinos

  ==> Concretized roots
  -- linux-ubuntu18.04-x86_64 / clang@6.0.0 -----------------------
  boost@1.70.0  openmpi@3.1.4  trilinos@12.14.1

  -- linux-ubuntu18.04-x86_64 / gcc@7.4.0 -------------------------
  boost@1.70.0  openmpi@3.1.4  trilinos@12.14.1  trilinos@12.14.1

  ==> 1 installed package
  -- linux-ubuntu18.04-x86_64 / gcc@7.4.0 -------------------------
  zlib@1.2.11

---------------------------------
Named lists in spack environments
---------------------------------

Spack also allows for named lists in environments. We can use these
lists to clean up our example above. These named lists are defined in
the ``definitions`` key of the ``spack.yaml`` file. Our lists today
will be simple lists of packages or constraints, but in more
complicated examples the named lists can include matrices as well.

Let's clean up our file a bit now.

.. code-block:: yaml

  # This is a Spack Environment file.
  #
  # It describes a set of packages to be installed, along with
  # configuration setings.
  spack:
    # named lists
    definitions:
      - packages: [boost, trilinos, openmpi]
      - mpis: [^mpich, ^mvapich2 fabrics=mrail]
      - compilers: ['%gcc', '%clang']

    specs:
      - matrix:
          - [$packages]
          - [$mpis]
          - [$compilers]
        exclude:
          - '%clang ^mvapich2'

    view: false

This syntax may take some getting used to. Specifically, matrices and
references to named lists are always "splatted" into their current
position, rather than included as a list object in yaml. This may seem
counterintuitive, but it becomes important when we look to combine
lists.

.. code-block:: yaml
  :emphasize-lines: 11,20

  # This is a Spack Environment file.
  #
  # It describes a set of packages to be installed, along with
  # configuration setings.
  spack:
    # named lists
    definitions:
      - packages: [boost, trilinos, openmpi]
      - mpis: [^mpich, ^mvapich2 fabrics=mrail]
      - compilers: ['%gcc', '%clang']
      - singleton_packages: [python, tcl]

    specs:
      - matrix:
          - [$packages]
          - [$mpis]
          - [$compilers]
        exclude:
          - '%clang ^mvapich2'
      - $singleton_packages

    view: false

Our ``specs`` list in this example is still a list of specs, as the
environment requires.

This stack is the same as our previous example, with the additions of
single configurations of python and tcl.

.. code-block:: console

  $ spack concretize -f
  ...
  $ spack find -c
  ==> In environment /home/spack/dev
  ==> Root specs
  python  tcl

  -- no arch / clang ----------------------------------------------
  boost  openmpi  trilinos

  -- no arch / gcc ------------------------------------------------
  boost  boost  openmpi  openmpi  trilinos  trilinos

  ==> Concretized roots
  -- linux-ubuntu18.04-x86_64 / clang@6.0.0 -----------------------
  boost@1.70.0  openmpi@3.1.4  trilinos@12.14.1

  -- linux-ubuntu18.04-x86_64 / gcc@7.4.0 -------------------------
  boost@1.70.0  openmpi@3.1.4  python@3.7.4  tcl@8.6.8  trilinos@12.14.1  trilinos@12.14.1

  ==> 4 installed packages
  -- linux-ubuntu18.04-x86_64 / gcc@7.4.0 -------------------------
  gdbm@1.18.1  ncurses@6.1  readline@8.0  zlib@1.2.11

-----------------------
Conditional definitions
-----------------------

Spec list definitions can also be conditioned on a ``when``
clause. The ``when`` clause is a python conditional that is evaluated
in a restricted environment. The variables available in ``when``
clauses are:

================= ===========
variable name     value
================= ===========
``platform``      The spack platform name for this machine
``os``            The default spack os name and version string for this machine
``target``        The default spack target string for this machine
``architecture``  The default spack architecture string platform-os-target for this machine
``arch``          Alias for ``architecture``
``env``           A dictionary representing the users environment variables
``re``            The python ``re`` module for regex
``hostname``      The hostname of this node
================= ===========

Let's say we only want to use clang if the ``SPACK_STACK_USE_CLANG``
environment variable is set and edit our ``spack.yaml`` file
accordingly.

.. code-block:: yaml
  :emphasize-lines: 10-12

  # This is a Spack Environment file.
  #
  # It describes a set of packages to be installed, along with
  # configuration setings.
  spack:
    # named lists
    definitions:
      - packages: [boost, trilinos, openmpi]
      - mpis: [^mpich, ^mvapich2 fabrics=mrail]
      - compilers: ['%gcc']
      - compilers: ['%clang']
        when: 'env.get("SPACK_STACK_USE_CLANG", "") == 1'
      - singleton_packages: [python, tcl]

    specs:
      - matrix:
          - [$packages]
          - [$mpis]
          - [$compilers]
        exclude:
          - '%clang ^mvapich2'
      - $singleton_packages

    view: false

Note that named lists in the Spack stack are concatenated. We can
define our compilers list in one place unconditionally, and then
conditionally append clang to it when our environment variable is set
properly.

.. code-block:: console

  $ spack concretize -f
  ...
  $ spack find -c
  ==> In environment /home/spack/dev
  ==> Root specs
  python  tcl

  -- no arch / gcc ------------------------------------------------
  boost  boost  openmpi  openmpi  trilinos  trilinos

  ==> Concretized roots
  -- linux-ubuntu18.04-x86_64 / gcc@7.4.0 -------------------------
  boost@1.70.0  openmpi@3.1.4  python@3.7.4  tcl@8.6.8  trilinos@12.14.1  trilinos@12.14.1

  ==> 4 installed packages
  -- linux-ubuntu18.04-x86_64 / gcc@7.4.0 -------------------------
  gdbm@1.18.1  ncurses@6.1  readline@8.0  zlib@1.2.11
  $ export SPACK_STACK_USE_CLANG=1
  $ spack concretize -f
  ...
  $ spack find -c
  ==> In environment /home/spack/dev
  ==> Root specs
  python  tcl

  -- no arch / clang ----------------------------------------------
  boost  openmpi  trilinos

  -- no arch / gcc ------------------------------------------------
  boost  boost  openmpi  openmpi  trilinos  trilinos

  ==> Concretized roots
  -- linux-ubuntu18.04-x86_64 / clang@6.0.0 -----------------------
  boost@1.70.0  openmpi@3.1.4  trilinos@12.14.1

  -- linux-ubuntu18.04-x86_64 / gcc@7.4.0 -------------------------
  boost@1.70.0  openmpi@3.1.4  python@3.7.4  tcl@8.6.8  trilinos@12.14.1  trilinos@12.14.1

  ==> 4 installed packages
  -- linux-ubuntu18.04-x86_64 / gcc@7.4.0 -------------------------
  gdbm@1.18.1  ncurses@6.1  readline@8.0  zlib@1.2.11

----------------
View descriptors
----------------

We told Spack not to create a view for this stack earlier because
simple views won't work with stacks. We've been concretizing multiple
packages of the same name -- they will conflict if linked into the
same view.

To work around this, we will use a view descriptor. This allows us to
define how each package is linked into the view, which packages are
linked into the view, or both.

Let's edit our ``spack.yaml`` file one last time.

.. code-block:: yaml
  :emphasize-lines: 24-33

  # This is a Spack Environment file.
  #
  # It describes a set of packages to be installed, along with
  # configuration setings.
  spack:
    # named lists
    definitions:
      - packages: [boost, trilinos, openmpi]
      - mpis: [^mpich, ^mvapich2 fabrics=mrail]
      - compilers: ['%gcc']
      - compilers: ['%clang']
        when: 'env.get("SPACK_STACK_USE_CLANG", "") == 1'
      - singleton_packages: [python, tcl]

    specs:
      - matrix:
          - [$packages]
          - [$mpis]
          - [$compilers]
        exclude:
          - '%clang ^mvapich2'
      - $singleton_packages

    view:
      default:
        root: views/default
        select: ['%gcc']
        exclude: [^mvapich2]
      full:
        root: views/full
        projections:
          ^mpi: '{name}/{name}-{version}-{^mpi.name}-{^mpi.version}-{compiler.name}-{compiler.version}'
          all: '{name}/{name}-{version}-{compiler.name}-{compiler.version}'

We won't see the views fully filled-in since we don't have time to
install everything in the stack during the tutorial, but the packages
that already happen to be installed will be linked into the views.

.. code-block:: console

  $ spack concretize
  ==> Updating view at views/default
  ==> Updating view at views/full
  $ ls views/default
  bin  include  lib  share
  $ ls views/default/lib
  libcurses.a      libgdbm.so.6.0.0         libmenuw.so           libncurses.so.6     libpanelw.so.6.1
  libcurses.so     libgdbm_compat.a         libmenuw.so.6         libncurses.so.6.1   libpanelw_g.a
  libform.a        libgdbm_compat.la        libmenuw.so.6.1       libncurses_g.a      libreadline.a
  libform.so       libgdbm_compat.so        libmenuw_g.a          libncursesw.a       libreadline.so
  libform.so.6     libgdbm_compat.so.4      libncurses++.a        libncursesw.so      libreadline.so.8
  libform.so.6.1   libgdbm_compat.so.4.0.0  libncurses++.so       libncursesw.so.6    libreadline.so.8.0
  libform_g.a      libhistory.a             libncurses++.so.6     libncursesw.so.6.1  libz.a
  libformw.a       libhistory.so            libncurses++.so.6.1   libncursesw_g.a     libz.so
  libformw.so      libhistory.so.8          libncurses++_g.a      libpanel.a          libz.so.1
  libformw.so.6    libhistory.so.8.0        libncurses++w.a       libpanel.so         libz.so.1.2.11
  libformw.so.6.1  libmenu.a                libncurses++w.so      libpanel.so.6       pkgconfig
  libformw_g.a     libmenu.so               libncurses++w.so.6    libpanel.so.6.1     terminfo
  libgdbm.a        libmenu.so.6             libncurses++w.so.6.1  libpanel_g.a
  libgdbm.la       libmenu.so.6.1           libncurses++w_g.a     libpanelw.a
  libgdbm.so       libmenu_g.a              libncurses.a          libpanelw.so
  libgdbm.so.6     libmenuw.a               libncurses.so         libpanelw.so.6
  $ ls views/full
  gdbm  ncurses  readline  zlib
  $ ls views/full/zlib
  zlib-1.2.11-gcc-7.4.0
  $ ls views/full/zlib/zlib-1.2.11-gcc-7.4.0/
  include  lib  share
  $ ls views/full/zlib/zlib-1.2.11-gcc-7.4.0/lib
  libz.a  libz.so  libz.so.1  libz.so.1.2.11  pkgconfig

The view descriptor also contains a ``link`` key, which is either
"all" or "roots". The default behavior, as we have seen, is to link
all packages, including implicit dependencies, into the view. The
"roots" option links only root packages into the view.

.. code-block:: yaml
  :emphasize-lines: 29

  # This is a Spack Environment file.
  #
  # It describes a set of packages to be installed, along with
  # configuration setings.
  spack:
    # named lists
    definitions:
      - packages: [boost, trilinos, openmpi]
      - mpis: [^mpich, ^mvapich2 fabrics=mrail]
      - compilers: ['%gcc']
      - compilers: ['%clang']
        when: 'env.get("SPACK_STACK_USE_CLANG", "") == 1'
      - singleton_packages: [python, tcl]

    specs:
      - matrix:
          - [$packages]
          - [$mpis]
          - [$compilers]
        exclude:
          - '%clang ^mvapich2'
      - $singleton_packages

    view:
      default:
        root: views/default
        select: ['%gcc']
        exclude: [^mvapich2]
        link: roots
      full:
        root: views/full
        projections:
          ^mpi: '{name}/{name}-{version}-{^mpi.name}-{^mpi.version}-{compiler.name}-{compiler.version}'
          all: '{name}/{name}-{version}-{compiler.name}-{compiler.version}'

.. code-block:: console

  $ ls views/default
  $

In this case, we have installed none of the root packages that match
our default view ``select/exclude`` lists, so nothing is linked into
the default view.
