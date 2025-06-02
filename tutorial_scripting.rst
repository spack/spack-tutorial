.. Copyright 2013-2023 Lawrence Livermore National Security, LLC and other
   Spack Project Developers. See the top-level COPYRIGHT file for details.

   SPDX-License-Identifier: (Apache-2.0 OR MIT)

.. include:: common/setup.rst

.. _spack-scripting-tutorial:

====================
Scripting with Spack
====================

This tutorial introduces advanced Spack features related to scripting.  
Specifically, we'll show how to write scripts using ``spack find`` and ``spack python``.

Earlier sections demonstrated using ``spack find`` to list and search installed packages.  
The ``spack python`` command provides access to all of Spack's `internal APIs <https://spack.readthedocs.io/en/latest/spack.html>`_, allowing you to write more complex queries.

Since Spack has an extensive API, we'll only scratch the surface here.  
Our goal is to give you enough information to start writing your own scripts and to help you discover what you need—with a little digging.

-----------------------------
Scripting with ``spack find``
-----------------------------

So far, the output we've seen from ``spack find`` has been intended for human consumption.  
However, the command also provides options for generating machine-readable output that can be piped into scripts.

^^^^^^^^^^^^^^^^^^^^^^^
``spack find --format``
^^^^^^^^^^^^^^^^^^^^^^^

The main purpose of ``spack find`` is to display information about concrete specs corresponding to installed packages.  
By default, it shows these specs with a set of standard attributes, such as the familiar ``@version`` suffix.

The ``--format`` argument allows you to customize the output string for each found package.  
Format strings let you specify which *parts* of each spec you want to display.

Let's see this option in action.

Suppose you only want to display the *name*, *version*, and the first ten (10) characters of the *hash* for every package installed in your Spack instance.  
You can generate that output with the following command:

.. literalinclude:: outputs/scripting/find-format.out
   :language: console
   :emphasize-lines: 1

Note that ``name``, ``version``, and ``hash`` are attributes of Spack's internal ``Spec`` object, and enclosing them in braces ensures they are rendered according to your format string.

Using ``spack find --format`` allows you to retrieve only the information you need—making it easy to pipe the output into standard UNIX command-line tools like ``sort`` or ``uniq``.

^^^^^^^^^^^^^^^^^^^^^
``spack find --json``
^^^^^^^^^^^^^^^^^^^^^

Alternatively, you can get a serialized version of ``Spec`` objects in `JSON` format using the ``--json`` option.  
For example, to retrieve attributes for all installations of ``zlib-ng``, you can run:

.. literalinclude:: outputs/scripting/find-json.out
   :language: console
   :emphasize-lines: 1

The ``spack find --json`` command gives you everything we know about the specs in a structured format.
You can pipe its output to JSON filtering tools like ``jq`` to extract just the parts you want.

Check out the `basic usage docs <https://spack.readthedocs.io/en/latest/basic_usage.html#machine-readable-output>`_ for more examples.

----------------------------------------
Introducing the ``spack python`` command
----------------------------------------

What if we need to perform more advanced queries?

Spack provides the ``spack python`` command, which launches a Python interpreter with Spack's modules available for import.  
This interpreter uses the same underlying Python environment that Spack uses for its other commands.

Using this interface, you can write scripts to:

- run Spack commands;  
- explore abstract and concretized specs; and  
- directly access other internal components of Spack.

Let's launch a Spack-aware Python interpreter by entering:

.. literalinclude:: outputs/scripting/spack-python-1.out
   :language: console
   :emphasize-lines: 1,5

Since we are in a Python interpreter, use ``exit()`` to end the session and return to the terminal.

^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
Accessing the ``Spec`` object
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Now let's take a look at the internal representation of the Spack ``Spec``.  
As you may already know, specs can be either *abstract* or *concrete*.  
The specs you've seen in ``package.py`` files (e.g., in the ``install()`` method) have been *concrete*—fully specified with resolved dependencies, compilers, and variants.  
In contrast, the specs you've typed on the command line have been *abstract*.

Understanding the difference between these two forms is key to effectively using Spack's internal API.

Let's open another Python interpreter using ``spack python``, instantiate the ``zlib`` spec, and inspect a few properties of an abstract spec:

.. literalinclude:: outputs/scripting/spack-python-abstract.out
   :language: console
   :emphasize-lines: 1-3,5,11,13

Notice that certain ``Spec`` properties and methods are not accessible on abstract specs:

- An exception—``SpecError``—is raised if you try to access the ``version``.
- There are no associated ``versions``.
- The spec's operating system is ``None``.

