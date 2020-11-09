.. Copyright 2013-2020 Lawrence Livermore National Security, LLC and other
   Spack Project Developers. See the top-level COPYRIGHT file for details.

   SPDX-License-Identifier: (Apache-2.0 OR MIT)

.. include:: common/setup.rst

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
point, you may or may not have a lot of packages installed already. To
ensure reasonable outputs for this section, we will remove the
``gcc@8.3.0`` compiler and install a couple of packages.

.. literalinclude:: outputs/scripting/setup.out
   :language: console

These commands should be familiar from earlier sections of the Spack
tutorial.

-----------------------------
Scripting with ``spack find``
-----------------------------

The ``spack find`` command has two options that are designed for
scripting. The first is the ``--format FORMAT`` option. This option
takes a Spack Spec format string, and calls ``Spec.format`` with that
string for each Spec in the output. This allows custom formatting to
make for easy input to user scripts.

.. literalinclude:: outputs/scripting/find-format.out
   :language: console

The other scripting option to the ``spack find`` command is the
``--json`` option. This formats the serializes the spec objects in the
output as json objects.

.. literalinclude:: outputs/scripting/find-json.out
   :language: console

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

.. literalinclude:: outputs/scripting/spack-python-1.out
   :language: console

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
    File "/home/spack/spack/lib/spack/spack/spec.py", line 3166, in version
      raise SpecError("Spec version is not concrete: " + str(self))
  SpecError: Spec version is not concrete: zlib arch=linux-None-ivybridge
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
  -- linux-ubuntu18.04-x86_64 / gcc@7.5.0 -------------------------
  autoconf@2.69    libiconv@1.16        m4@1.4.18       perl@5.30.3         zlib@1.2.11
  automake@1.16.2  libpciaccess@0.13.5  ncurses@6.2     pkgconf@1.7.3
  gdbm@1.18.1      libsigsegv@2.12      numactl@2.0.12  readline@8.0
  hdf5@1.10.6      libtool@2.4.6        openmpi@3.1.6   util-macros@1.19.1
  hwloc@1.11.11    libxml2@2.9.10       patchelf@0.10   xz@5.2.5

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

.. literalinclude:: outputs/scripting/0.find_exclude.py.example
   :language: python

Now we can run this new command using ``spack python``.

.. literalinclude:: outputs/scripting/find-exclude-1.out
   :language: console

-------------------------------
The ``spack-python`` executable
-------------------------------

The last thing we want to do in this example is run our code using a
shebang.

.. literalinclude:: outputs/scripting/1.find_exclude.py.example
   :language: python
   :emphasize-lines: 1

This is great, and will work on some systems.

.. literalinclude:: outputs/scripting/find-exclude-2.out
   :language: console

However, on some systems the shebang line cannot take multiple
arguments. The ``spack-python`` executable exists to solve this
problem. It provides a single-argument shim layer to the ``spack
python`` command.

.. literalinclude:: outputs/scripting/2.find_exclude.py.example
   :language: python
   :emphasize-lines: 1

Now we can run on any system with Spack installed.

.. literalinclude:: outputs/scripting/find-exclude-3.out
   :language: console

With the ``spack-python`` shebang you can create any infrastructure
you need on top of what Spack already provides, or prototype ideas
that you eventually aim to contribute back to Spack. We've only just
scratched the surface of the capabilities of this command!
