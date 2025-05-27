.. Copyright 2013-2023 Lawrence Livermore National Security, LLC and other
   Spack Project Developers. See the top-level COPYRIGHT file for details.

   SPDX-License-Identifier: (Apache-2.0 OR MIT)

.. include:: common/setup.rst

.. _spack-scripting-tutorial:

====================
Scripting with Spack
====================

This tutorial introduces advanced Spack features related to scripting.
Specifically, we will show you how to write scripts using features of
``spack find`` for machine-readable output and how to leverage
``spack python`` for more complex scripting tasks.
Earlier sections of the tutorial demonstrated using ``spack find`` to
list and search installed packages for human users.
The ``spack python`` command gives you access to all of Spack's internal
Python APIs, allowing you to write powerful custom queries and automation scripts.

Since Spack has an extensive API, we'll only scratch the surface here.
We'll give you enough information to start writing your own scripts and
to find what you need, with a little digging.

-----------------------------
Scripting with ``spack find``
-----------------------------

So far, the output we've seen from ``spack find`` has been primarily for human
consumption. However, ``spack find`` also provides options to generate
machine-readable output suitable for piping to other command-line tools or
for use in scripts.

^^^^^^^^^^^^^^^^^^^^^^^
``spack find --format``
^^^^^^^^^^^^^^^^^^^^^^^

The main job of ``spack find`` is to display information about concrete
specs that correspond to installed packages. By default, it displays them
with common attributes like the version suffix (e.g., ``@1.2.3``) and compiler.

The ``--format`` argument allows you to customize the output string for each
found package. Format strings use curly braces ``{}`` to denote placeholders
that Spack will fill with attributes of the ``Spec`` object. Let's see this
in action.

Suppose you only want to display the *name*, *version*, and the first ten (10)
characters of the package *hash* for every package installed in your Spack
instance. You can generate that output with the following command:

.. literalinclude:: outputs/scripting/find-format.out
   :language: console
   :emphasize-lines: 1

Note that ``name``, ``version``, and ``hash`` are attributes of Spack's
internal ``Spec`` object. Enclosing them in braces (e.g., ``{name}``) in the
format string tells Spack to substitute their values. You can also use format
specifiers, like ``{hash:10s}`` to get the first 10 characters of the hash
string, or ``{/hash}`` to get the full hash prefixed by a slash.
Many attributes of a ``Spec`` can be used here (see `spack help --spec-format`
for a full list).

Using ``spack find --format`` allows you to retrieve just the information
you need to do things like pipe the output to typical UNIX command-line
tools like ``sort`` or ``uniq``.

^^^^^^^^^^^^^^^^^^^^^
``spack find --json``
^^^^^^^^^^^^^^^^^^^^^

Alternatively, you can get a serialized version of Spec objects in
the `JSON` format using the ``--json`` option. For example, you can
get attributes for all installations of ``zlib-ng`` by entering:

.. literalinclude:: outputs/scripting/find-json.out
   :language: console
   :emphasize-lines: 1

The ``spack find --json`` command gives you everything we know about
the specs in a structured format. You can pipe its output to
JSON filtering tools like `jq <https://stedolan.github.io/jq/>`_
to extract just the parts you want.

Check out the `basic usage docs
<https://spack.readthedocs.io/en/latest/basic_usage.html#machine-readable-output>`_
for more examples.


----------------------------------------
Introducing the ``spack python`` command
----------------------------------------

What if we need to perform more advanced queries?

Spack provides the ``spack python`` command to launch a Python interpreter
session with Spack's Python modules automatically added to the `PYTHONPATH`.
This means you can directly import and use Spack's internal APIs.
It uses the same Python interpreter that Spack itself uses.
You can write scripts to:

- run Spack commands;
- explore abstract and concretized specs; and
- directly access other internal components of Spack.

Let's launch a Spack-aware python interpreter by entering:

.. literalinclude:: outputs/scripting/spack-python-1.out
   :language: console
   :emphasize-lines: 1,5

Since we are in a Python interpreter, use ``exit()`` or ``quit()`` to end
the session and return to the terminal.

^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
Accessing the ``Spec`` object
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Now let's take a look at the internal representation of a Spack ``Spec`` object.
As you already know, specs can be either *abstract* (not fully defined, e.g., ``zlib``)
or *concrete* (all choices like version, compiler, variants, etc., are determined).
The specs you typically work with inside a `package.py` file's methods (like
``self.spec`` in the ``install()`` method) are *concrete*. The specs you often
type on the command line (e.g., ``spack install zlib%gcc``) are initially *abstract*
and then Spack *concretizes* them. Understanding this distinction is key to
using Spack's internal API effectively, as some attributes are only available
on concrete specs.

Let's open another Python interpreter with ``spack python``, import the ``Spec``
class, instantiate an abstract spec for ``zlib``, and check a few of its properties:

.. literalinclude:: outputs/scripting/spack-python-abstract.out
   :language: console
   :emphasize-lines: 1-3,5,11,13

Notice that for an abstract spec:

- an attempt to access its ``version`` (which is a single, concrete version)
  would typically raise a ``SpecError`` or return an undefined-like state because
  an abstract spec doesn't have *a* version yet, it has a `VersionList` of possibilities.
- the ``versions`` property (a ``VersionList``) might be empty (any version allowed) or
  contain version ranges, but not a single concrete version.
- other properties like ``architecture`` (which includes the OS) might be ``None`` or
  represent a non-specific default.

Now, without exiting the interpreter, let's concretize this spec using the
``concretize()`` method and observe the changes:

