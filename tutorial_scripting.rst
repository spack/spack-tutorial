.. Copyright Spack Project Developers. See COPYRIGHT file for details.

   SPDX-License-Identifier: (Apache-2.0 OR MIT)

.. include:: common/setup.rst

.. _spack-scripting-tutorial:

====================
Scripting with Spack
====================

This tutorial introduces advanced Spack features related to scripting.
Specifically, we will show us how to write scripts using ``spack find`` and ``spack python``.
Earlier sections of the tutorial demonstrated using ``spack find`` to list and search installed packages.
The ``spack python`` command gives us access to all of Spack's `internal APIs <https://spack.readthedocs.io/en/latest/spack.html>`_, allowing us to write more complex queries, for example.

Since Spack has an extensive API, we will only scratch the surface here.
We will give us enough information to start writing our own scripts and to find what we need, with a little digging.

-----------------------------
Scripting with ``spack find``
-----------------------------

The output we have seen from ``spack find`` has been for human consumption.
But we can take advantage of some advanced options of the command to generate machine-readable output suitable for piping to a script.

^^^^^^^^^^^^^^^^^^^^^^^
``spack find --format``
^^^^^^^^^^^^^^^^^^^^^^^

The main job of ``spack find`` is to show the user a bunch of concrete specs that correspond to installed packages.
By default, we display them with some default attributes, like the ``@version`` suffix we are used to seeing in the output.

The ``--format`` argument allows us to display the specs however we choose, using custom format strings.
Format strings let us specify the names of particular *parts* of the specs we want displayed.
Let us examine the first option.

Suppose we only want to display the *name*, *version*, and first ten (10) characters of the *hash* for every package installed in our Spack instance.
We can generate that output with the following command:

.. literalinclude:: outputs/scripting/find-format.out
   :language: console
   :emphasize-lines: 1

Note that ``name``, ``version``, and ``hash`` are attributes of Spack's internal ``Spec`` object and enclosing them in braces ensures they are output according to our format string.

Using ``spack find --format`` allows us to retrieve just the information we need to do things like pipe the output to typical UNIX command-line tools like ``sort`` or ``uniq``.

^^^^^^^^^^^^^^^^^^^^^
``spack find --json``
^^^^^^^^^^^^^^^^^^^^^

Alternatively, we can get a serialized version of Spec objects in the `JSON` format using the ``--json`` option.
For example, we can get attributes for all installations of ``zlib-ng`` by entering:

.. literalinclude:: outputs/scripting/find-json.out
   :language: console
   :emphasize-lines: 1

The ``spack find --json`` command gives us everything we know about the specs in a structured format.
We can pipe its output to JSON filtering tools like ``jq`` to extract just the parts we want.

Check out the `basic usage docs <https://spack.readthedocs.io/en/latest/basic_usage.html#machine-readable-output>`_ for more examples.


----------------------------------------
Introducing the ``spack python`` command
----------------------------------------

What if we need to perform more advanced queries?

Spack provides the ``spack python`` command to launch a python interpreter with Spack's python modules available to import.
It uses the underlying python for the rest of its commands.
We can write scripts to:

- run Spack commands;
- explore abstract and concretized specs; and
- directly access other internal components of Spack.

Let us launch a Spack-aware python interpreter by entering:

.. literalinclude:: outputs/scripting/spack-python-1.out
   :language: console
   :emphasize-lines: 1,5

As we are in a Python interpreter, use ``exit()`` to end the session and return to the terminal.

^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
Accessing the ``Spec`` object
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Let us take a look at the internal representation of the Spack ``Spec``.
As we already know, specs can be either *abstract* or *concrete*.
The specs we have seen in ``package.py`` files (e.g., in the ``install()`` method) have been *concrete*, or fully specified.
The specs we have typed on the command line have been *abstract*.
Understanding the differences between the two types is key to using Spack's internal API.

Let us open another python interpreter with ``spack python``, instantiate the ``zlib`` spec, and check a few properties of an abstract spec:

.. literalinclude:: outputs/scripting/spack-python-abstract.out
   :language: console
   :emphasize-lines: 1-3,5,11,13

Notice that there are ``Spec`` properties and methods that are not accessible to abstract specs; specifically:

- an exception -- ``SpecError`` -- is raised if we try to access its
  ``version``;
- there are no associated ``versions``; and
- the spec's operating system is ``None``.

Without exiting the interpreter, let us concretize the spec and try again:

.. literalinclude:: outputs/scripting/spack-python-concrete.out
   :language: console
   :emphasize-lines: 1-2,4,6,8

Notice that the concretized spec now:

- has a ``version``;
- has a single entry in its ``versions`` list; and
- the operating system is now ``ubuntu22.04``.

It is not necessary to store the intermediate abstract spec -- we can use the ``.concretized()`` method as shorthand:

.. literalinclude:: outputs/scripting/spack-python-sans-intermediate.out
   :language: console
   :emphasize-lines: 1-2

^^^^^^^^^^^^^^^^^^^^^^^^^^^
Querying the Spack database
^^^^^^^^^^^^^^^^^^^^^^^^^^^

Even more powerful queries are available when we look at the information stored in the Spack database.
The ``Database`` object in Spack is in the ``spack.store.STORE.db`` variable.
We will interact with it mainly through the ``query()`` method.
Let us see the documentation available for ``query()`` using python's built-in ``help()`` function:

.. literalinclude:: outputs/scripting/spack-python-db-query-help.out
   :language: console
   :emphasize-lines: 1-2,9-13

We will primarily make use of the ``query_spec`` argument.

Recall that queries using the ``spack find`` command are limited to queries of attributes with matching values, not values they do *not* have.
In other words, we cannot use the ``spack find`` command for all packages that *do not* satisfy a certain criterion.

We *can* use the python interface to write these types of queries.
For example, let us find all packages that were compiled with ``gcc`` but do not depend on ``mpich``.
We can do this by using custom python code and Spack database queries.
We will use the ``spack.cmd.display_specs`` for output to achieve the same printing functionality as the ``spack find`` command:

.. literalinclude:: outputs/scripting/spack-python-db-query-exclude.out
   :language: console
   :emphasize-lines: 1-5

Now we have a powerful query not available through ``spack find``.

Exit the interpreter to return to the command line:

.. code-block:: console

   >>> exit()

before generalizing the functionality for reuse.

^^^^^^^^^^^^^
Using scripts
^^^^^^^^^^^^^

Now let us parameterize our script to accept arguments on the command line.
With a few generalizations to use the include and exclude specs as arguments, we can create a powerful, general-purpose query script.

Open a file called ``find_exclude.py`` in our preferred editor and add the following code:

.. literalinclude:: outputs/scripting/0.find_exclude.py.example
   :language: python

We added importing and using the system package (``sys``) to access the first and second command line arguments.

Now we can run our new script by entering the following:

.. literalinclude:: outputs/scripting/find-exclude-1.out
   :language: console
   :emphasize-lines: 1

This is beneficial for us, as long as we remember to use Spack's ``python`` command to run it.

-------------------------------------
Using the ``spack-python`` executable
-------------------------------------

What if we want to make our script available for others to use without the hassle of having to remember to use ``spack python``?

We can take advantage of the shebang line typically added as the first line of python executable files.
There is a catch, as we will soon see.

Open the ``find_exclude.py`` script we created above in your preferred editor and add the shebang line with ``spack python`` as the arguments to ``env``:

.. literalinclude:: outputs/scripting/1.find_exclude.py.example
   :language: python
   :emphasize-lines: 1

Exit our editor and add execute permissions to the script before running it as follows:

.. literalinclude:: outputs/scripting/find-exclude-2.out
   :language: console
   :emphasize-lines: 1-2

If we are lucky, it worked on our system, but there is no guarantee.
Some systems only support a single argument on the shebang line (see `here <https://www.in-ulm.de/~mascheck/various/shebang/>`_). ``spack-python``, which is a wrapper script for ``spack python``, solves this issue.

Bring up the file in our editor again and change the ``env`` argument to ``spack-python`` as follows:

.. literalinclude:: outputs/scripting/2.find_exclude.py.example
   :language: python
   :emphasize-lines: 1

Exit our editor and run the script again:

.. literalinclude:: outputs/scripting/find-exclude-3.out
   :language: console
   :emphasize-lines: 1

It will now work on any system with Spack installed.

We now have the basic tools to create our own custom Spack queries and prototype ideas.
We encourage us to contribute them back to Spack in the future.

..  LocalWords:  LLC Spack's APIs hdf zlib literalinclude json uniq jq
..  LocalWords:  docs concretized REPL API SpecError spec's py ubuntu
..  LocalWords:  concretize gcc mpich sys shebang env
