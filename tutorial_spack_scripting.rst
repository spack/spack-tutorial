.. Copyright 2013-2019 Lawrence Livermore National Security, LLC and other
   Spack Project Developers. See the top-level COPYRIGHT file for details.

   SPDX-License-Identifier: (Apache-2.0 OR MIT)

.. _spack-scripting-tutorial:

====================
Scripting with Spack
====================

In this tutorial, we will discuss the ``spack python`` command and
scripting with Spack. We will also discuss advanced ``spack find``
usage and how Spack scripting can be used to create more advanced
queries than what are possible with the ``spack find`` command. It
will be impossible to cover everything that can be done with the
``spack python`` command, but we provide an introduction to the types
of functionality available.

---------------------------
Setting up for the tutorial
---------------------------

Depending on which sections of the tutorial you've done up until this
point, you may have a lot of packages installed already. To get more
manageable outputs in this section, we will uninstall everything and
start over.

.. code-block:: console

  $ spack uninstall -ay %gcc
  ...
  $ spack uninstall -ay %clang
  ...
  $ spack compiler rm gcc@8.3.0
  ...
  $ spack install hdf5
  ...
  $ spack install zlib%clang
  ...

All of these commands should be familiar from earlier sections of the
Spack tutorial.

-----------------------------
Scripting with ``spack find``
-----------------------------

The ``spack find`` command has two options that are designed for
scripting. The first is the ``--format FORMAT`` option. This option
takes a Spack Spec format string, and calls ``Spec.format`` with that
string for each Spec in the output. This allows custom formatting to
make for easy input to user scripts.

.. code-block:: console

  $ spack find --format "{name} {version} {hash:10}"
  autoconf 2.69 g23qfulbkb    hdf5 1.10.5 audmuesjjp    libpciaccess 0.13.5 vhehc322oo  libxml2 2.9.9 fg5evg4bxx  numactl 2.0.12 n6yyt2yxl3  pkgconf 1.6.3 eifxmpsduq       xz 5.2.4 ur2jffeua3
  automake 1.16.1 io3tplo73z  hwloc 1.11.11 xcjsxcroxc  libsigsegv 2.12 3khohgmwhb      m4 1.4.18 ut64la6rpt      openmpi 3.1.4 f6maodnm53   readline 8.0 hzwkvqampr        zlib 1.2.11 5qffmms6gw
  gdbm 1.18.1 surdjxdcan      libiconv 1.16 zvmmgjbnfr  libtool 2.4.6 4neu5jwwmu        ncurses 6.1 s4rsiori6b    perl 5.30.0 cxcj6eisjs     util-macros 1.19.1 a226ran4th  zlib 1.2.11 o2viq7yrii

The other scripting option to the ``spack find`` command is the
``--json`` option. This formats the serializes the spec objects in the
output as json objects.

.. code-block:: console

  $ spack find --json
  [
   {
    "name": "zlib",
    "hash": "5qffmms6gwykcikh6aag4h3z4scrfdla",
    "version": "1.2.11",
    "arch": {
     "platform": "linux",
     "platform_os": "ubuntu18.04",
     "target": "x86_64"
    },
    "compiler": {
     "name": "clang",
     "version": "6.0.0"
    },
    "namespace": "builtin",
    "parameters": {
     "optimize": true,
     "pic": true,
     "shared": true,
     "cflags": [],
     "cppflags": [],
     "cxxflags": [],
     "fflags": [],
     "ldflags": [],
     "ldlibs": []
    }
   }
  ]$

----------------------------
The ``spack python`` command
----------------------------

The ``spack python`` command launches a python interpreter in which
the python modules of Spack can be imported. It uses the underlying
python that Spack uses for the rest of its commands. The ``spack
python`` command can be used to run Spack commands, explore abstract
and concretized specs, and directly access other internal components
of Spack. In this tutorial we will cover the ``Spec`` object and
querying Spack's internal database of installed packages.

.. code-block:: console

  $ spack python
  Spack version 0.13.0
  Python 3.6.8, Linux x86_64
  >>> ...

^^^^^^^^^^^^^^^^^^^
The ``Spec`` object
^^^^^^^^^^^^^^^^^^^