.. literalinclude:: outputs/scripting/spack-python-concrete.out
   :language: console
   :emphasize-lines: 1-2,4,6,8

Notice that the concretized spec now:

- now has a specific ``version`` (e.g., ``Version('1.2.13')``).
- its ``versions`` list now represents a single, concrete version.
- attributes like ``architecture`` (and thus ``os``, ``platform``, ``target``) are now specific (e.g., the OS might be `ubuntu22.04`).

It is not necessary to store the intermediate abstract spec if you only need
the concrete one. You can use the ``.concretized()`` method as a shorthand to
get a concrete spec directly (this creates a new concrete spec from the abstract one):

.. literalinclude:: outputs/scripting/spack-python-sans-intermediate.out
   :language: console
   :emphasize-lines: 1-2

^^^^^^^^^^^^^^^^^^^^^^^^^^^
Querying the Spack database
^^^^^^^^^^^^^^^^^^^^^^^^^^^

Even more powerful queries are available when we interact with the information
stored in Spack's installation database. You can access Spack's database object
via `spack.store.db` (after `import spack.store`). We'll interact with it
mainly through its ``query()`` method. Let's see the documentation available
for ``query()`` using Python's built-in ``help()`` function:

.. literalinclude:: outputs/scripting/spack-python-db-query-help.out
   :language: console
   :emphasize-lines: 1-2,9-13

We will primarily make use of the first argument (which can be a spec string
or `Spec` object to match against) and the `installed=True` keyword argument
to query only installed packages.

Recall that queries using the ``spack find`` command are primarily for finding
packages that *match* certain criteria. It's harder to use `spack find`
for queries that involve *excluding* packages based on complex criteria
(e.g., "does *not* depend on X" while depending on Y).

We *can* use the Python interface to write these more complex types of queries.
For example, let's find all installed packages that were compiled with any version
of ``gcc`` but do *not* depend on ``mpich``. We can do this by iterating
through specs compiled with `gcc` and then checking their dependencies.
For displaying the results, instead of relying on internal display functions,
we can simply print the spec strings.

.. literalinclude:: outputs/scripting/spack-python-db-query-exclude.out
   :language: console
   :emphasize-lines: 1-9

Now we have a powerful query not available through ``spack find``.

Let's exit the interpreter to take us back to the command line:

.. code-block:: console

   >>> exit()

before generalizing the functionality for reuse.

^^^^^^^^^^^^^
Using scripts
^^^^^^^^^^^^^

Now let's parameterize our script to accept arguments on the command
line. With a few generalizations to use the include and exclude spec strings
as arguments, we can create a powerful, general-purpose query script.

Create a file named ``find_exclude.py`` in your current directory with your
preferred text editor and add the following Python code:

.. literalinclude:: outputs/scripting/0.find_exclude.py.example
   :language: python

Notice we added importing and using Python's built-in ``sys`` module
to access command-line arguments via ``sys.argv``.
The script expects two arguments: an "include" spec string and an "exclude"
spec string.

Now we can run our new script by entering the following:

.. literalinclude:: outputs/scripting/find-exclude-1.out
   :language: console
   :emphasize-lines: 1

This works well when invoked with `spack python find_exclude.py ...`,
as `spack python` ensures that Spack's libraries are in the `PYTHONPATH`.

-------------------------------------
Using the ``spack-python`` executable
-------------------------------------

What if we want to make our script available for others to use without
the hassle of having to remember to use ``spack python``?

We can make the script directly executable by adding a "shebang" line
(e.g., `#!/usr/bin/env spack python`) at the very beginning of the script
and making the file executable (e.g., `chmod +x find_exclude.py`).
This tells the system to use `spack python` to interpret the script.
However, there's a common catch with shebang lines on some systems.

Let's try it. Open the ``find_exclude.py`` script again and add the
following shebang line at the top:

.. literalinclude:: outputs/scripting/1.find_exclude.py.example
   :language: python
   :emphasize-lines: 1

Then exit our editor and add execute permissions to the script before
running it as follows:

.. literalinclude:: outputs/scripting/find-exclude-2.out
   :language: console
   :emphasize-lines: 1-2

If you are lucky, this might work on your system. However, there's no guarantee,
as some operating systems only support a single argument on the shebang line after
the interpreter (see `here <https://www.in-ulm.de/~mascheck/various/shebang/>`_ for details).
In `#!/usr/bin/env spack python`, `spack` is the command and `python` is its argument.

To make the script more portable across systems, Spack provides a helper executable
called `spack-python`. This wrapper script is designed to be used in shebang lines
and correctly invokes `spack python`.

Bring up the file in your editor again and change the shebang line to use
``spack-python``:

.. literalinclude:: outputs/scripting/2.find_exclude.py.example
   :language: python
   :emphasize-lines: 1

Exit your editor and let's run the script again:

.. literalinclude:: outputs/scripting/find-exclude-3.out
   :language: console
   :emphasize-lines: 1

Congratulations! The script should now be directly executable (e.g., `./find_exclude.py ...`)
on any system where Spack's `bin` directory (which includes `spack-python`) is in the `PATH`.

You now have the basic tools to create your own custom Spack queries and
prototype ideas using Spack's Python API. We hope you'll find this useful
and perhaps even contribute your scripts or ideas back to the Spack community.

..  LocalWords:  LLC Spack's APIs hdf zlib literalinclude json uniq jq
..  LocalWords:  docs concretized REPL API SpecError spec's py ubuntu
..  LocalWords:  concretize gcc mpich sys shebang env
