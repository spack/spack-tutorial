.. Copyright 2013-2020 Lawrence Livermore National Security, LLC and other
   Spack Project Developers. See the top-level COPYRIGHT file for details.

   SPDX-License-Identifier: (Apache-2.0 OR MIT)

.. include:: common/setup.rst

.. _spack-scripting-tutorial:

====================
Scripting with Spack
====================

This tutorial introduces advanced capabilities for programmatically
querying information about packages installed with Spack so you can
create your own custom scripts. Specifically, we will discuss how to
use the ``spack find`` and ``spack python`` commands for this purpose. 

Only an introductory-level discussion of the functionality of scripting
with the ``spack python`` command is provides since it exposes the Spack
API. Therefore, more thorough coverage is beyond the scope of this tutorial.

-----------------------
Setting up the tutorial
-----------------------

At this point you may have a lot of packages already installed,
depending on which sections of the tutorial you've done so far.
Let's ensure the outputs for this segment are reasonable using
commands presented in earlier sections of the tutorial.

Remove ``gcc@8.3.0`` and re-install ``hdf5`` and ``zlib@clang``
using the following commands:

.. literalinclude:: outputs/scripting/setup.out
   :language: console
   :emphasize-lines: 1,3,24

Now we are ready to use the Spack's ``find`` and ``python`` subcommands
to query the installed packages.

-----------------------------
Scripting with ``spack find``
-----------------------------

Earlier sections of the tutorial introduced different uses of the
``spack find`` command for querying installed packages at the command
line. Depending on the scripting language and associated tools you want
to use, you can take advantage of the following advanced options to
generate machine-readable output:

- ``--format FORMAT``; and
- ``--json``.

``FORMAT`` is a string that uses the same syntax expected by the Python
``format()`` command. The format string is passed to ``Spec.format``.

Let's see the first option in action.

Suppose you want the name, version, and first ten (10) characters of the
hash for every package installed in your Spack instance with a space 
between each field. You can get the information in the requested
format with the following command:

.. literalinclude:: outputs/scripting/find-format.out
   :language: console
   :emphasize-lines: 1

Alternatively, you can get a serialized version of Spec objects in
the `JSON` format using the ``--json`` option. For example, you can
get attributes for all installations of ``zlib`` by entering:

.. literalinclude:: outputs/scripting/find-json.out
   :language: console
   :emphasize-lines: 1

Refer to
https://spack.readthedocs.io/en/latest/basic_usage.html#machine-readable-output
for more examples.

Hence, the ``spack find`` command is useful for developing scripts
based on queries of attributes of installed packages with specific
values.

----------------------------------------
Introducing the ``spack python`` command
----------------------------------------

What if we need to perform more advanced queries?

Spack provides the ``spack python`` command to launch a python interpreter
with Spack's python modules already imported. It uses the underlying
python for the rest of its commands. So you can write scripts to:

- run Spack commands;
- explore abstract and concretized specs; and
- directly access other internal components of Spack.

Launch a Spack-aware python interpreter and exit the interpreter by
entering the following two commands:

.. literalinclude:: outputs/scripting/spack-python-1.out
   :language: console
   :emphasize-lines: 1,4

Now let's revisit the Spack ``Spec`` object described in earlier tutorials.
We will also look at querying Spack's internal database of installed
packages. We will do our examples from within the python interpreter.

^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
Accessing the ``Spec`` object
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Since the Spack API is available within the interpreter, we can access
both abstract and concrete specs. Typically ``package.py`` files reference
concrete specs within the ``install`` method. But we'll look at the
differences between the two.

Open the python interpreter with ``spack python``, instantiate the
``zlib`` spec, and check a few properties of an abstract spec:

.. literalinclude:: outputs/scripting/spack-python-abstract.out
   :language: console
   :emphasize-lines: 1-3,5,11,13

Notice that there are Spec properties and methods that are not accessible
to abstract specs; specifically:

- an exception -- ``SpecError`` -- is raised if we try to access its
  ``version``;
- there are no associated ``versions``; and
- the platform operating system is ``None``.

Now, from within the same interpreter session, let's concretize the spec
and try again:

.. literalinclude:: outputs/scripting/spack-python-concrete.out
   :language: console
   :emphasize-lines: 1-2,4,6,8

Notice that the concretized spec now:

- has a ``version``;
- has a single entry in its ``versions`` list; and
- the platform operating system is now ``ubuntu18.04``.

It is not necessary to store the intermediate abstract spec as we can
see when we instantiate and concretize a new instance:

.. literalinclude:: outputs/scripting/spack-python-sans-intermediate.out
   :language: console
   :emphasize-lines: 1-2

^^^^^^^^^^^^^^^^^^^^^^^^^^^
Querying the Spack database
^^^^^^^^^^^^^^^^^^^^^^^^^^^

Even more powerful queries are available when we look at the information
stored in the Spack database, which manages read, write, and locking
operations on the backing file system.

Most queries will be using the ``Database.query`` method on the singleton
instance of the database, which is accessed using ``spack.store.db``.
Let's see the documentation available for the ``query`` method using 
python's built-in ``help``.

Enter the following python statements from within the interpreter:

.. literalinclude:: outputs/scripting/spack-python-db-query-help.out
   :language: console
   :emphasize-lines: 1-2,9-13

We will primarily make use of the ``query_spec`` argument.

Recall that queries using the ``spack find`` command are limited to 
queries of attributes with matching values, not values they do *not*
have. In other words, we cannot use the ``spack find`` command for
all packages that *do not* satisfy a certain criterion.
Using the database, we can now perform such queries.

For example, let's find all packages that were compiled with ``gcc``
but do not depend on ``mpich``. We can do this from within the 
interpreter by entering the following python statements, where we
deliberately use ``spack.cmd.display_specs`` to get the output in
the same pretty-printed format as that of the ``spack find`` command:

.. literalinclude:: outputs/scripting/spack-python-db-query-exclude.out
   :language: console
   :emphasize-lines: 1-5

Now we have a powerful query not available through ``spack find``.

Now exit the interpreter so we are back at the command line:

.. code-block:: console

   >>> exit()


^^^^^^^^^^^^^
Using scripts
^^^^^^^^^^^^^

Suppose we want to re-use our query with different specs?

With a few generalizations to accept the include and exclude specs
on the command line, we can create a general-purpose query script.

Open a file called ``find_exclude.py`` in your preferred editor
and add the following code:

.. literalinclude:: outputs/scripting/0.find_exclude.py.example
   :language: python

Notice we added importing and using the system package (``sys``)
to access access the first and second command line arguments. We
also concretized the exclude spec.

Now we can run this new command by entering the following:

.. literalinclude:: outputs/scripting/find-exclude-1.out
   :language: console
   :emphasize-lines: 1

This is *great* for us, as long as we remember to use Spack's
``python`` command to run the script.

-------------------------------------
Using the ``spack-python`` executable
-------------------------------------

What if we want to make our script available for others to use without
the hassle of having to remember to use ``spack python``?

We can take advantage of the shebang line typically added as the
first line of python executable files. But there is a catch, as 
we will soon see.

Open the ``find_exclude.py`` script we created above in your preferred
editor and add the shebang line with ``spack python`` as the arguments
to ``env``:

.. literalinclude:: outputs/scripting/1.find_exclude.py.example
   :language: python
   :emphasize-lines: 1

Then exit our editor and add execute permissions to the script before
running it as follows:

.. literalinclude:: outputs/scripting/find-exclude-2.out
   :language: console
   :emphasize-lines: 1-2

If you are lucky, it worked on your system but there is no guarantee.
Some systems only support a single argument on the shebang line.
So Spack developers created essentially a wrapper script for
``spack python`` to address this issue.

Bring up the file in your editor again and change the ``env`` argument
to ``spack-python`` as follows:

.. literalinclude:: outputs/scripting/2.find_exclude.py.example
   :language: python
   :emphasize-lines: 1

Exit your editor and let's try to run the command again:

.. literalinclude:: outputs/scripting/find-exclude-3.out
   :language: console
   :emphasize-lines: 1

Congratulations!  It will now work on any system with Spack installed.

You now have the basic tools to create your own custom Spack 
queries and prototype ideas that you will, hopefully, eventually
contribute back to Spack.