Now, without exiting the interpreter, let's concretize the spec and try again:

.. literalinclude:: outputs/scripting/spack-python-concrete.out
   :language: console
   :emphasize-lines: 1-2,4,6,8

Notice that the concretized spec now:

- has a ``version``;
- includes a single entry in its ``versions`` list; and  
- has ``ubuntu22.04`` as its operating system.

It's not necessary to store the intermediate abstract spec—you can use the ``.concretized()`` method as a shorthand:

.. literalinclude:: outputs/scripting/spack-python-sans-intermediate.out
   :language: console
   :emphasize-lines: 1-2

^^^^^^^^^^^^^^^^^^^^^^^^^^^
Querying the Spack database
^^^^^^^^^^^^^^^^^^^^^^^^^^^

More powerful queries become available when interacting with Spack's installation database.  
The ``Database`` object is accessible via the ``spack.store.STORE.db`` variable.  
We'll primarily interact with it through the ``query()`` method.
Let's view the documentation for ``query()`` using Python's built-in ``help()`` function:


.. literalinclude:: outputs/scripting/spack-python-db-query-help.out
   :language: console
   :emphasize-lines: 1-2,9-13

We will primarily make use of the ``query_spec`` argument.

Recall that queries using the ``spack find`` command are primarily intended to *match* packages based on specified criteria.  
However, it's more difficult to use ``spack find`` for queries that involve *excluding* packages based on complex logic (e.g., “does *not* depend on X”).

Using the Python interface, we *can* write these more advanced queries.  
For example, let's find all packages that were compiled with ``gcc`` but do **not** depend on ``mpich``.

We'll use ``spack.cmd.display_specs`` to print the results, replicating the display behavior of the ``spack find`` command:


.. literalinclude:: outputs/scripting/spack-python-db-query-exclude.out
   :language: console
   :emphasize-lines: 1-5

Now we have a powerful query not available through ``spack find``.

Let's exit the interpreter to take us back to the command line:

.. code-block:: console

   >>> exit()

before generalizing the functionality for reuse.

^^^^^^^^^^^^^
Using scripts
^^^^^^^^^^^^^

Now let's parameterize our script to accept command-line arguments.  
With a few generalizations, we can use the include and exclude specs as arguments to create a powerful, general-purpose query script.

Open a file named ``find_exclude.py`` in your preferred editor and add the following code:

.. literalinclude:: outputs/scripting/0.find_exclude.py.example
   :language: python

Notice that we've imported the ``sys`` module and used it to access the first and second command-line arguments.

Now we can run our new script by entering the following:

.. literalinclude:: outputs/scripting/find-exclude-1.out
   :language: console
   :emphasize-lines: 1

This is *great* for us, as long as we remember to use Spack's ``python`` command to run it.

-------------------------------------
Using the ``spack-python`` executable
-------------------------------------

What if we want to make our script available for others to use—without requiring them to remember to run it with ``spack python``?

We can take advantage of a shebang line, typically included as the first line in executable Python scripts.  
However, there's a catch, as we'll see shortly.

Open the ``find_exclude.py`` script you created earlier in your preferred editor, and add a shebang line that invokes ``spack python`` using ``env``:

.. literalinclude:: outputs/scripting/1.find_exclude.py.example
   :language: python
   :emphasize-lines: 1

Then exit our editor and add execute permissions to the script before running it as follows:

.. literalinclude:: outputs/scripting/find-exclude-2.out
   :language: console
   :emphasize-lines: 1-2

If you're lucky, the script worked on your system—but there's no guarantee.  
Some systems only support a single argument on the shebang line (see `here <https://www.in-ulm.de/~mascheck/various/shebang/>`_).  
``spack-python``, a wrapper script for ``spack python``, solves this limitation.

Open the script in your editor again and change the ``env`` argument to ``spack-python`` as shown below:

.. literalinclude:: outputs/scripting/2.find_exclude.py.example
   :language: python
   :emphasize-lines: 1

Exit your editor, and let's run the script again:

.. literalinclude:: outputs/scripting/find-exclude-3.out
   :language: console
   :emphasize-lines: 1

Congratulations! It will now work on any system with Spack installed.

You now have the basic tools to write your own custom Spack queries and prototype new ideas.  
We hope you'll consider contributing them back to Spack in the future.

..  LocalWords:  LLC Spack's APIs hdf zlib literalinclude json uniq jq
..  LocalWords:  docs concretized REPL API SpecError spec's py ubuntu
..  LocalWords:  concretize gcc mpich sys shebang env