In the python interpreter, we can access both abstract and concrete
specs. In the ``package.py`` files you may be more familiar with at
this point, we only access concrete specs in the install method.

Many methods or properties of specs may be inaccessible on abstract
specs.

.. code-block:: console

  >>> from spack.spec import Spec
  >>> s = Spec('zlib target=ivybridge')
  >>> s.concrete
  False
  >>> s.version
  Traceback (most recent call last):
    File "<console>", line 1, in <module>
    File "/home/spack/spack/lib/spack/spack/spec.py", line 3136, in version
      raise SpecError("Spec version is not concrete: " + str(self))
  spack.error.SpecError: Spec version is not concrete: zlib arch=linux-None-ivybridge
  >>> s.versions
  [:]
  >>> s.architecture
  linux-None-ivybridge

These same methods are always set for concrete specs.

.. code-block:: console

  >>> s.concretize()
  >>> s.concrete
  True
  >>> s.version
  Version('1.2.11')
  >>> s.versions
  [Version('1.2.11')]
  >>> s.architecture
  linux-ubuntu18.04-ivybridge

We can also ask Spack for concrete specs without storing the
intermediate abstract spec.

.. code-block:: console

  >>> t = Spec('zlib target=ivybridge').concretized()
  >>> s == t
  True

^^^^^^^^^^^^^^^^^^^^^^^^^^^
Querying the Spack database
^^^^^^^^^^^^^^^^^^^^^^^^^^^

The internal Spack database object is defined in the ``spack.store``
module as ``spack.store.db``. This object transparently handles all
read/write and locking operations on the filesystem object backing the
database. Most queries will be using the aptly named
``Database.query`` method. We can use python's builtin ``help`` method
to see documentation for this method.

.. code-block:: console

  >>> import spack.store
  >>> help(spack.store.db.query)
  Help on method query in module spack.database:

  query(*args, **kwargs) method of spack.database.Database instance
      Query the Spack database including all upstream databases.

      Args:
          query_spec: queries iterate through specs in the database and
              return those that satisfy the supplied ``query_spec``. If
              query_spec is `any`, This will match all specs in the
              database.  If it is a spec, we'll evaluate
              ``spec.satisfies(query_spec)``

          known (bool or any, optional): Specs that are "known" are those
              for which Spack can locate a ``package.py`` file -- i.e.,
              Spack "knows" how to install them.  Specs that are unknown may
              represent packages that existed in a previous version of
              Spack, but have since either changed their name or
              been removed

          installed (bool or any, or InstallStatus or iterable of
              InstallStatus, optional): if ``True``, includes only installed
              specs in the search; if ``False`` only missing specs, and if
              ``any``, all specs in database. If an InstallStatus or iterable
              of InstallStatus, returns specs whose install status
              (installed, deprecated, or missing) matches (one of) the
              InstallStatus. (default: True)

          explicit (bool or any, optional): A spec that was installed
              following a specific user request is marked as explicit. If
              instead it was pulled-in as a dependency of a user requested
              spec it's considered implicit.

          start_date (datetime, optional): filters the query discarding
              specs that have been installed before ``start_date``.

          end_date (datetime, optional): filters the query discarding
              specs that have been installed after ``end_date``.

          hashes (container): list or set of hashes that we can use to
              restrict the search

      Returns:
          list of specs that match the query
  (END)

We will primarily make use of the ``query_spec`` argument in this
tutorial.

Thinking back to our usage of the ``spack find`` command, there are
some queries that we cannot write. For example, it is impossible to
search, using the ``spack find`` command, for all packages that do not
satisfy a certain criterion. So let's use the ``spack python`` command
to find all packages that were compiled with ``gcc`` but do not depend
on ``mpich``. This is just a few lines of code using ``spack python``.

.. code-block:: console

  >>> gcc_query_spec = Spec('%gcc')
  >>> gcc_specs = spack.store.db.query(gcc_query_spec)
  >>> result = filter(lambda spec: not spec.satisfies('^mpich'), gcc_specs)
  >>> import spack.cmd
  >>> spack.cmd.display_specs(result)
  -- linux-ubuntu18.04-x86_64 / gcc@7.4.0 -------------------------
  autoconf@2.69    hwloc@1.11.11        libtool@2.4.6  numactl@2.0.12  readline@8.0
  automake@1.16.1  libiconv@1.16        libxml2@2.9.9  openmpi@3.1.4   util-macros@1.19.1
  gdbm@1.18.1      libpciaccess@0.13.5  m4@1.4.18      perl@5.30.0     xz@5.2.4
  hdf5@1.10.5      libsigsegv@2.12      ncurses@6.1    pkgconf@1.6.3   zlib@1.2.11

