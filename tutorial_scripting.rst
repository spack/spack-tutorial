.. Copyright Spack Project Developers. See COPYRIGHT file for details.

   SPDX-License-Identifier: (Apache-2.0 OR MIT)

.. include:: common/setup.rst

.. _spack-scripting-tutorial:

====================
Scripting with Spack
====================

This tutorial introduces advanced scripting features available in Spack, using the ``spack find`` and ``spack python`` commands.
We've already seen how to list and search installed packages with ``spack find``.
The ``spack python`` command allows us to write more complex queries, as it gives access to all of Spack's `internal APIs <https://spack.readthedocs.io/en/latest/spack.html>`_.

Since Spack has an extensive API, we'll only scratch the surface here.

-----------------------------
Scripting with ``spack find``
-----------------------------

The output we've seen from ``spack find`` has been for human consumption.
We can take advantage of the command's advanced features to generate machine-readable output suitable for piping to a script.

^^^^^^^^^^^^^^^^^^^^^^^
``spack find --format``
^^^^^^^^^^^^^^^^^^^^^^^

The main function of ``spack find`` is to display concrete specs that correspond to installed packages.
By default, they are shown with default attributes, like the ``@version`` suffix.

The ``--format`` argument allows us to display the specs using custom format strings.

Suppose we only want to see the *name*, *version*, and first ten (10) characters of the *hash* for every package installed in the Spack instance.
This output can be generated with the following command:

.. literalinclude:: outputs/scripting/find-format.out
   :language: console
   :emphasize-lines: 1

Note that ``name``, ``version``, and ``hash`` are attributes of Spack's internal ``Spec`` object and enclosing them in braces ensures they are output according to the format string.

Using ``spack find --format`` allows you to retrieve just the information you need to do things like pipe the output to typical UNIX command line tools like ``sort`` or ``uniq``. ``spack find --format`` can be combined with typical command line tools like ``sort`` or ``uniq`` to retrieve information relevant to specific workflows.

^^^^^^^^^^^^^^^^^^^^^
``spack find --json``
^^^^^^^^^^^^^^^^^^^^^

Alternatively, we can get a serialized version of ``Spec`` objects in the `JSON` format using the ``--json`` option.

For example, to get attributes for all installations of ``zlib-ng``:

.. literalinclude:: outputs/scripting/find-json.out
   :language: console

This command provides complete information about any spec of interest in a structured format.
The output of ``spack find --json`` can be piped to JSON filtering tools like ``jq`` to extract specific information.

Visit `basic usage docs <https://spack.readthedocs.io/en/latest/basic_usage.html#machine-readable-output>`_ for more examples.


----------------------------------------
Introducing the ``spack python`` command
----------------------------------------

What if we need to perform more advanced queries?

Spack provides the ``spack python`` command to launch an interpreter with Spack's Python modules available to import.
The underlying Python instance is used for all other commands.
We can write scripts to:

- run Spack commands
- explore abstract and concretized specs
- directly access other internal components of Spack

Let's launch a Spack-aware Python interpreter by entering:

.. literalinclude:: outputs/scripting/spack-python-1.out
   :language: console
   :emphasize-lines: 1,5

As we are in a Python interpreter, use ``exit()`` to end the session and return to the terminal.

^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
Accessing the ``Spec`` object
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Let's take a look at the internal representation of the Spack ``Spec``.
As previously mentioned, specs can be either *abstract* or *concrete*.
The specs we've seen in ``package.py`` files (e.g., in the ``install()`` method) have been *concrete*, or fully specified.
Specs typed on the command line have been *abstract*.
Understanding the differences between the two types is key to using Spack's internal API.

Let's open another Python interpreter with ``spack python``, instantiate the ``zlib`` spec, and check a few properties of an abstract spec:

.. literalinclude:: outputs/scripting/spack-python-abstract.out
   :language: console
   :emphasize-lines: 1-3,5,11,13

Notice that there are ``Spec`` properties and methods not accessible to abstract specs; specifically:

- an exception -- ``SpecError`` -- is raised if we try to access its ``version``
- there are no associated ``versions``
- the spec's operating system is ``None``

Without exiting the interpreter, let's concretize the spec and try again:

.. literalinclude:: outputs/scripting/spack-python-concrete.out
   :language: console
   :emphasize-lines: 1-2,4,6,8

Notice that the concretized spec now:

- has a ``version``
- has a single entry in its ``versions`` list
- the operating system is now ``ubuntu22.04``

It's not necessary to store the intermediate abstract spec, we can use the ``.concretize_one()`` method as shorthand:

.. literalinclude:: outputs/scripting/spack-python-sans-intermediate.out
   :language: console
   :emphasize-lines: 1-2

^^^^^^^^^^^^^^^^^^^^^^^^^^^
Querying the Spack database
^^^^^^^^^^^^^^^^^^^^^^^^^^^

More powerful queries are available when we look at the information stored in the Spack database.
The ``Database`` object in Spack is in the ``spack.store.STORE.db`` variable.
We'll interact with it mainly through the ``query()`` method.
Let's see the documentation available for ``query()`` using Python's built-in ``help()`` function:

.. literalinclude:: outputs/scripting/spack-python-db-query-help.out
   :language: console
   :emphasize-lines: 1-2,9-10

We'll primarily make use of the ``query_spec`` argument.

Recall that ``spack find`` is limited to queries of attributes with matching values.
It cannot be used to find packages that *do not* meet a specific condition.

We *can* use the Python interface to write these types of queries.
For example, let's find all packages that were compiled with ``gcc`` but do not depend on ``mpich``.
We can do this by using custom Python code and Spack database queries.
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

Next, the script can be updated to accept arguments from the command line.
By generalizing the script to take include and exclude specs as arguments, it becomes a flexible, general-purpose query tool.

Open a file called ``find_exclude.py`` in a text editor and add the following code:

.. literalinclude:: outputs/scripting/0.find_exclude.py.example
   :language: python

We added importing and using the system package (``sys``) to access the first and second command line arguments.

Now we can run our new script by entering the following:

.. literalinclude:: outputs/scripting/find-exclude-1.out
   :language: console
   :emphasize-lines: 1

This works well, as long as we remember to use Spack's ``python`` command to run it.

-------------------------------------
Using the ``spack-python`` executable
-------------------------------------

What if the script needs to be shared with others, without requiring them to remember to use ``spack python``?

This can be done by adding a shebang line as the first line of the Python script, which allows it to be run as an executable.
However, there is an important limitation to be aware of, as shown in the next example.

Open the ``find_exclude.py`` script we created above and add the shebang line with ``spack python`` as the arguments to ``env``:

.. literalinclude:: outputs/scripting/1.find_exclude.py.example
   :language: python
   :emphasize-lines: 1

Exit the editor and add execute permissions to the script before running it as follows:

.. literalinclude:: outputs/scripting/find-exclude-2.out
   :language: console
   :emphasize-lines: 1-2

If we're lucky, it ran successfully, but there's no guarantee this will work for every system.
Some systems only support a single argument on the shebang line (see `here <https://www.in-ulm.de/~mascheck/various/shebang/>`_). ``spack-python``, which is a wrapper script for ``spack python``, solves this issue.

Bring up the file in the editor again and change the ``env`` argument to ``spack-python`` as follows:

.. literalinclude:: outputs/scripting/2.find_exclude.py.example
   :language: python
   :emphasize-lines: 1

Exit the editor and run the script again:

.. literalinclude:: outputs/scripting/find-exclude-3.out
   :language: console
   :emphasize-lines: 1

It will now work on any system with Spack installed.

With these tools, we can create custom Spack queries and prototype new ideas.
Contributions that improve or extend common Spack workflows are always welcome in the community.

..  LocalWords:  LLC Spack's APIs hdf zlib literalinclude json uniq jq
..  LocalWords:  docs concretized REPL API SpecError spec's py ubuntu
..  LocalWords:  concretize gcc mpich sys shebang env