^^^^^^^^^^^^^
Using scripts
^^^^^^^^^^^^^

Now that we've developed this functionality, what if we want to run
this query repeatedly? Let's write it out to a file and run that file
using the ``spack python`` command.

First, let's write our query code to a file and give it some
arguments.

.. code-block:: console

  $EDITOR find_exclude.py

.. code-block:: python

  from spack.spec import Spec
  import spack.store
  import spack.cmd
  import sys

  include_spec = Spec(sys.argv[1])
  exclude_spec = Spec(sys.argv[2])

  all_included = spack.store.db.query(include_spec)
  result = filter(lambda spec: not spec.satisfies(exclude_spec), all_included)

  spack.cmd.display_specs(result)

Now we can run this new command using ``spack python``.

.. code-block:: console

  $ spack python find_exclude.py %gcc ^mpich
  -- linux-ubuntu18.04-x86_64 / gcc@7.4.0 -------------------------
  autoconf@2.69    hwloc@1.11.11        libtool@2.4.6  numactl@2.0.12  readline@8.0
  automake@1.16.1  libiconv@1.16        libxml2@2.9.9  openmpi@3.1.4   util-macros@1.19.1
  gdbm@1.18.1      libpciaccess@0.13.5  m4@1.4.18      perl@5.30.0     xz@5.2.4
  hdf5@1.10.5      libsigsegv@2.12      ncurses@6.1    pkgconf@1.6.3   zlib@1.2.11

-------------------------------
The ``spack-python`` executable
-------------------------------

The last thing we want to do in this example is run our code using a
shebang.

.. code-block:: python
  :emphasize-lines: 1

  #!/usr/bin/env spack python
  from spack.spec import Spec
  import spack.store
  import spack.cmd
  import sys

  include_spec = Spec(sys.argv[1])
  exclude_spec = Spec(sys.argv[2])

  all_included = spack.store.db.query(include_spec)
  result = filter(lambda spec: not spec.satisfies(exclude_spec), all_included)

  spack.cmd.display_specs(result)

This is great, and will work on some systems.

.. code-block:: console

  $ chmod u+x find_exclude.py
  $ ./find_exclude.py %gcc ^mpich
  /usr/bin/env: 'spack python': No such file or directory

However, on some systems the shebang line cannot take multiple
arguments. The ``spack-python`` executable exists to solve this
problem. It provides a single-argument shim layer to the ``spack
python`` command.

.. code-block:: python
  :emphasize-lines: 1

  #!/usr/bin/env spack-python
  from spack.spec import Spec
  import spack.store
  import spack.cmd
  import sys

  include_spec = Spec(sys.argv[1])
  exclude_spec = Spec(sys.argv[2])

  all_included = spack.store.db.query(include_spec)
  result = filter(lambda spec: not spec.satisfies(exclude_spec), all_included)

  spack.cmd.display_specs(result)

Now we can run on any system with Spack installed.

.. code-block:: console

  ./find_exclude.py %gcc ^mpich
  -- linux-ubuntu18.04-x86_64 / gcc@7.4.0 -------------------------
  autoconf@2.69    hwloc@1.11.11        libtool@2.4.6  numactl@2.0.12  readline@8.0
  automake@1.16.1  libiconv@1.16        libxml2@2.9.9  openmpi@3.1.4   util-macros@1.19.1
  gdbm@1.18.1      libpciaccess@0.13.5  m4@1.4.18      perl@5.30.0     xz@5.2.4
  hdf5@1.10.5      libsigsegv@2.12      ncurses@6.1    pkgconf@1.6.3   zlib@1.2.11

With the ``spack-python`` shebang you can create any infrastructure
you need on top of what Spack already provides, or prototype ideas
that you eventually aim to contribute back to Spack. We've only just
scratched the surface of the capabilities of this command!
