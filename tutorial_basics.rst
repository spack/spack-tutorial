.. Copyright 2013-2019 Lawrence Livermore National Security, LLC and other
   Spack Project Developers. See the top-level COPYRIGHT file for details.

   SPDX-License-Identifier: (Apache-2.0 OR MIT)

.. _basics-tutorial:

=========================================
Basic Installation Tutorial
=========================================

This tutorial will guide you through the process of installing
software using Spack. We will first cover the `spack install` command,
focusing on the power of the spec syntax and the flexibility it gives
to users. We will also cover the `spack find` command for viewing
installed packages and the `spack uninstall` command. Finally, we will
touch on how Spack manages compilers, especially as it relates to
using Spack-built compilers within Spack. We will include full output
from all of the commands demonstrated, although we will frequently
call attention to only small portions of that output (or merely to the
fact that it succeeded). The provided output is all from an AWS
instance running Ubuntu 18.04

.. _basics-tutorial-install:

----------------
Installing Spack
----------------

Spack works out of the box. Simply clone spack and get going. We will
clone Spack and immediately checkout the most recent release, v0.13.

.. code-block:: console

  $ git clone https://github.com/spack/spack
  Cloning into 'spack'...
  remote: Enumerating objects: 8, done.
  remote: Counting objects: 100% (8/8), done.
  remote: Compressing objects: 100% (3/3), done.
  remote: Total 177911 (delta 6), reused 5 (delta 5), pack-reused 177903
  Receiving objects: 100% (177911/177911), 65.46 MiB | 1.52 MiB/s, done.
  Resolving deltas: 100% (80595/80595), done.
  $ cd spack
  $ git checkout releases/v0.13
  Branch 'releases/v0.13' set up to track remote branch 'releases/v0.13' from 'origin'.
  Switched to a new branch 'releases/v0.13'

Next add Spack to your path. Spack has some nice command line
integration tools, so instead of simply appending to your ``PATH``
variable, source the spack setup script.  Then add Spack to your path.

.. code-block:: console

  $ . share/spack/setup-env.sh

You're good to go!

-----------------
What is in Spack?
-----------------

The ``spack list`` command shows available packages.

.. code-block:: console

  $ spack list
  ==> 3563 packages.
  abinit                    libtirpc                               py-gensim                         r-lpsolve
  abyss                     libtomlc99                             py-geoalchemy2                    r-lsei
  accfft                    libtool                                py-geopandas                      r-lubridate
  ...

The ``spack list`` command can also take a query string. Spack
automatically adds wildcards to both ends of the string. For example,
we can view all available python packages.

.. code-block:: console

  $ spack list py-
  ==> 698 packages.
  lumpy-sv                               py-elasticsearch             py-lockfile           py-pyasn1-modules      py-scientificpython
  perl-file-copy-recursive               py-elephant                  py-logilab-common     py-pybedtools          py-scikit-image
  py-3to2                                py-emcee                     py-lrudict            py-pybigwig            py-scikit-learn
  ...

-------------------
Installing Packages
-------------------

Installing a package with Spack is very simple. To install a piece of
software, simply type ``spack install <package_name>``.

.. code-block:: console

  $ spack install zlib
  ==> Installing zlib
  ==> Searching for binary cache of zlib
  ==> Warning: No Spack mirrors are currently configured
  ==> No binary for zlib found: installing from source
  ==> Fetching http://zlib.net/fossils/zlib-1.2.11.tar.gz
  ########################################################################################################################################### 100.0%
  ==> Staging archive: /tmp/spack/spack-stage/spack-stage-zlib-1.2.11-o2viq7yriiaw6nwqpaa7ltpyzqkaonhb/zlib-1.2.11.tar.gz
  ==> Created stage in /tmp/spack/spack-stage/spack-stage-zlib-1.2.11-o2viq7yriiaw6nwqpaa7ltpyzqkaonhb
  ==> No patches needed for zlib
  ==> Building zlib [Package]
  ==> Executing phase: 'install'
  ==> Successfully installed zlib
    Fetch: 2.71s.  Build: 3.84s.  Total: 6.54s.
  [+] /home/spack/spack/opt/spack/linux-ubuntu18.04-x86_64/gcc-7.4.0/zlib-1.2.11-o2viq7yriiaw6nwqpaa7ltpyzqkaonhb

Spack can install software either from source or from a binary
cache. Packages in the binary cache are signed with GPG for
security. For the tutorial we have prepared a binary cache so you
don't have to wait on slow compilation from source. To be able to
install from the binary cache, we will need to configure Spack with
the location of the binary cache and trust the GPG key that the binary
cache was signed with.

.. code-block:: console

  $ spack mirror add tutorial /mirror
  $ spack gpg trust /mirror/public.key
  gpg: keybox '/home/spack/spack/opt/spack/gpg/pubring.kbx' created
  gpg: /home/spack/spack/opt/spack/gpg/trustdb.gpg: trustdb created
  gpg: key E68DE2A80314303D: public key "prl" imported
  gpg: Total number processed: 1
  gpg:               imported: 1

You'll learn more about configuring Spack later in the tutorial, but
for now you will be able to install the rest of the packages in the
tutorial from a binary cache using the same ``spack install``
command. By default this will install the binary cached version if it
exists and fall back on installing from source.

Spack's spec syntax is the interface by which we can request specific
configurations of the package. The ``%`` sigil is used to specify
compilers.

.. code-block:: console

  $ spack install zlib %clang
  ==> Installing zlib
  ==> Searching for binary cache of zlib
  ==> Finding buildcaches in /mirror/build_cache
  ==> Fetching file:///mirror/build_cache/linux-ubuntu18.04-x86_64-gcc-7.4.0-tcl-8.6.8-t3gp773osdwptcklekqkqg5742zbq42b.spec.yaml
  ########################################################################################################################################### 100.0%
  ==> Fetching file:///mirror/build_cache/linux-ubuntu18.04-x86_64-gcc-7.4.0-trilinos-12.14.1-ioo4i643shsbor4jfjdtzxju2m4hv4we.spec.yaml
  ########################################################################################################################################### 100.0%
  ==> Fetching file:///mirror/build_cache/linux-ubuntu18.04-x86_64-gcc-8.3.0-libsigsegv-2.12-oaiujfnv3i2ya5w3ssywai4u4op5elkf.spec.yaml
  ########################################################################################################################################### 100.0%
  ==> Fetching file:///mirror/build_cache/linux-ubuntu18.04-x86_64-gcc-8.3.0-arpack-ng-3.7.0-5tocvv5kixnbnkrtogqla56ewmi7kdnc.spec.yaml
  ########################################################################################################################################### 100.0%  ...
  ...
  ==> Installing zlib from binary cache
  gpg: Signature made Thu Oct 31 21:58:41 2019 UTC
  gpg:                using RSA key 7D344E2992071B0AAAE1EDB0E68DE2A80314303D
  gpg: Good signature from "prl" [unknown]
  gpg: WARNING: This key is not certified with a trusted signature!
  gpg:          There is no indication that the signature belongs to the owner.
  Primary key fingerprint: 7D34 4E29 9207 1B0A AAE1  EDB0 E68D E2A8 0314 303D
  ==> Relocating package from
    /spack/opt/spack to /home/spack/spack/opt/spack.
  ==> Successfully installed zlib from binary cache
  [+] /home/spack/spack/opt/spack/linux-ubuntu18.04-x86_64/clang-6.0.0/zlib-1.2.11-5qffmms6gwykcikh6aag4h3z4scrfdla

Note that this installation is located separately from the previous
one. We will discuss this in more detail later, but this is part of what
allows Spack to support arbitrarily versioned software.

You can check for particular versions before requesting them. We will
use the ``spack versions`` command to see the available versions, and then
install a different version of ``zlib``.

.. code-block:: console

  $ spack versions zlib
  ==> Safe versions (already checksummed):
    1.2.11  1.2.8  1.2.3
  ==> Remote versions (not yet checksummed):
    1.2.10   1.2.7.1  1.2.5.3  1.2.4.5  1.2.4.1
    ...

The ``@`` sigil is used to specify versions, both of packages and of
compilers.

.. code-block:: console

  $ spack install zlib@1.2.8
  ==> Installing zlib
  ==> Searching for binary cache of zlib
  ==> Finding buildcaches in /mirror/build_cache
  ==> Fetching file:///mirror/build_cache/linux-ubuntu18.04-x86_64/gcc-7.4.0/zlib-1.2.8/linux-ubuntu18.04-x86_64-gcc-7.4.0-zlib-1.2.8-d6ety7cr4j2otoiai3cuqparcdifq35n.spack
  ########################################################################################################################################### 100.0%
  ==> Installing zlib from binary cache
  gpg: Signature made Fri Nov  1 21:51:27 2019 UTC
  gpg:                using RSA key 7D344E2992071B0AAAE1EDB0E68DE2A80314303D
  gpg: Good signature from "prl" [unknown]
  gpg: WARNING: This key is not certified with a trusted signature!
  gpg:          There is no indication that the signature belongs to the owner.
  Primary key fingerprint: 7D34 4E29 9207 1B0A AAE1  EDB0 E68D E2A8 0314 303D
  ==> Relocating package from
    /home/spack/spack/opt/spack to /home/spack/spack/opt/spack.
  ==> Successfully installed zlib from binary cache
  [+] /home/spack/spack/opt/spack/linux-ubuntu18.04-x86_64/gcc-7.4.0/zlib-1.2.8-d6ety7cr4j2otoiai3cuqparcdifq35n

  $ spack install zlib %gcc@6.5.0
  ==> Installing zlib
  ==> Searching for binary cache of zlib
  ==> Finding buildcaches in /mirror/build_cache
  ==> Fetching file:///mirror/build_cache/linux-ubuntu18.04-x86_64/gcc-6.5.0/zlib-1.2.11/linux-ubuntu18.04-x86_64-gcc-6.5.0-zlib-1.2.11-qtrzwovqizyaw2clz5rkhoxr3j5mbrxy.spack
  ########################################################################################################################################### 100.0%
  ==> Installing zlib from binary cache
  gpg: Signature made Thu Oct 31 21:58:25 2019 UTC
  gpg:                using RSA key 7D344E2992071B0AAAE1EDB0E68DE2A80314303D
  gpg: Good signature from "prl" [unknown]
  gpg: WARNING: This key is not certified with a trusted signature!
  gpg:          There is no indication that the signature belongs to the owner.
  Primary key fingerprint: 7D34 4E29 9207 1B0A AAE1  EDB0 E68D E2A8 0314 303D
  ==> Relocating package from
    /spack/opt/spack to /home/spack/spack/opt/spack.
  ==> Successfully installed zlib from binary cache
  [+] /home/spack/spack/opt/spack/linux-ubuntu18.04-x86_64/gcc-6.5.0/zlib-1.2.11-qtrzwovqizyaw2clz5rkhoxr3j5mbrxy

The spec syntax also includes compiler flags. Spack accepts
``cppflags``, ``cflags``, ``cxxflags``, ``fflags``, ``ldflags``, and
``ldlibs`` parameters.  The values of these fields must be quoted on
the command line if they include spaces. These values are injected
into the compile line automatically by the Spack compiler wrappers.

.. code-block:: console

  $ spack install zlib @1.2.8 cppflags=-O3
  ==> Installing zlib
  ==> Searching for binary cache of zlib
  ==> Finding buildcaches in /mirror/build_cache
  ==> Fetching file:///mirror/build_cache/linux-ubuntu18.04-x86_64/gcc-7.4.0/zlib-1.2.8/linux-ubuntu18.04-x86_64-gcc-7.4.0-zlib-1.2.8-hmvjty5ey5ism3za5m7yewpa7in22poc.spack
  ########################################################################################################################################### 100.0%
  ==> Installing zlib from binary cache
  gpg: Signature made Fri Nov  1 21:50:46 2019 UTC
  gpg:                using RSA key 7D344E2992071B0AAAE1EDB0E68DE2A80314303D
  gpg: Good signature from "prl" [unknown]
  gpg: WARNING: This key is not certified with a trusted signature!
  gpg:          There is no indication that the signature belongs to the owner.
  Primary key fingerprint: 7D34 4E29 9207 1B0A AAE1  EDB0 E68D E2A8 0314 303D
  ==> Relocating package from
    /home/spack/spack/opt/spack to /home/spack/spack/opt/spack.
  ==> Successfully installed zlib from binary cache
  [+] /home/spack/spack/opt/spack/linux-ubuntu18.04-x86_64/gcc-7.4.0/zlib-1.2.8-hmvjty5ey5ism3za5m7yewpa7in22poc

The ``spack find`` command is used to query installed packages. Note that
some packages appear identical with the default output. The ``-l`` flag
shows the hash of each package, and the ``-f`` flag shows any non-empty
compiler flags of those packages.

.. code-block:: console

  $ spack find
  ==> 5 installed packages
  -- linux-ubuntu18.04-x86_64 / clang@6.0.0 -----------------------
  zlib@1.2.11

  -- linux-ubuntu18.04-x86_64 / gcc@6.5.0 -------------------------
  zlib@1.2.11

  -- linux-ubuntu18.04-x86_64 / gcc@7.4.0 -------------------------
  zlib@1.2.8  zlib@1.2.8  zlib@1.2.11


  $ spack find -lf
  ==> 5 installed packages
  -- linux-ubuntu18.04-x86_64 / clang@6.0.0 -----------------------
  5qffmms zlib@1.2.11%clang

  -- linux-ubuntu18.04-x86_64 / gcc@6.5.0 -------------------------
  qtrzwov zlib@1.2.11%gcc

  -- linux-ubuntu18.04-x86_64 / gcc@7.4.0 -------------------------
  d6ety7c zlib@1.2.8%gcc   hmvjty5 zlib@1.2.8%gcc  cppflags="-O3"   o2viq7y zlib@1.2.11%gcc


Spack generates a hash for each spec. This hash is a function of the full
provenance of the package, so any change to the spec affects the
hash. Spack uses this value to compare specs and to generate unique
installation directories for every combinatorial version. As we move into
more complicated packages with software dependencies, we can see that
Spack reuses existing packages to satisfy a dependency only when the
existing package's hash matches the desired spec.

.. code-block:: console

  $ spack install tcl
  ==> zlib is already installed in /home/spack/spack/opt/spack/linux-ubuntu18.04-x86_64/gcc-7.4.0/zlib-1.2.11-o2viq7yriiaw6nwqpaa7ltpyzqkaonhb
  ==> Installing tcl
  ==> Searching for binary cache of tcl
  ==> Finding buildcaches in /mirror/build_cache
  ==> Fetching file:///mirror/build_cache/linux-ubuntu18.04-x86_64/gcc-7.4.0/tcl-8.6.8/linux-ubuntu18.04-x86_64-gcc-7.4.0-tcl-8.6.8-t3gp773osdwptcklekqkqg5742zbq42b.spack
  ########################################################################################################################################### 100.0%
  ==> Installing tcl from binary cache
  gpg: Signature made Thu Oct 31 22:20:41 2019 UTC
  gpg:                using RSA key 7D344E2992071B0AAAE1EDB0E68DE2A80314303D
  gpg: Good signature from "prl" [unknown]
  gpg: WARNING: This key is not certified with a trusted signature!
  gpg:          There is no indication that the signature belongs to the owner.
  Primary key fingerprint: 7D34 4E29 9207 1B0A AAE1  EDB0 E68D E2A8 0314 303D
  ==> Relocating package from
    /spack/opt/spack to /home/spack/spack/opt/spack.
  ==> Successfully installed tcl from binary cache
  [+] /home/spack/spack/opt/spack/linux-ubuntu18.04-x86_64/gcc-7.4.0/tcl-8.6.8-t3gp773osdwptcklekqkqg5742zbq42b

Dependencies can be explicitly requested using the ``^`` sigil. Note that
the spec syntax is recursive. Anything we could specify about the
top-level package, we can also specify about a dependency using ``^``.

.. code-block:: console

  $ spack install tcl ^zlib @1.2.8 %clang
  ==> Installing zlib
  ==> Searching for binary cache of zlib
  ==> Finding buildcaches in /mirror/build_cache
  ==> Fetching file:///mirror/build_cache/linux-ubuntu18.04-x86_64/clang-6.0.0/zlib-1.2.8/linux-ubuntu18.04-x86_64-clang-6.0.0-zlib-1.2.8-pdfmc5xxsopitln5y7wcirbmfz47o5tp.spack
  ########################################################################################################################################### 100.0%
  ==> Installing zlib from binary cache
  gpg: Signature made Thu Oct 31 21:56:52 2019 UTC
  gpg:                using RSA key 7D344E2992071B0AAAE1EDB0E68DE2A80314303D
  gpg: Good signature from "prl" [unknown]
  gpg: WARNING: This key is not certified with a trusted signature!
  gpg:          There is no indication that the signature belongs to the owner.
  Primary key fingerprint: 7D34 4E29 9207 1B0A AAE1  EDB0 E68D E2A8 0314 303D
  ==> Relocating package from
    /spack/opt/spack to /home/spack/spack/opt/spack.
  ==> Successfully installed zlib from binary cache
  [+] /home/spack/spack/opt/spack/linux-ubuntu18.04-x86_64/clang-6.0.0/zlib-1.2.8-pdfmc5xxsopitln5y7wcirbmfz47o5tp
  ==> Installing tcl
  ==> Searching for binary cache of tcl
  ==> Fetching file:///mirror/build_cache/linux-ubuntu18.04-x86_64/clang-6.0.0/tcl-8.6.8/linux-ubuntu18.04-x86_64-clang-6.0.0-tcl-8.6.8-4ef57swt6n2ke74mhx4pny32z7hzxif3.spack
  ########################################################################################################################################### 100.0%
  ==> Installing tcl from binary cache
  gpg: Signature made Thu Oct 31 22:15:33 2019 UTC
  gpg:                using RSA key 7D344E2992071B0AAAE1EDB0E68DE2A80314303D
  gpg: Good signature from "prl" [unknown]
  gpg: WARNING: This key is not certified with a trusted signature!
  gpg:          There is no indication that the signature belongs to the owner.
  Primary key fingerprint: 7D34 4E29 9207 1B0A AAE1  EDB0 E68D E2A8 0314 303D
  ==> Relocating package from
    /spack/opt/spack to /home/spack/spack/opt/spack.
  ==> Successfully installed tcl from binary cache
  [+] /home/spack/spack/opt/spack/linux-ubuntu18.04-x86_64/clang-6.0.0/tcl-8.6.8-4ef57swt6n2ke74mhx4pny32z7hzxif3

Packages can also be referred to from the command line by their package
hash. Using the ``spack find -lf`` command earlier we saw that the hash
of our optimized installation of zlib (``cppflags="-O3"``) began with
``hmvjty5``. We can now explicitly build with that package without typing
the entire spec, by using the ``/`` sigil to refer to it by hash. As with
other tools like git, you do not need to specify an *entire* hash on the
command line.  You can specify just enough digits to identify a hash
uniquely.  If a hash prefix is ambiguous (i.e., two or more installed
packages share the prefix) then spack will report an error.

.. code-block:: console

  $ spack install tcl ^/hmv
  ==> zlib is already installed in /home/spack/spack/opt/spack/linux-ubuntu18.04-x86_64/gcc-7.4.0/zlib-1.2.8-hmvjty5ey5ism3za5m7yewpa7in22poc
  ==> Installing tcl
  ==> Searching for binary cache of tcl
  ==> Finding buildcaches in /mirror/build_cache
  ==> Fetching file:///mirror/build_cache/linux-ubuntu18.04-x86_64/gcc-7.4.0/tcl-8.6.8/linux-ubuntu18.04-x86_64-gcc-7.4.0-tcl-8.6.8-nstkcalz4ryzfzirsyeql5dmmi2chcig.spack
  ########################################################################################################################################### 100.0%
  ==> Installing tcl from binary cache
  gpg: Signature made Fri Nov  1 21:51:25 2019 UTC
  gpg:                using RSA key 7D344E2992071B0AAAE1EDB0E68DE2A80314303D
  gpg: Good signature from "prl" [unknown]
  gpg: WARNING: This key is not certified with a trusted signature!
  gpg:          There is no indication that the signature belongs to the owner.
  Primary key fingerprint: 7D34 4E29 9207 1B0A AAE1  EDB0 E68D E2A8 0314 303D
  ==> Relocating package from
    /home/spack/spack/opt/spack to /home/spack/spack/opt/spack.
  ==> Successfully installed tcl from binary cache
  [+] /home/spack/spack/opt/spack/linux-ubuntu18.04-x86_64/gcc-7.4.0/tcl-8.6.8-nstkcalz4ryzfzirsyeql5dmmi2chcig

The ``spack find`` command can also take a ``-d`` flag, which can show
dependency information. Note that each package has a top-level entry,
even if it also appears as a dependency.

.. code-block:: console

  $ spack find -ldf
  ==> 9 installed packages
  -- linux-ubuntu18.04-x86_64 / clang@6.0.0 -----------------------
  4ef57sw tcl@8.6.8%clang
  pdfmc5x     zlib@1.2.8%clang

  pdfmc5x zlib@1.2.8%clang

  5qffmms zlib@1.2.11%clang


  -- linux-ubuntu18.04-x86_64 / gcc@6.5.0 -------------------------
  qtrzwov zlib@1.2.11%gcc


  -- linux-ubuntu18.04-x86_64 / gcc@7.4.0 -------------------------
  nstkcal tcl@8.6.8%gcc
  hmvjty5     zlib@1.2.8%gcc  cppflags="-O3"

  t3gp773 tcl@8.6.8%gcc
  o2viq7y     zlib@1.2.11%gcc

  d6ety7c zlib@1.2.8%gcc

  hmvjty5 zlib@1.2.8%gcc  cppflags="-O3"

  o2viq7y zlib@1.2.11%gcc


Let's move on to slightly more complicated packages. ``HDF5`` is a
good example of a more complicated package, with an MPI dependency. If
we install it "out of the box," it will build with ``openmpi``.

.. code-block:: console

  $ spack install hdf5
  ==> Installing libsigsegv
  ==> Searching for binary cache of libsigsegv
  ==> Finding buildcaches in /mirror/build_cache
  ==> Fetching file:///mirror/build_cache/linux-ubuntu18.04-x86_64/gcc-7.4.0/libsigsegv-2.12/linux-ubuntu18.04-x86_64-gcc-7.4.0-libsigsegv-2.12-3khohgmwhbgvxehlt7rcnnzqfxelyv4p.spack
  ########################################################################################################################################### 100.0%
  ==> Installing libsigsegv from binary cache
  gpg: Signature made Thu Oct 31 22:08:36 2019 UTC
  gpg:                using RSA key 7D344E2992071B0AAAE1EDB0E68DE2A80314303D
  gpg: Good signature from "prl" [unknown]
  gpg: WARNING: This key is not certified with a trusted signature!
  gpg:          There is no indication that the signature belongs to the owner.
  Primary key fingerprint: 7D34 4E29 9207 1B0A AAE1  EDB0 E68D E2A8 0314 303D
  ==> Relocating package from
    /spack/opt/spack to /home/spack/spack/opt/spack.
  ==> Successfully installed libsigsegv from binary cache
  [+] /home/spack/spack/opt/spack/linux-ubuntu18.04-x86_64/gcc-7.4.0/libsigsegv-2.12-3khohgmwhbgvxehlt7rcnnzqfxelyv4p
  ==> Installing m4
  ==> Searching for binary cache of m4
  ==> Fetching file:///mirror/build_cache/linux-ubuntu18.04-x86_64/gcc-7.4.0/m4-1.4.18/linux-ubuntu18.04-x86_64-gcc-7.4.0-m4-1.4.18-ut64la6rptcwos3uwl2kp5mle572hlhi.spack
  ########################################################################################################################################### 100.0%
  ==> Installing m4 from binary cache
  gpg: Signature made Thu Oct 31 22:14:20 2019 UTC
  gpg:                using RSA key 7D344E2992071B0AAAE1EDB0E68DE2A80314303D
  gpg: Good signature from "prl" [unknown]
  gpg: WARNING: This key is not certified with a trusted signature!
  gpg:          There is no indication that the signature belongs to the owner.
  Primary key fingerprint: 7D34 4E29 9207 1B0A AAE1  EDB0 E68D E2A8 0314 303D
  ==> Relocating package from
    /spack/opt/spack to /home/spack/spack/opt/spack.
  ==> Successfully installed m4 from binary cache
  [+] /home/spack/spack/opt/spack/linux-ubuntu18.04-x86_64/gcc-7.4.0/m4-1.4.18-ut64la6rptcwos3uwl2kp5mle572hlhi
  ==> Installing libtool
  ==> Searching for binary cache of libtool
  ==> Fetching file:///mirror/build_cache/linux-ubuntu18.04-x86_64/gcc-7.4.0/libtool-2.4.6/linux-ubuntu18.04-x86_64-gcc-7.4.0-libtool-2.4.6-4neu5jwwmuo26mjs6363q6bupczjk6hk.spack
  ########################################################################################################################################### 100.0%
  ==> Installing libtool from binary cache
  gpg: Signature made Thu Oct 31 22:21:53 2019 UTC
  gpg:                using RSA key 7D344E2992071B0AAAE1EDB0E68DE2A80314303D
  gpg: Good signature from "prl" [unknown]
  gpg: WARNING: This key is not certified with a trusted signature!
  gpg:          There is no indication that the signature belongs to the owner.
  Primary key fingerprint: 7D34 4E29 9207 1B0A AAE1  EDB0 E68D E2A8 0314 303D
  ==> Relocating package from
    /spack/opt/spack to /home/spack/spack/opt/spack.
  ==> Successfully installed libtool from binary cache
  [+] /home/spack/spack/opt/spack/linux-ubuntu18.04-x86_64/gcc-7.4.0/libtool-2.4.6-4neu5jwwmuo26mjs6363q6bupczjk6hk
  ==> Installing pkgconf
  ==> Searching for binary cache of pkgconf
  ==> Fetching file:///mirror/build_cache/linux-ubuntu18.04-x86_64/gcc-7.4.0/pkgconf-1.6.3/linux-ubuntu18.04-x86_64-gcc-7.4.0-pkgconf-1.6.3-eifxmpsduqbsvgrk2sx5pn7cy5eraanr.spack
  ########################################################################################################################################### 100.0%
  ==> Installing pkgconf from binary cache
  gpg: Signature made Thu Oct 31 21:58:44 2019 UTC
  gpg:                using RSA key 7D344E2992071B0AAAE1EDB0E68DE2A80314303D
  gpg: Good signature from "prl" [unknown]
  gpg: WARNING: This key is not certified with a trusted signature!
  gpg:          There is no indication that the signature belongs to the owner.
  Primary key fingerprint: 7D34 4E29 9207 1B0A AAE1  EDB0 E68D E2A8 0314 303D
  ==> Relocating package from
    /spack/opt/spack to /home/spack/spack/opt/spack.
  ==> Successfully installed pkgconf from binary cache
  [+] /home/spack/spack/opt/spack/linux-ubuntu18.04-x86_64/gcc-7.4.0/pkgconf-1.6.3-eifxmpsduqbsvgrk2sx5pn7cy5eraanr
  ==> Installing util-macros
  ==> Searching for binary cache of util-macros
  ==> Fetching file:///mirror/build_cache/linux-ubuntu18.04-x86_64/gcc-7.4.0/util-macros-1.19.1/linux-ubuntu18.04-x86_64-gcc-7.4.0-util-macros-1.19.1-a226ran4thxadofd7yow3sfng3gy3t3k.spack
  ########################################################################################################################################### 100.0%
  ==> Installing util-macros from binary cache
  gpg: Signature made Thu Oct 31 22:21:21 2019 UTC
  gpg:                using RSA key 7D344E2992071B0AAAE1EDB0E68DE2A80314303D
  gpg: Good signature from "prl" [unknown]
  gpg: WARNING: This key is not certified with a trusted signature!
  gpg:          There is no indication that the signature belongs to the owner.
  Primary key fingerprint: 7D34 4E29 9207 1B0A AAE1  EDB0 E68D E2A8 0314 303D
  ==> Relocating package from
    /spack/opt/spack to /home/spack/spack/opt/spack.
  ==> Successfully installed util-macros from binary cache
  [+] /home/spack/spack/opt/spack/linux-ubuntu18.04-x86_64/gcc-7.4.0/util-macros-1.19.1-a226ran4thxadofd7yow3sfng3gy3t3k
  ==> Installing libpciaccess
  ==> Searching for binary cache of libpciaccess
  ==> Fetching file:///mirror/build_cache/linux-ubuntu18.04-x86_64/gcc-7.4.0/libpciaccess-0.13.5/linux-ubuntu18.04-x86_64-gcc-7.4.0-libpciaccess-0.13.5-vhehc322oo5ipbbk465m6py6zzr4kdam.spack
  ########################################################################################################################################### 100.0%
  ==> Installing libpciaccess from binary cache
  gpg: Signature made Thu Oct 31 21:51:33 2019 UTC
  gpg:                using RSA key 7D344E2992071B0AAAE1EDB0E68DE2A80314303D
  gpg: Good signature from "prl" [unknown]
  gpg: WARNING: This key is not certified with a trusted signature!
  gpg:          There is no indication that the signature belongs to the owner.
  Primary key fingerprint: 7D34 4E29 9207 1B0A AAE1  EDB0 E68D E2A8 0314 303D
  ==> Relocating package from
    /spack/opt/spack to /home/spack/spack/opt/spack.
  ==> Successfully installed libpciaccess from binary cache
  [+] /home/spack/spack/opt/spack/linux-ubuntu18.04-x86_64/gcc-7.4.0/libpciaccess-0.13.5-vhehc322oo5ipbbk465m6py6zzr4kdam
  ==> Installing libiconv
  ==> Searching for binary cache of libiconv
  ==> Fetching file:///mirror/build_cache/linux-ubuntu18.04-x86_64/gcc-7.4.0/libiconv-1.16/linux-ubuntu18.04-x86_64-gcc-7.4.0-libiconv-1.16-zvmmgjbnfrzbo3hl2ijqxcjpkiv7q3ab.spack
  ########################################################################################################################################### 100.0%
  ==> Installing libiconv from binary cache
  gpg: Signature made Thu Oct 31 21:46:02 2019 UTC
  gpg:                using RSA key 7D344E2992071B0AAAE1EDB0E68DE2A80314303D
  gpg: Good signature from "prl" [unknown]
  gpg: WARNING: This key is not certified with a trusted signature!
  gpg:          There is no indication that the signature belongs to the owner.
  Primary key fingerprint: 7D34 4E29 9207 1B0A AAE1  EDB0 E68D E2A8 0314 303D
  ==> Relocating package from
    /spack/opt/spack to /home/spack/spack/opt/spack.
  ==> Successfully installed libiconv from binary cache
  [+] /home/spack/spack/opt/spack/linux-ubuntu18.04-x86_64/gcc-7.4.0/libiconv-1.16-zvmmgjbnfrzbo3hl2ijqxcjpkiv7q3ab
  ==> Installing xz
  ==> Searching for binary cache of xz
  ==> Fetching file:///mirror/build_cache/linux-ubuntu18.04-x86_64/gcc-7.4.0/xz-5.2.4/linux-ubuntu18.04-x86_64-gcc-7.4.0-xz-5.2.4-ur2jffeua3gzg5otnmqgfnfdexgtjxcl.spack
  ########################################################################################################################################### 100.0%
  ==> Installing xz from binary cache
  gpg: Signature made Thu Oct 31 21:54:13 2019 UTC
  gpg:                using RSA key 7D344E2992071B0AAAE1EDB0E68DE2A80314303D
  gpg: Good signature from "prl" [unknown]
  gpg: WARNING: This key is not certified with a trusted signature!
  gpg:          There is no indication that the signature belongs to the owner.
  Primary key fingerprint: 7D34 4E29 9207 1B0A AAE1  EDB0 E68D E2A8 0314 303D
  ==> Relocating package from
    /spack/opt/spack to /home/spack/spack/opt/spack.
  ==> Successfully installed xz from binary cache
  [+] /home/spack/spack/opt/spack/linux-ubuntu18.04-x86_64/gcc-7.4.0/xz-5.2.4-ur2jffeua3gzg5otnmqgfnfdexgtjxcl
  ==> zlib is already installed in /home/spack/spack/opt/spack/linux-ubuntu18.04-x86_64/gcc-7.4.0/zlib-1.2.11-o2viq7yriiaw6nwqpaa7ltpyzqkaonhb
  ==> Installing libxml2
  ==> Searching for binary cache of libxml2
  ==> Fetching file:///mirror/build_cache/linux-ubuntu18.04-x86_64/gcc-7.4.0/libxml2-2.9.9/linux-ubuntu18.04-x86_64-gcc-7.4.0-libxml2-2.9.9-fg5evg4bxx4jy3paclojb46lok4fjclf.spack
  ########################################################################################################################################### 100.0%
  ==> Installing libxml2 from binary cache
  gpg: Signature made Thu Oct 31 21:51:18 2019 UTC
  gpg:                using RSA key 7D344E2992071B0AAAE1EDB0E68DE2A80314303D
  gpg: Good signature from "prl" [unknown]
  gpg: WARNING: This key is not certified with a trusted signature!
  gpg:          There is no indication that the signature belongs to the owner.
  Primary key fingerprint: 7D34 4E29 9207 1B0A AAE1  EDB0 E68D E2A8 0314 303D
  ==> Relocating package from
    /spack/opt/spack to /home/spack/spack/opt/spack.
  ==> Successfully installed libxml2 from binary cache
  [+] /home/spack/spack/opt/spack/linux-ubuntu18.04-x86_64/gcc-7.4.0/libxml2-2.9.9-fg5evg4bxx4jy3paclojb46lok4fjclf
  ==> Installing ncurses
  ==> Searching for binary cache of ncurses
  ==> Fetching file:///mirror/build_cache/linux-ubuntu18.04-x86_64/gcc-7.4.0/ncurses-6.1/linux-ubuntu18.04-x86_64-gcc-7.4.0-ncurses-6.1-s4rsiori6blknfxf2jx4nbfxfzvcww2k.spack
  ########################################################################################################################################### 100.0%
  ==> Installing ncurses from binary cache
  gpg: Signature made Thu Oct 31 22:16:11 2019 UTC
  gpg:                using RSA key 7D344E2992071B0AAAE1EDB0E68DE2A80314303D
  gpg: Good signature from "prl" [unknown]
  gpg: WARNING: This key is not certified with a trusted signature!
  gpg:          There is no indication that the signature belongs to the owner.
  Primary key fingerprint: 7D34 4E29 9207 1B0A AAE1  EDB0 E68D E2A8 0314 303D
  ==> Relocating package from
    /spack/opt/spack to /home/spack/spack/opt/spack.
  ==> Successfully installed ncurses from binary cache
  [+] /home/spack/spack/opt/spack/linux-ubuntu18.04-x86_64/gcc-7.4.0/ncurses-6.1-s4rsiori6blknfxf2jx4nbfxfzvcww2k
  ==> Installing readline
  ==> Searching for binary cache of readline
  ==> Fetching file:///mirror/build_cache/linux-ubuntu18.04-x86_64/gcc-7.4.0/readline-8.0/linux-ubuntu18.04-x86_64-gcc-7.4.0-readline-8.0-hzwkvqampr3c6mfceyxq4xej7eyxoxoj.spack
  ########################################################################################################################################### 100.0%
  ==> Installing readline from binary cache
  gpg: Signature made Thu Oct 31 21:54:17 2019 UTC
  gpg:                using RSA key 7D344E2992071B0AAAE1EDB0E68DE2A80314303D
  gpg: Good signature from "prl" [unknown]
  gpg: WARNING: This key is not certified with a trusted signature!
  gpg:          There is no indication that the signature belongs to the owner.
  Primary key fingerprint: 7D34 4E29 9207 1B0A AAE1  EDB0 E68D E2A8 0314 303D
  ==> Relocating package from
    /spack/opt/spack to /home/spack/spack/opt/spack.
  ==> Successfully installed readline from binary cache
  [+] /home/spack/spack/opt/spack/linux-ubuntu18.04-x86_64/gcc-7.4.0/readline-8.0-hzwkvqampr3c6mfceyxq4xej7eyxoxoj
  ==> Installing gdbm
  ==> Searching for binary cache of gdbm
  ==> Fetching file:///mirror/build_cache/linux-ubuntu18.04-x86_64/gcc-7.4.0/gdbm-1.18.1/linux-ubuntu18.04-x86_64-gcc-7.4.0-gdbm-1.18.1-surdjxdcankv3xqk5tnnwroz3tor77o7.spack
  ########################################################################################################################################### 100.0%
  ==> Installing gdbm from binary cache
  gpg: Signature made Thu Oct 31 22:00:47 2019 UTC
  gpg:                using RSA key 7D344E2992071B0AAAE1EDB0E68DE2A80314303D
  gpg: Good signature from "prl" [unknown]
  gpg: WARNING: This key is not certified with a trusted signature!
  gpg:          There is no indication that the signature belongs to the owner.
  Primary key fingerprint: 7D34 4E29 9207 1B0A AAE1  EDB0 E68D E2A8 0314 303D
  ==> Relocating package from
    /spack/opt/spack to /home/spack/spack/opt/spack.
  ==> Successfully installed gdbm from binary cache
  [+] /home/spack/spack/opt/spack/linux-ubuntu18.04-x86_64/gcc-7.4.0/gdbm-1.18.1-surdjxdcankv3xqk5tnnwroz3tor77o7
  ==> Installing perl
  ==> Searching for binary cache of perl
  ==> Fetching file:///mirror/build_cache/linux-ubuntu18.04-x86_64/gcc-7.4.0/perl-5.30.0/linux-ubuntu18.04-x86_64-gcc-7.4.0-perl-5.30.0-cxcj6eisjsfp3iv6xlio6rvc33fbxfmc.spack
  ########################################################################################################################################### 100.0%
  ==> Installing perl from binary cache
  gpg: Signature made Thu Oct 31 22:17:41 2019 UTC
  gpg:                using RSA key 7D344E2992071B0AAAE1EDB0E68DE2A80314303D
  gpg: Good signature from "prl" [unknown]
  gpg: WARNING: This key is not certified with a trusted signature!
  gpg:          There is no indication that the signature belongs to the owner.
  Primary key fingerprint: 7D34 4E29 9207 1B0A AAE1  EDB0 E68D E2A8 0314 303D
  ==> Relocating package from
    /spack/opt/spack to /home/spack/spack/opt/spack.
  ==> Successfully installed perl from binary cache
  [+] /home/spack/spack/opt/spack/linux-ubuntu18.04-x86_64/gcc-7.4.0/perl-5.30.0-cxcj6eisjsfp3iv6xlio6rvc33fbxfmc
  ==> Installing autoconf
  ==> Searching for binary cache of autoconf
  ==> Fetching file:///mirror/build_cache/linux-ubuntu18.04-x86_64/gcc-7.4.0/autoconf-2.69/linux-ubuntu18.04-x86_64-gcc-7.4.0-autoconf-2.69-g23qfulbkb5qtgmpuwyv65o3p2r7w434.spack
  ########################################################################################################################################### 100.0%
  ==> Installing autoconf from binary cache
  gpg: Signature made Thu Oct 31 22:14:22 2019 UTC
  gpg:                using RSA key 7D344E2992071B0AAAE1EDB0E68DE2A80314303D
  gpg: Good signature from "prl" [unknown]
  gpg: WARNING: This key is not certified with a trusted signature!
  gpg:          There is no indication that the signature belongs to the owner.
  Primary key fingerprint: 7D34 4E29 9207 1B0A AAE1  EDB0 E68D E2A8 0314 303D
  ==> Relocating package from
    /spack/opt/spack to /home/spack/spack/opt/spack.
  ==> Successfully installed autoconf from binary cache
  [+] /home/spack/spack/opt/spack/linux-ubuntu18.04-x86_64/gcc-7.4.0/autoconf-2.69-g23qfulbkb5qtgmpuwyv65o3p2r7w434
  ==> Installing automake
  ==> Searching for binary cache of automake
  ==> Fetching file:///mirror/build_cache/linux-ubuntu18.04-x86_64/gcc-7.4.0/automake-1.16.1/linux-ubuntu18.04-x86_64-gcc-7.4.0-automake-1.16.1-io3tplo73zw2v5lkbknnvsk7tszjaj2d.spack
  ########################################################################################################################################### 100.0%
  ==> Installing automake from binary cache
  gpg: Signature made Thu Oct 31 21:58:39 2019 UTC
  gpg:                using RSA key 7D344E2992071B0AAAE1EDB0E68DE2A80314303D
  gpg: Good signature from "prl" [unknown]
  gpg: WARNING: This key is not certified with a trusted signature!
  gpg:          There is no indication that the signature belongs to the owner.
  Primary key fingerprint: 7D34 4E29 9207 1B0A AAE1  EDB0 E68D E2A8 0314 303D
  ==> Relocating package from
    /spack/opt/spack to /home/spack/spack/opt/spack.
  ==> Successfully installed automake from binary cache
  [+] /home/spack/spack/opt/spack/linux-ubuntu18.04-x86_64/gcc-7.4.0/automake-1.16.1-io3tplo73zw2v5lkbknnvsk7tszjaj2d
  ==> Installing numactl
  ==> Searching for binary cache of numactl
  ==> Fetching file:///mirror/build_cache/linux-ubuntu18.04-x86_64/gcc-7.4.0/numactl-2.0.12/linux-ubuntu18.04-x86_64-gcc-7.4.0-numactl-2.0.12-n6yyt2yxl3ydtze6fhlg6kjyuf33ezel.spack
  ########################################################################################################################################### 100.0%
  ==> Installing numactl from binary cache
  gpg: Signature made Thu Oct 31 22:15:38 2019 UTC
  gpg:                using RSA key 7D344E2992071B0AAAE1EDB0E68DE2A80314303D
  gpg: Good signature from "prl" [unknown]
  gpg: WARNING: This key is not certified with a trusted signature!
  gpg:          There is no indication that the signature belongs to the owner.
  Primary key fingerprint: 7D34 4E29 9207 1B0A AAE1  EDB0 E68D E2A8 0314 303D
  ==> Relocating package from
    /spack/opt/spack to /home/spack/spack/opt/spack.
  ==> Successfully installed numactl from binary cache
  [+] /home/spack/spack/opt/spack/linux-ubuntu18.04-x86_64/gcc-7.4.0/numactl-2.0.12-n6yyt2yxl3ydtze6fhlg6kjyuf33ezel
  ==> Installing hwloc
  ==> Searching for binary cache of hwloc
  ==> Fetching file:///mirror/build_cache/linux-ubuntu18.04-x86_64/gcc-7.4.0/hwloc-1.11.11/linux-ubuntu18.04-x86_64-gcc-7.4.0-hwloc-1.11.11-xcjsxcroxc5g6pwepcbq4ppuixpcdecv.spack
  ########################################################################################################################################### 100.0%
  ==> Installing hwloc from binary cache
  gpg: Signature made Thu Oct 31 21:42:40 2019 UTC
  gpg:                using RSA key 7D344E2992071B0AAAE1EDB0E68DE2A80314303D
  gpg: Good signature from "prl" [unknown]
  gpg: WARNING: This key is not certified with a trusted signature!
  gpg:          There is no indication that the signature belongs to the owner.
  Primary key fingerprint: 7D34 4E29 9207 1B0A AAE1  EDB0 E68D E2A8 0314 303D
  ==> Relocating package from
    /spack/opt/spack to /home/spack/spack/opt/spack.
  ==> Successfully installed hwloc from binary cache
  [+] /home/spack/spack/opt/spack/linux-ubuntu18.04-x86_64/gcc-7.4.0/hwloc-1.11.11-xcjsxcroxc5g6pwepcbq4ppuixpcdecv
  ==> Installing openmpi
  ==> Searching for binary cache of openmpi
  ==> Fetching file:///mirror/build_cache/linux-ubuntu18.04-x86_64/gcc-7.4.0/openmpi-3.1.4/linux-ubuntu18.04-x86_64-gcc-7.4.0-openmpi-3.1.4-f6maodnm53tkmchq5woe33nt5wbt2tel.spack
  ########################################################################################################################################### 100.0%
  ==> Installing openmpi from binary cache
  gpg: Signature made Thu Oct 31 22:07:47 2019 UTC
  gpg:                using RSA key 7D344E2992071B0AAAE1EDB0E68DE2A80314303D
  gpg: Good signature from "prl" [unknown]
  gpg: WARNING: This key is not certified with a trusted signature!
  gpg:          There is no indication that the signature belongs to the owner.
  Primary key fingerprint: 7D34 4E29 9207 1B0A AAE1  EDB0 E68D E2A8 0314 303D
  ==> Relocating package from
    /spack/opt/spack to /home/spack/spack/opt/spack.
  ==> Successfully installed openmpi from binary cache
  [+] /home/spack/spack/opt/spack/linux-ubuntu18.04-x86_64/gcc-7.4.0/openmpi-3.1.4-f6maodnm53tkmchq5woe33nt5wbt2tel
  ==> Installing hdf5
  ==> Searching for binary cache of hdf5
  ==> Fetching file:///mirror/build_cache/linux-ubuntu18.04-x86_64/gcc-7.4.0/hdf5-1.10.5/linux-ubuntu18.04-x86_64-gcc-7.4.0-hdf5-1.10.5-audmuesjjp62dbn2ldwt576f3yurx5cs.spack
  ########################################################################################################################################### 100.0%
  ==> Installing hdf5 from binary cache
  gpg: Signature made Thu Oct 31 21:45:12 2019 UTC
  gpg:                using RSA key 7D344E2992071B0AAAE1EDB0E68DE2A80314303D
  gpg: Good signature from "prl" [unknown]
  gpg: WARNING: This key is not certified with a trusted signature!
  gpg:          There is no indication that the signature belongs to the owner.
  Primary key fingerprint: 7D34 4E29 9207 1B0A AAE1  EDB0 E68D E2A8 0314 303D
  ==> Relocating package from
    /spack/opt/spack to /home/spack/spack/opt/spack.
  ==> Successfully installed hdf5 from binary cache
  [+] /home/spack/spack/opt/spack/linux-ubuntu18.04-x86_64/gcc-7.4.0/hdf5-1.10.5-audmuesjjp62dbn2ldwt576f3yurx5cs

Spack packages can also have build options, called variants. Boolean
variants can be specified using the ``+`` and ``~`` or ``-``
sigils. There are two sigils for ``False`` to avoid conflicts with
shell parsing in different situations. Variants (boolean or otherwise)
can also be specified using the same syntax as compiler flags.  Here
we can install HDF5 without MPI support.

.. code-block:: console

   $ spack install hdf5~mpi
   ==> zlib is already installed in /home/spack/spack/opt/spack/linux-ubuntu18.04-x86_64/gcc-7.4.0/zlib-1.2.11-o2viq7yriiaw6nwqpaa7ltpyzqkaonhb
   ==> Installing hdf5
   ==> Searching for binary cache of hdf5
   ==> Finding buildcaches in /mirror/build_cache
   ==> Fetching file:///mirror/build_cache/linux-ubuntu18.04-x86_64/gcc-7.4.0/hdf5-1.10.5/linux-ubuntu18.04-x86_64-gcc-7.4.0-hdf5-1.10.5-fuuwoa2jk65h7xlr4tmhvomswegcpkjo.spack
   ########################################################################################################################################### 100.0%
   ==> Installing hdf5 from binary cache
   gpg: Signature made Thu Oct 31 22:14:54 2019 UTC
   gpg:                using RSA key 7D344E2992071B0AAAE1EDB0E68DE2A80314303D
   gpg: Good signature from "prl" [unknown]
   gpg: WARNING: This key is not certified with a trusted signature!
   gpg:          There is no indication that the signature belongs to the owner.
   Primary key fingerprint: 7D34 4E29 9207 1B0A AAE1  EDB0 E68D E2A8 0314 303D
   ==> Relocating package from
     /spack/opt/spack to /home/spack/spack/opt/spack.
   ==> Successfully installed hdf5 from binary cache
   [+] /home/spack/spack/opt/spack/linux-ubuntu18.04-x86_64/gcc-7.4.0/hdf5-1.10.5-fuuwoa2jk65h7xlr4tmhvomswegcpkjo

We might also want to install HDF5 with a different MPI
implementation. While MPI is not a package itself, packages can depend on
abstract interfaces like MPI. Spack handles these through "virtual
dependencies." A package, such as HDF5, can depend on the MPI
interface. Other packages (``openmpi``, ``mpich``, ``mvapich``, etc.)
provide the MPI interface.  Any of these providers can be requested for
an MPI dependency. For example, we can build HDF5 with MPI support
provided by mpich by specifying a dependency on ``mpich``. Spack also
supports versioning of virtual dependencies. A package can depend on the
MPI interface at version 3, and provider packages specify what version of
the interface *they* provide. The partial spec ``^mpi@3`` can be safisfied
by any of several providers.

.. code-block:: console

  $ spack install hdf5+hl+mpi ^mpich
  ==> libsigsegv is already installed in /home/spack/spack/opt/spack/linux-ubuntu18.04-x86_64/gcc-7.4.0/libsigsegv-2.12-3khohgmwhbgvxehlt7rcnnzqfxelyv4p
  ==> m4 is already installed in /home/spack/spack/opt/spack/linux-ubuntu18.04-x86_64/gcc-7.4.0/m4-1.4.18-ut64la6rptcwos3uwl2kp5mle572hlhi
  ==> pkgconf is already installed in /home/spack/spack/opt/spack/linux-ubuntu18.04-x86_64/gcc-7.4.0/pkgconf-1.6.3-eifxmpsduqbsvgrk2sx5pn7cy5eraanr
  ==> ncurses is already installed in /home/spack/spack/opt/spack/linux-ubuntu18.04-x86_64/gcc-7.4.0/ncurses-6.1-s4rsiori6blknfxf2jx4nbfxfzvcww2k
  ==> readline is already installed in /home/spack/spack/opt/spack/linux-ubuntu18.04-x86_64/gcc-7.4.0/readline-8.0-hzwkvqampr3c6mfceyxq4xej7eyxoxoj
  ==> gdbm is already installed in /home/spack/spack/opt/spack/linux-ubuntu18.04-x86_64/gcc-7.4.0/gdbm-1.18.1-surdjxdcankv3xqk5tnnwroz3tor77o7
  ==> perl is already installed in /home/spack/spack/opt/spack/linux-ubuntu18.04-x86_64/gcc-7.4.0/perl-5.30.0-cxcj6eisjsfp3iv6xlio6rvc33fbxfmc
  ==> autoconf is already installed in /home/spack/spack/opt/spack/linux-ubuntu18.04-x86_64/gcc-7.4.0/autoconf-2.69-g23qfulbkb5qtgmpuwyv65o3p2r7w434
  ==> automake is already installed in /home/spack/spack/opt/spack/linux-ubuntu18.04-x86_64/gcc-7.4.0/automake-1.16.1-io3tplo73zw2v5lkbknnvsk7tszjaj2d
  ==> libtool is already installed in /home/spack/spack/opt/spack/linux-ubuntu18.04-x86_64/gcc-7.4.0/libtool-2.4.6-4neu5jwwmuo26mjs6363q6bupczjk6hk
  ==> Installing texinfo
  ==> Searching for binary cache of texinfo
  ==> Finding buildcaches in /mirror/build_cache
  ==> Fetching file:///mirror/build_cache/linux-ubuntu18.04-x86_64/gcc-7.4.0/texinfo-6.5/linux-ubuntu18.04-x86_64-gcc-7.4.0-texinfo-6.5-hyetop53cbzzvs4nydn447k6mxar7oom.spack
  ########################################################################################################################################### 100.0%
  ==> Installing texinfo from binary cache
  gpg: Signature made Thu Oct 31 21:58:37 2019 UTC
  gpg:                using RSA key 7D344E2992071B0AAAE1EDB0E68DE2A80314303D
  gpg: Good signature from "prl" [unknown]
  gpg: WARNING: This key is not certified with a trusted signature!
  gpg:          There is no indication that the signature belongs to the owner.
  Primary key fingerprint: 7D34 4E29 9207 1B0A AAE1  EDB0 E68D E2A8 0314 303D
  ==> Relocating package from
    /spack/opt/spack to /home/spack/spack/opt/spack.
  ==> Successfully installed texinfo from binary cache
  [+] /home/spack/spack/opt/spack/linux-ubuntu18.04-x86_64/gcc-7.4.0/texinfo-6.5-hyetop53cbzzvs4nydn447k6mxar7oom
  ==> Installing findutils
  ==> Searching for binary cache of findutils
  ==> Fetching file:///mirror/build_cache/linux-ubuntu18.04-x86_64/gcc-7.4.0/findutils-4.6.0/linux-ubuntu18.04-x86_64-gcc-7.4.0-findutils-4.6.0-uf3gw7kk3bfknzvmmqax733o6i63qtrz.spack
  ########################################################################################################################################### 100.0%
  ==> Installing findutils from binary cache
  gpg: Signature made Thu Oct 31 22:14:25 2019 UTC
  gpg:                using RSA key 7D344E2992071B0AAAE1EDB0E68DE2A80314303D
  gpg: Good signature from "prl" [unknown]
  gpg: WARNING: This key is not certified with a trusted signature!
  gpg:          There is no indication that the signature belongs to the owner.
  Primary key fingerprint: 7D34 4E29 9207 1B0A AAE1  EDB0 E68D E2A8 0314 303D
  ==> Relocating package from
    /spack/opt/spack to /home/spack/spack/opt/spack.
  ==> Successfully installed findutils from binary cache
  [+] /home/spack/spack/opt/spack/linux-ubuntu18.04-x86_64/gcc-7.4.0/findutils-4.6.0-uf3gw7kk3bfknzvmmqax733o6i63qtrz
  ==> util-macros is already installed in /home/spack/spack/opt/spack/linux-ubuntu18.04-x86_64/gcc-7.4.0/util-macros-1.19.1-a226ran4thxadofd7yow3sfng3gy3t3k
  ==> libpciaccess is already installed in /home/spack/spack/opt/spack/linux-ubuntu18.04-x86_64/gcc-7.4.0/libpciaccess-0.13.5-vhehc322oo5ipbbk465m6py6zzr4kdam
  ==> libiconv is already installed in /home/spack/spack/opt/spack/linux-ubuntu18.04-x86_64/gcc-7.4.0/libiconv-1.16-zvmmgjbnfrzbo3hl2ijqxcjpkiv7q3ab
  ==> xz is already installed in /home/spack/spack/opt/spack/linux-ubuntu18.04-x86_64/gcc-7.4.0/xz-5.2.4-ur2jffeua3gzg5otnmqgfnfdexgtjxcl
  ==> zlib is already installed in /home/spack/spack/opt/spack/linux-ubuntu18.04-x86_64/gcc-7.4.0/zlib-1.2.11-o2viq7yriiaw6nwqpaa7ltpyzqkaonhb
  ==> libxml2 is already installed in /home/spack/spack/opt/spack/linux-ubuntu18.04-x86_64/gcc-7.4.0/libxml2-2.9.9-fg5evg4bxx4jy3paclojb46lok4fjclf
  ==> Installing mpich
  ==> Searching for binary cache of mpich
  ==> Fetching file:///mirror/build_cache/linux-ubuntu18.04-x86_64/gcc-7.4.0/mpich-3.3.1/linux-ubuntu18.04-x86_64-gcc-7.4.0-mpich-3.3.1-6e3rvexzhuij3csp7u2onkjtizsfowz2.spack
  ########################################################################################################################################### 100.0%
  ==> Installing mpich from binary cache
  gpg: Signature made Thu Oct 31 22:00:43 2019 UTC
  gpg:                using RSA key 7D344E2992071B0AAAE1EDB0E68DE2A80314303D
  gpg: Good signature from "prl" [unknown]
  gpg: WARNING: This key is not certified with a trusted signature!
  gpg:          There is no indication that the signature belongs to the owner.
  Primary key fingerprint: 7D34 4E29 9207 1B0A AAE1  EDB0 E68D E2A8 0314 303D
  ==> Relocating package from
    /spack/opt/spack to /home/spack/spack/opt/spack.
  ==> Successfully installed mpich from binary cache
  [+] /home/spack/spack/opt/spack/linux-ubuntu18.04-x86_64/gcc-7.4.0/mpich-3.3.1-6e3rvexzhuij3csp7u2onkjtizsfowz2
  ==> Installing hdf5
  ==> Searching for binary cache of hdf5
  ==> Fetching file:///mirror/build_cache/linux-ubuntu18.04-x86_64/gcc-7.4.0/hdf5-1.10.5/linux-ubuntu18.04-x86_64-gcc-7.4.0-hdf5-1.10.5-c24mwwta5dws3itb6vetov3ctoza4g6v.spack
  ########################################################################################################################################### 100.0%
  ==> Installing hdf5 from binary cache
  gpg: Signature made Thu Oct 31 22:19:58 2019 UTC
  gpg:                using RSA key 7D344E2992071B0AAAE1EDB0E68DE2A80314303D
  gpg: Good signature from "prl" [unknown]
  gpg: WARNING: This key is not certified with a trusted signature!
  gpg:          There is no indication that the signature belongs to the owner.
  Primary key fingerprint: 7D34 4E29 9207 1B0A AAE1  EDB0 E68D E2A8 0314 303D
  ==> Relocating package from
    /spack/opt/spack to /home/spack/spack/opt/spack.
  ==> Successfully installed hdf5 from binary cache
  [+] /home/spack/spack/opt/spack/linux-ubuntu18.04-x86_64/gcc-7.4.0/hdf5-1.10.5-c24mwwta5dws3itb6vetov3ctoza4g6v

We'll do a quick check in on what we have installed so far.

.. code-block:: console

  $ spack find -ldf
  ==> 33 installed packages
  -- linux-ubuntu18.04-x86_64 / clang@6.0.0 -----------------------
  4ef57sw tcl@8.6.8%clang
  pdfmc5x     zlib@1.2.8%clang

  pdfmc5x zlib@1.2.8%clang

  5qffmms zlib@1.2.11%clang


  -- linux-ubuntu18.04-x86_64 / gcc@6.5.0 -------------------------
  qtrzwov zlib@1.2.11%gcc


  -- linux-ubuntu18.04-x86_64 / gcc@7.4.0 -------------------------
  g23qful autoconf@2.69%gcc
  ut64la6     m4@1.4.18%gcc
  3khohgm         libsigsegv@2.12%gcc
  cxcj6ei     perl@5.30.0%gcc
  surdjxd         gdbm@1.18.1%gcc
  hzwkvqa             readline@8.0%gcc
  s4rsior                 ncurses@6.1%gcc

  io3tplo automake@1.16.1%gcc
  cxcj6ei     perl@5.30.0%gcc
  surdjxd         gdbm@1.18.1%gcc
  hzwkvqa             readline@8.0%gcc
  s4rsior                 ncurses@6.1%gcc

  uf3gw7k findutils@4.6.0%gcc

  surdjxd gdbm@1.18.1%gcc
  hzwkvqa     readline@8.0%gcc
  s4rsior         ncurses@6.1%gcc

  fuuwoa2 hdf5@1.10.5%gcc
  o2viq7y     zlib@1.2.11%gcc

  audmues hdf5@1.10.5%gcc
  f6maodn     openmpi@3.1.4%gcc
  xcjsxcr         hwloc@1.11.11%gcc
  vhehc32             libpciaccess@0.13.5%gcc
  fg5evg4             libxml2@2.9.9%gcc
  zvmmgjb                 libiconv@1.16%gcc
  ur2jffe                 xz@5.2.4%gcc
  o2viq7y                 zlib@1.2.11%gcc
  n6yyt2y             numactl@2.0.12%gcc

  c24mwwt hdf5@1.10.5%gcc
  6e3rvex     mpich@3.3.1%gcc
  vhehc32         libpciaccess@0.13.5%gcc
  fg5evg4         libxml2@2.9.9%gcc
  zvmmgjb             libiconv@1.16%gcc
  ur2jffe             xz@5.2.4%gcc
  o2viq7y             zlib@1.2.11%gcc

  xcjsxcr hwloc@1.11.11%gcc
  vhehc32     libpciaccess@0.13.5%gcc
  fg5evg4     libxml2@2.9.9%gcc
  zvmmgjb         libiconv@1.16%gcc
  ur2jffe         xz@5.2.4%gcc
  o2viq7y         zlib@1.2.11%gcc
  n6yyt2y     numactl@2.0.12%gcc

  zvmmgjb libiconv@1.16%gcc

  vhehc32 libpciaccess@0.13.5%gcc

  3khohgm libsigsegv@2.12%gcc

  4neu5jw libtool@2.4.6%gcc

  fg5evg4 libxml2@2.9.9%gcc
  zvmmgjb     libiconv@1.16%gcc
  ur2jffe     xz@5.2.4%gcc
  o2viq7y     zlib@1.2.11%gcc

  ut64la6 m4@1.4.18%gcc
  3khohgm     libsigsegv@2.12%gcc

  6e3rvex mpich@3.3.1%gcc
  vhehc32     libpciaccess@0.13.5%gcc
  fg5evg4     libxml2@2.9.9%gcc
  zvmmgjb         libiconv@1.16%gcc
  ur2jffe         xz@5.2.4%gcc
  o2viq7y         zlib@1.2.11%gcc

  s4rsior ncurses@6.1%gcc

  n6yyt2y numactl@2.0.12%gcc

  f6maodn openmpi@3.1.4%gcc
  xcjsxcr     hwloc@1.11.11%gcc
  vhehc32         libpciaccess@0.13.5%gcc
  fg5evg4         libxml2@2.9.9%gcc
  zvmmgjb             libiconv@1.16%gcc
  ur2jffe             xz@5.2.4%gcc
  o2viq7y             zlib@1.2.11%gcc
  n6yyt2y         numactl@2.0.12%gcc

  cxcj6ei perl@5.30.0%gcc
  surdjxd     gdbm@1.18.1%gcc
  hzwkvqa         readline@8.0%gcc
  s4rsior             ncurses@6.1%gcc

  eifxmps pkgconf@1.6.3%gcc

  hzwkvqa readline@8.0%gcc
  s4rsior     ncurses@6.1%gcc

  nstkcal tcl@8.6.8%gcc
  hmvjty5     zlib@1.2.8%gcc  cppflags="-O3"

  t3gp773 tcl@8.6.8%gcc
  o2viq7y     zlib@1.2.11%gcc

  hyetop5 texinfo@6.5%gcc
  cxcj6ei     perl@5.30.0%gcc
  surdjxd         gdbm@1.18.1%gcc
  hzwkvqa             readline@8.0%gcc
  s4rsior                 ncurses@6.1%gcc

  a226ran util-macros@1.19.1%gcc

  ur2jffe xz@5.2.4%gcc

  d6ety7c zlib@1.2.8%gcc

  hmvjty5 zlib@1.2.8%gcc  cppflags="-O3"

  o2viq7y zlib@1.2.11%gcc


Spack models the dependencies of packages as a directed acyclic graph
(DAG). The ``spack find -d`` command shows the tree representation of
that graph.  We can also use the ``spack graph`` command to view the entire
DAG as a graph.

.. code-block:: console

  $ spack graph hdf5+hl+mpi ^mpich
  o  hdf5
  |\
  | o  mpich
  | |\
  | | |\
  | | | |\
  | | o | |  libxml2
  | |/| | |
  |/|/| | |
  | | |\ \ \
  o | | | | |  zlib
   / / / / /
  | o | | |  xz
  |  / / /
  | | o |  libpciaccess
  | |/| |
  |/| | |
  | | |\ \
  | | o | |  util-macros
  | |  / /
  | | | o  findutils
  | | |/|
  | | | |\
  | | | | |\
  | | | | | |\
  | | | o | | |  texinfo
  | | | | | o |  automake
  | | | | |/| |
  | | | |/| | |
  | | | | | |/
  | | | | | o  autoconf
  | | | | |/|
  | | | |/|/
  | | | o |  perl
  | | | o |  gdbm
  | | | o |  readline
  | | | o |  ncurses
  | |_|/ /
  |/| | |
  o | | |  pkgconf
   / / /
  | o |  libtool
  | |/
  | o  m4
  | o  libsigsegv
  |
  o  libiconv

You may also have noticed that there are some packages shown in the
``spack find -d`` output that we didn't install explicitly. These are
dependencies that were installed implicitly. A few packages installed
implicitly are not shown as dependencies in the ``spack find -d``
output. These are build dependencies. For example, ``libpciaccess`` is a
dependency of openmpi and requires ``m4`` to build. Spack will build ``m4`` as
part of the installation of ``openmpi``, but it does not become a part of
the DAG because it is not linked in at run time. Spack handles build
dependencies differently because of their different (less strict)
consistency requirements. It is entirely possible to have two packages
using different versions of a dependency to build, which obviously cannot
be done with linked dependencies.

``HDF5`` is more complicated than our basic example of zlib and
openssl, but it's still within the realm of software that an experienced
HPC user could reasonably expect to install given a bit of time. Now
let's look at an even more complicated package.

.. code-block:: console

  $ spack install trilinos
  ==> libiconv is already installed in /home/spack/spack/opt/spack/linux-ubuntu18.04-x86_64/gcc-7.4.0/libiconv-1.16-zvmmgjbnfrzbo3hl2ijqxcjpkiv7q3ab
  ==> Installing diffutils
  ==> Searching for binary cache of diffutils
  ==> Finding buildcaches in /mirror/build_cache
  ==> Fetching file:///mirror/build_cache/linux-ubuntu18.04-x86_64/gcc-7.4.0/diffutils-3.7/linux-ubuntu18.04-x86_64-gcc-7.4.0-diffutils-3.7-vku7yph7wtd5y372dk3p7thg5lttsy2n.spack
  ########################################################################################################################################### 100.0%
  ==> Installing diffutils from binary cache
  gpg: Signature made Thu Oct 31 22:16:58 2019 UTC
  gpg:                using RSA key 7D344E2992071B0AAAE1EDB0E68DE2A80314303D
  gpg: Good signature from "prl" [unknown]
  gpg: WARNING: This key is not certified with a trusted signature!
  gpg:          There is no indication that the signature belongs to the owner.
  Primary key fingerprint: 7D34 4E29 9207 1B0A AAE1  EDB0 E68D E2A8 0314 303D
  ==> Relocating package from
    /spack/opt/spack to /home/spack/spack/opt/spack.
  ==> Successfully installed diffutils from binary cache
  [+] /home/spack/spack/opt/spack/linux-ubuntu18.04-x86_64/gcc-7.4.0/diffutils-3.7-vku7yph7wtd5y372dk3p7thg5lttsy2n
  ==> Installing bzip2
  ==> Searching for binary cache of bzip2
  ==> Fetching file:///mirror/build_cache/linux-ubuntu18.04-x86_64/gcc-7.4.0/bzip2-1.0.8/linux-ubuntu18.04-x86_64-gcc-7.4.0-bzip2-1.0.8-g2ghsbb6kih2itnkcqc2v6iraimj23r4.spack
  ########################################################################################################################################### 100.0%
  ==> Installing bzip2 from binary cache
  gpg: Signature made Thu Oct 31 21:46:27 2019 UTC
  gpg:                using RSA key 7D344E2992071B0AAAE1EDB0E68DE2A80314303D
  gpg: Good signature from "prl" [unknown]
  gpg: WARNING: This key is not certified with a trusted signature!
  gpg:          There is no indication that the signature belongs to the owner.
  Primary key fingerprint: 7D34 4E29 9207 1B0A AAE1  EDB0 E68D E2A8 0314 303D
  ==> Relocating package from
    /spack/opt/spack to /home/spack/spack/opt/spack.
  ==> Successfully installed bzip2 from binary cache
  [+] /home/spack/spack/opt/spack/linux-ubuntu18.04-x86_64/gcc-7.4.0/bzip2-1.0.8-g2ghsbb6kih2itnkcqc2v6iraimj23r4
  ==> zlib is already installed in /home/spack/spack/opt/spack/linux-ubuntu18.04-x86_64/gcc-7.4.0/zlib-1.2.11-o2viq7yriiaw6nwqpaa7ltpyzqkaonhb
  ==> Installing boost
  ==> Searching for binary cache of boost
  ==> Fetching file:///mirror/build_cache/linux-ubuntu18.04-x86_64/gcc-7.4.0/boost-1.70.0/linux-ubuntu18.04-x86_64-gcc-7.4.0-boost-1.70.0-d42gtzk7f4chkyjqyqbg5c7tkd3r375y.spack
  ########################################################################################################################################### 100.0%
  ==> Installing boost from binary cache
  gpg: Signature made Thu Oct 31 22:19:25 2019 UTC
  gpg:                using RSA key 7D344E2992071B0AAAE1EDB0E68DE2A80314303D
  gpg: Good signature from "prl" [unknown]
  gpg: WARNING: This key is not certified with a trusted signature!
  gpg:          There is no indication that the signature belongs to the owner.
  Primary key fingerprint: 7D34 4E29 9207 1B0A AAE1  EDB0 E68D E2A8 0314 303D
  ==> Relocating package from
    /spack/opt/spack to /home/spack/spack/opt/spack.
  ==> Successfully installed boost from binary cache
  [+] /home/spack/spack/opt/spack/linux-ubuntu18.04-x86_64/gcc-7.4.0/boost-1.70.0-d42gtzk7f4chkyjqyqbg5c7tkd3r375y
  ==> pkgconf is already installed in /home/spack/spack/opt/spack/linux-ubuntu18.04-x86_64/gcc-7.4.0/pkgconf-1.6.3-eifxmpsduqbsvgrk2sx5pn7cy5eraanr
  ==> ncurses is already installed in /home/spack/spack/opt/spack/linux-ubuntu18.04-x86_64/gcc-7.4.0/ncurses-6.1-s4rsiori6blknfxf2jx4nbfxfzvcww2k
  ==> readline is already installed in /home/spack/spack/opt/spack/linux-ubuntu18.04-x86_64/gcc-7.4.0/readline-8.0-hzwkvqampr3c6mfceyxq4xej7eyxoxoj
  ==> gdbm is already installed in /home/spack/spack/opt/spack/linux-ubuntu18.04-x86_64/gcc-7.4.0/gdbm-1.18.1-surdjxdcankv3xqk5tnnwroz3tor77o7
  ==> perl is already installed in /home/spack/spack/opt/spack/linux-ubuntu18.04-x86_64/gcc-7.4.0/perl-5.30.0-cxcj6eisjsfp3iv6xlio6rvc33fbxfmc
  ==> Installing openssl
  ==> Searching for binary cache of openssl
  ==> Fetching file:///mirror/build_cache/linux-ubuntu18.04-x86_64/gcc-7.4.0/openssl-1.1.1d/linux-ubuntu18.04-x86_64-gcc-7.4.0-openssl-1.1.1d-jujqjv5qejwtzau7zmbcqft7ercsa5o5.spack
  ########################################################################################################################################### 100.0%
  ==> Installing openssl from binary cache
  gpg: Signature made Thu Oct 31 21:56:37 2019 UTC
  gpg:                using RSA key 7D344E2992071B0AAAE1EDB0E68DE2A80314303D
  gpg: Good signature from "prl" [unknown]
  gpg: WARNING: This key is not certified with a trusted signature!
  gpg:          There is no indication that the signature belongs to the owner.
  Primary key fingerprint: 7D34 4E29 9207 1B0A AAE1  EDB0 E68D E2A8 0314 303D
  ==> Relocating package from
    /spack/opt/spack to /home/spack/spack/opt/spack.
  ==> Successfully installed openssl from binary cache
  [+] /home/spack/spack/opt/spack/linux-ubuntu18.04-x86_64/gcc-7.4.0/openssl-1.1.1d-jujqjv5qejwtzau7zmbcqft7ercsa5o5
  ==> Installing cmake
  ==> Searching for binary cache of cmake
  ==> Fetching file:///mirror/build_cache/linux-ubuntu18.04-x86_64/gcc-7.4.0/cmake-3.15.4/linux-ubuntu18.04-x86_64-gcc-7.4.0-cmake-3.15.4-3wkiwji3xtohdmgay4ti2m6sqkpmakv3.spack
  ########################################################################################################################################### 100.0%
  ==> Installing cmake from binary cache
  gpg: Signature made Thu Oct 31 22:07:29 2019 UTC
  gpg:                using RSA key 7D344E2992071B0AAAE1EDB0E68DE2A80314303D
  gpg: Good signature from "prl" [unknown]
  gpg: WARNING: This key is not certified with a trusted signature!
  gpg:          There is no indication that the signature belongs to the owner.
  Primary key fingerprint: 7D34 4E29 9207 1B0A AAE1  EDB0 E68D E2A8 0314 303D
  ==> Relocating package from
    /spack/opt/spack to /home/spack/spack/opt/spack.
  ==> Successfully installed cmake from binary cache
  [+] /home/spack/spack/opt/spack/linux-ubuntu18.04-x86_64/gcc-7.4.0/cmake-3.15.4-3wkiwji3xtohdmgay4ti2m6sqkpmakv3
  ==> Installing glm
  ==> Searching for binary cache of glm
  ==> Fetching file:///mirror/build_cache/linux-ubuntu18.04-x86_64/gcc-7.4.0/glm-0.9.7.1/linux-ubuntu18.04-x86_64-gcc-7.4.0-glm-0.9.7.1-4zyyrqsditrvrxdgjlnouqosjzzcdjql.spack
  ########################################################################################################################################### 100.0%
  ==> Installing glm from binary cache
  gpg: Signature made Thu Oct 31 22:20:00 2019 UTC
  gpg:                using RSA key 7D344E2992071B0AAAE1EDB0E68DE2A80314303D
  gpg: Good signature from "prl" [unknown]
  gpg: WARNING: This key is not certified with a trusted signature!
  gpg:          There is no indication that the signature belongs to the owner.
  Primary key fingerprint: 7D34 4E29 9207 1B0A AAE1  EDB0 E68D E2A8 0314 303D
  ==> Relocating package from
    /spack/opt/spack to /home/spack/spack/opt/spack.
  ==> Successfully installed glm from binary cache
  [+] /home/spack/spack/opt/spack/linux-ubuntu18.04-x86_64/gcc-7.4.0/glm-0.9.7.1-4zyyrqsditrvrxdgjlnouqosjzzcdjql
  ==> libsigsegv is already installed in /home/spack/spack/opt/spack/linux-ubuntu18.04-x86_64/gcc-7.4.0/libsigsegv-2.12-3khohgmwhbgvxehlt7rcnnzqfxelyv4p
  ==> m4 is already installed in /home/spack/spack/opt/spack/linux-ubuntu18.04-x86_64/gcc-7.4.0/m4-1.4.18-ut64la6rptcwos3uwl2kp5mle572hlhi
  ==> libtool is already installed in /home/spack/spack/opt/spack/linux-ubuntu18.04-x86_64/gcc-7.4.0/libtool-2.4.6-4neu5jwwmuo26mjs6363q6bupczjk6hk
  ==> util-macros is already installed in /home/spack/spack/opt/spack/linux-ubuntu18.04-x86_64/gcc-7.4.0/util-macros-1.19.1-a226ran4thxadofd7yow3sfng3gy3t3k
  ==> libpciaccess is already installed in /home/spack/spack/opt/spack/linux-ubuntu18.04-x86_64/gcc-7.4.0/libpciaccess-0.13.5-vhehc322oo5ipbbk465m6py6zzr4kdam
  ==> xz is already installed in /home/spack/spack/opt/spack/linux-ubuntu18.04-x86_64/gcc-7.4.0/xz-5.2.4-ur2jffeua3gzg5otnmqgfnfdexgtjxcl
  ==> libxml2 is already installed in /home/spack/spack/opt/spack/linux-ubuntu18.04-x86_64/gcc-7.4.0/libxml2-2.9.9-fg5evg4bxx4jy3paclojb46lok4fjclf
  ==> autoconf is already installed in /home/spack/spack/opt/spack/linux-ubuntu18.04-x86_64/gcc-7.4.0/autoconf-2.69-g23qfulbkb5qtgmpuwyv65o3p2r7w434
  ==> automake is already installed in /home/spack/spack/opt/spack/linux-ubuntu18.04-x86_64/gcc-7.4.0/automake-1.16.1-io3tplo73zw2v5lkbknnvsk7tszjaj2d
  ==> numactl is already installed in /home/spack/spack/opt/spack/linux-ubuntu18.04-x86_64/gcc-7.4.0/numactl-2.0.12-n6yyt2yxl3ydtze6fhlg6kjyuf33ezel
  ==> hwloc is already installed in /home/spack/spack/opt/spack/linux-ubuntu18.04-x86_64/gcc-7.4.0/hwloc-1.11.11-xcjsxcroxc5g6pwepcbq4ppuixpcdecv
  ==> openmpi is already installed in /home/spack/spack/opt/spack/linux-ubuntu18.04-x86_64/gcc-7.4.0/openmpi-3.1.4-f6maodnm53tkmchq5woe33nt5wbt2tel
  ==> Installing hdf5
  ==> Searching for binary cache of hdf5
  ==> Fetching file:///mirror/build_cache/linux-ubuntu18.04-x86_64/gcc-7.4.0/hdf5-1.10.5/linux-ubuntu18.04-x86_64-gcc-7.4.0-hdf5-1.10.5-65cucf4mb2vyni6xto4me4sei6kwvjqv.spack
  ########################################################################################################################################### 100.0%
  ==> Installing hdf5 from binary cache
  gpg: Signature made Thu Oct 31 21:42:34 2019 UTC
  gpg:                using RSA key 7D344E2992071B0AAAE1EDB0E68DE2A80314303D
  gpg: Good signature from "prl" [unknown]
  gpg: WARNING: This key is not certified with a trusted signature!
  gpg:          There is no indication that the signature belongs to the owner.
  Primary key fingerprint: 7D34 4E29 9207 1B0A AAE1  EDB0 E68D E2A8 0314 303D
  ==> Relocating package from
    /spack/opt/spack to /home/spack/spack/opt/spack.
  ==> Successfully installed hdf5 from binary cache
  [+] /home/spack/spack/opt/spack/linux-ubuntu18.04-x86_64/gcc-7.4.0/hdf5-1.10.5-65cucf4mb2vyni6xto4me4sei6kwvjqv
  ==> Installing openblas
  ==> Searching for binary cache of openblas
  ==> Fetching file:///mirror/build_cache/linux-ubuntu18.04-x86_64/gcc-7.4.0/openblas-0.3.7/linux-ubuntu18.04-x86_64-gcc-7.4.0-openblas-0.3.7-jepvsjbuh6mlpkxvsxyhh2r22cqeow7z.spack
  ########################################################################################################################################### 100.0%
  ==> Installing openblas from binary cache
  gpg: Signature made Thu Oct 31 22:14:13 2019 UTC
  gpg:                using RSA key 7D344E2992071B0AAAE1EDB0E68DE2A80314303D
  gpg: Good signature from "prl" [unknown]
  gpg: WARNING: This key is not certified with a trusted signature!
  gpg:          There is no indication that the signature belongs to the owner.
  Primary key fingerprint: 7D34 4E29 9207 1B0A AAE1  EDB0 E68D E2A8 0314 303D
  ==> Relocating package from
    /spack/opt/spack to /home/spack/spack/opt/spack.
  ==> Successfully installed openblas from binary cache
  [+] /home/spack/spack/opt/spack/linux-ubuntu18.04-x86_64/gcc-7.4.0/openblas-0.3.7-jepvsjbuh6mlpkxvsxyhh2r22cqeow7z
  ==> Installing hypre
  ==> Searching for binary cache of hypre
  ==> Fetching file:///mirror/build_cache/linux-ubuntu18.04-x86_64/gcc-7.4.0/hypre-2.18.1/linux-ubuntu18.04-x86_64-gcc-7.4.0-hypre-2.18.1-gsuceumk6kvcf4plbfrtevorbfeymy6r.spack
  ########################################################################################################################################### 100.0%
  ==> Installing hypre from binary cache
  gpg: Signature made Thu Oct 31 21:54:06 2019 UTC
  gpg:                using RSA key 7D344E2992071B0AAAE1EDB0E68DE2A80314303D
  gpg: Good signature from "prl" [unknown]
  gpg: WARNING: This key is not certified with a trusted signature!
  gpg:          There is no indication that the signature belongs to the owner.
  Primary key fingerprint: 7D34 4E29 9207 1B0A AAE1  EDB0 E68D E2A8 0314 303D
  ==> Relocating package from
    /spack/opt/spack to /home/spack/spack/opt/spack.
  ==> Successfully installed hypre from binary cache
  [+] /home/spack/spack/opt/spack/linux-ubuntu18.04-x86_64/gcc-7.4.0/hypre-2.18.1-gsuceumk6kvcf4plbfrtevorbfeymy6r
  ==> Installing matio
  ==> Searching for binary cache of matio
  ==> Fetching file:///mirror/build_cache/linux-ubuntu18.04-x86_64/gcc-7.4.0/matio-1.5.13/linux-ubuntu18.04-x86_64-gcc-7.4.0-matio-1.5.13-7643xwiplub3c6ccq6m2ko2k2v75cows.spack
  ########################################################################################################################################### 100.0%
  ==> Installing matio from binary cache
  gpg: Signature made Thu Oct 31 21:55:37 2019 UTC
  gpg:                using RSA key 7D344E2992071B0AAAE1EDB0E68DE2A80314303D
  gpg: Good signature from "prl" [unknown]
  gpg: WARNING: This key is not certified with a trusted signature!
  gpg:          There is no indication that the signature belongs to the owner.
  Primary key fingerprint: 7D34 4E29 9207 1B0A AAE1  EDB0 E68D E2A8 0314 303D
  ==> Relocating package from
    /spack/opt/spack to /home/spack/spack/opt/spack.
  ==> Successfully installed matio from binary cache
  [+] /home/spack/spack/opt/spack/linux-ubuntu18.04-x86_64/gcc-7.4.0/matio-1.5.13-7643xwiplub3c6ccq6m2ko2k2v75cows
  ==> Installing metis
  ==> Searching for binary cache of metis
  ==> Fetching file:///mirror/build_cache/linux-ubuntu18.04-x86_64/gcc-7.4.0/metis-5.1.0/linux-ubuntu18.04-x86_64-gcc-7.4.0-metis-5.1.0-q6wvktue4oy654iuyspzahnj7xbgjjry.spack
  ########################################################################################################################################### 100.0%
  ==> Installing metis from binary cache
  gpg: Signature made Thu Oct 31 22:00:23 2019 UTC
  gpg:                using RSA key 7D344E2992071B0AAAE1EDB0E68DE2A80314303D
  gpg: Good signature from "prl" [unknown]
  gpg: WARNING: This key is not certified with a trusted signature!
  gpg:          There is no indication that the signature belongs to the owner.
  Primary key fingerprint: 7D34 4E29 9207 1B0A AAE1  EDB0 E68D E2A8 0314 303D
  ==> Relocating package from
    /spack/opt/spack to /home/spack/spack/opt/spack.
  ==> Successfully installed metis from binary cache
  [+] /home/spack/spack/opt/spack/linux-ubuntu18.04-x86_64/gcc-7.4.0/metis-5.1.0-q6wvktue4oy654iuyspzahnj7xbgjjry
  ==> Installing netlib-scalapack
  ==> Searching for binary cache of netlib-scalapack
  ==> Fetching file:///mirror/build_cache/linux-ubuntu18.04-x86_64/gcc-7.4.0/netlib-scalapack-2.0.2/linux-ubuntu18.04-x86_64-gcc-7.4.0-netlib-scalapack-2.0.2-gfcwr4d6w6qdvenaqthatm4yacqweuuy.spack
  ########################################################################################################################################### 100.0%
  ==> Installing netlib-scalapack from binary cache
  gpg: Signature made Thu Oct 31 22:00:52 2019 UTC
  gpg:                using RSA key 7D344E2992071B0AAAE1EDB0E68DE2A80314303D
  gpg: Good signature from "prl" [unknown]
  gpg: WARNING: This key is not certified with a trusted signature!
  gpg:          There is no indication that the signature belongs to the owner.
  Primary key fingerprint: 7D34 4E29 9207 1B0A AAE1  EDB0 E68D E2A8 0314 303D
  ==> Relocating package from
    /spack/opt/spack to /home/spack/spack/opt/spack.
  ==> Successfully installed netlib-scalapack from binary cache
  [+] /home/spack/spack/opt/spack/linux-ubuntu18.04-x86_64/gcc-7.4.0/netlib-scalapack-2.0.2-gfcwr4d6w6qdvenaqthatm4yacqweuuy
  ==> Installing mumps
  ==> Searching for binary cache of mumps
  ==> Fetching file:///mirror/build_cache/linux-ubuntu18.04-x86_64/gcc-7.4.0/mumps-5.2.0/linux-ubuntu18.04-x86_64-gcc-7.4.0-mumps-5.2.0-s2ezmwe6of5i6fws2qxirze6cfbfihrz.spack
  ########################################################################################################################################### 100.0%
  ==> Installing mumps from binary cache
  gpg: Signature made Thu Oct 31 21:58:15 2019 UTC
  gpg:                using RSA key 7D344E2992071B0AAAE1EDB0E68DE2A80314303D
  gpg: Good signature from "prl" [unknown]
  gpg: WARNING: This key is not certified with a trusted signature!
  gpg:          There is no indication that the signature belongs to the owner.
  Primary key fingerprint: 7D34 4E29 9207 1B0A AAE1  EDB0 E68D E2A8 0314 303D
  ==> Relocating package from
    /spack/opt/spack to /home/spack/spack/opt/spack.
  ==> Successfully installed mumps from binary cache
  [+] /home/spack/spack/opt/spack/linux-ubuntu18.04-x86_64/gcc-7.4.0/mumps-5.2.0-s2ezmwe6of5i6fws2qxirze6cfbfihrz
  ==> Installing netcdf
  ==> Searching for binary cache of netcdf
  ==> Fetching file:///mirror/build_cache/linux-ubuntu18.04-x86_64/gcc-7.4.0/netcdf-4.7.1/linux-ubuntu18.04-x86_64-gcc-7.4.0-netcdf-4.7.1-t6uuk2xxvkytfu2j2bxdn7xwucqgebyo.spack
  ########################################################################################################################################### 100.0%
  ==> Installing netcdf from binary cache
  gpg: Signature made Thu Oct 31 22:21:51 2019 UTC
  gpg:                using RSA key 7D344E2992071B0AAAE1EDB0E68DE2A80314303D
  gpg: Good signature from "prl" [unknown]
  gpg: WARNING: This key is not certified with a trusted signature!
  gpg:          There is no indication that the signature belongs to the owner.
  Primary key fingerprint: 7D34 4E29 9207 1B0A AAE1  EDB0 E68D E2A8 0314 303D
  ==> Relocating package from
    /spack/opt/spack to /home/spack/spack/opt/spack.
  ==> Successfully installed netcdf from binary cache
  [+] /home/spack/spack/opt/spack/linux-ubuntu18.04-x86_64/gcc-7.4.0/netcdf-4.7.1-t6uuk2xxvkytfu2j2bxdn7xwucqgebyo
  ==> Installing parmetis
  ==> Searching for binary cache of parmetis
  ==> Fetching file:///mirror/build_cache/linux-ubuntu18.04-x86_64/gcc-7.4.0/parmetis-4.0.3/linux-ubuntu18.04-x86_64-gcc-7.4.0-parmetis-4.0.3-khzaszhki3ghfcwedrs7eay7ycphnv6x.spack
  ########################################################################################################################################### 100.0%
  ==> Installing parmetis from binary cache
  gpg: Signature made Thu Oct 31 21:51:09 2019 UTC
  gpg:                using RSA key 7D344E2992071B0AAAE1EDB0E68DE2A80314303D
  gpg: Good signature from "prl" [unknown]
  gpg: WARNING: This key is not certified with a trusted signature!
  gpg:          There is no indication that the signature belongs to the owner.
  Primary key fingerprint: 7D34 4E29 9207 1B0A AAE1  EDB0 E68D E2A8 0314 303D
  ==> Relocating package from
    /spack/opt/spack to /home/spack/spack/opt/spack.
  ==> Successfully installed parmetis from binary cache
  [+] /home/spack/spack/opt/spack/linux-ubuntu18.04-x86_64/gcc-7.4.0/parmetis-4.0.3-khzaszhki3ghfcwedrs7eay7ycphnv6x
  ==> Installing suite-sparse
  ==> Searching for binary cache of suite-sparse
  ==> Fetching file:///mirror/build_cache/linux-ubuntu18.04-x86_64/gcc-7.4.0/suite-sparse-5.3.0/linux-ubuntu18.04-x86_64-gcc-7.4.0-suite-sparse-5.3.0-3jghv4qpmozfnfdmulpmap4x5fy2ajaq.spack
  ########################################################################################################################################### 100.0%
  ==> Installing suite-sparse from binary cache
  gpg: Signature made Thu Oct 31 21:43:10 2019 UTC
  gpg:                using RSA key 7D344E2992071B0AAAE1EDB0E68DE2A80314303D
  gpg: Good signature from "prl" [unknown]
  gpg: WARNING: This key is not certified with a trusted signature!
  gpg:          There is no indication that the signature belongs to the owner.
  Primary key fingerprint: 7D34 4E29 9207 1B0A AAE1  EDB0 E68D E2A8 0314 303D
  ==> Relocating package from
    /spack/opt/spack to /home/spack/spack/opt/spack.
  ==> Successfully installed suite-sparse from binary cache
  [+] /home/spack/spack/opt/spack/linux-ubuntu18.04-x86_64/gcc-7.4.0/suite-sparse-5.3.0-3jghv4qpmozfnfdmulpmap4x5fy2ajaq
  ==> Installing trilinos
  ==> Searching for binary cache of trilinos
  ==> Fetching file:///mirror/build_cache/linux-ubuntu18.04-x86_64/gcc-7.4.0/trilinos-12.14.1/linux-ubuntu18.04-x86_64-gcc-7.4.0-trilinos-12.14.1-mpalhktqqjjo2hayykb6ut2jyhkmow3z.spack
  ########################################################################################################################################### 100.0%
  ==> Installing trilinos from binary cache
  gpg: Signature made Thu Oct 31 22:14:03 2019 UTC
  gpg:                using RSA key 7D344E2992071B0AAAE1EDB0E68DE2A80314303D
  gpg: Good signature from "prl" [unknown]
  gpg: WARNING: This key is not certified with a trusted signature!
  gpg:          There is no indication that the signature belongs to the owner.
  Primary key fingerprint: 7D34 4E29 9207 1B0A AAE1  EDB0 E68D E2A8 0314 303D
  ==> Relocating package from
    /spack/opt/spack to /home/spack/spack/opt/spack.
  ==> Successfully installed trilinos from binary cache
  [+] /home/spack/spack/opt/spack/linux-ubuntu18.04-x86_64/gcc-7.4.0/trilinos-12.14.1-mpalhktqqjjo2hayykb6ut2jyhkmow3z

Now we're starting to see the power of Spack. Trilinos in its default
configuration has 23 top level dependecies, many of which have
dependencies of their own. Installing more complex packages can take
days or weeks even for an experienced user. Although we've done a
binary installation for the tutorial, a source installation of
trilinos using Spack takes about 3 hours (depending on the system),
but only 20 seconds of programmer time.

Spack manages constistency of the entire DAG. Every MPI dependency will
be satisfied by the same configuration of MPI, etc. If we install
``trilinos`` again specifying a dependency on our previous HDF5 built
with ``mpich``:

.. code-block:: console

  $ spack install trilinos +hdf5 ^hdf5+hl+mpi ^mpich
  ==> libiconv is already installed in /home/spack/spack/opt/spack/linux-ubuntu18.04-x86_64/gcc-7.4.0/libiconv-1.16-zvmmgjbnfrzbo3hl2ijqxcjpkiv7q3ab
  ==> diffutils is already installed in /home/spack/spack/opt/spack/linux-ubuntu18.04-x86_64/gcc-7.4.0/diffutils-3.7-vku7yph7wtd5y372dk3p7thg5lttsy2n
  ==> bzip2 is already installed in /home/spack/spack/opt/spack/linux-ubuntu18.04-x86_64/gcc-7.4.0/bzip2-1.0.8-g2ghsbb6kih2itnkcqc2v6iraimj23r4
  ==> zlib is already installed in /home/spack/spack/opt/spack/linux-ubuntu18.04-x86_64/gcc-7.4.0/zlib-1.2.11-o2viq7yriiaw6nwqpaa7ltpyzqkaonhb
  ==> boost is already installed in /home/spack/spack/opt/spack/linux-ubuntu18.04-x86_64/gcc-7.4.0/boost-1.70.0-d42gtzk7f4chkyjqyqbg5c7tkd3r375y
  ==> pkgconf is already installed in /home/spack/spack/opt/spack/linux-ubuntu18.04-x86_64/gcc-7.4.0/pkgconf-1.6.3-eifxmpsduqbsvgrk2sx5pn7cy5eraanr
  ==> ncurses is already installed in /home/spack/spack/opt/spack/linux-ubuntu18.04-x86_64/gcc-7.4.0/ncurses-6.1-s4rsiori6blknfxf2jx4nbfxfzvcww2k
  ==> readline is already installed in /home/spack/spack/opt/spack/linux-ubuntu18.04-x86_64/gcc-7.4.0/readline-8.0-hzwkvqampr3c6mfceyxq4xej7eyxoxoj
  ==> gdbm is already installed in /home/spack/spack/opt/spack/linux-ubuntu18.04-x86_64/gcc-7.4.0/gdbm-1.18.1-surdjxdcankv3xqk5tnnwroz3tor77o7
  ==> perl is already installed in /home/spack/spack/opt/spack/linux-ubuntu18.04-x86_64/gcc-7.4.0/perl-5.30.0-cxcj6eisjsfp3iv6xlio6rvc33fbxfmc
  ==> openssl is already installed in /home/spack/spack/opt/spack/linux-ubuntu18.04-x86_64/gcc-7.4.0/openssl-1.1.1d-jujqjv5qejwtzau7zmbcqft7ercsa5o5
  ==> cmake is already installed in /home/spack/spack/opt/spack/linux-ubuntu18.04-x86_64/gcc-7.4.0/cmake-3.15.4-3wkiwji3xtohdmgay4ti2m6sqkpmakv3
  ==> glm is already installed in /home/spack/spack/opt/spack/linux-ubuntu18.04-x86_64/gcc-7.4.0/glm-0.9.7.1-4zyyrqsditrvrxdgjlnouqosjzzcdjql
  ==> libsigsegv is already installed in /home/spack/spack/opt/spack/linux-ubuntu18.04-x86_64/gcc-7.4.0/libsigsegv-2.12-3khohgmwhbgvxehlt7rcnnzqfxelyv4p
  ==> m4 is already installed in /home/spack/spack/opt/spack/linux-ubuntu18.04-x86_64/gcc-7.4.0/m4-1.4.18-ut64la6rptcwos3uwl2kp5mle572hlhi
  ==> autoconf is already installed in /home/spack/spack/opt/spack/linux-ubuntu18.04-x86_64/gcc-7.4.0/autoconf-2.69-g23qfulbkb5qtgmpuwyv65o3p2r7w434
  ==> automake is already installed in /home/spack/spack/opt/spack/linux-ubuntu18.04-x86_64/gcc-7.4.0/automake-1.16.1-io3tplo73zw2v5lkbknnvsk7tszjaj2d
  ==> libtool is already installed in /home/spack/spack/opt/spack/linux-ubuntu18.04-x86_64/gcc-7.4.0/libtool-2.4.6-4neu5jwwmuo26mjs6363q6bupczjk6hk
  ==> texinfo is already installed in /home/spack/spack/opt/spack/linux-ubuntu18.04-x86_64/gcc-7.4.0/texinfo-6.5-hyetop53cbzzvs4nydn447k6mxar7oom
  ==> findutils is already installed in /home/spack/spack/opt/spack/linux-ubuntu18.04-x86_64/gcc-7.4.0/findutils-4.6.0-uf3gw7kk3bfknzvmmqax733o6i63qtrz
  ==> util-macros is already installed in /home/spack/spack/opt/spack/linux-ubuntu18.04-x86_64/gcc-7.4.0/util-macros-1.19.1-a226ran4thxadofd7yow3sfng3gy3t3k
  ==> libpciaccess is already installed in /home/spack/spack/opt/spack/linux-ubuntu18.04-x86_64/gcc-7.4.0/libpciaccess-0.13.5-vhehc322oo5ipbbk465m6py6zzr4kdam
  ==> xz is already installed in /home/spack/spack/opt/spack/linux-ubuntu18.04-x86_64/gcc-7.4.0/xz-5.2.4-ur2jffeua3gzg5otnmqgfnfdexgtjxcl
  ==> libxml2 is already installed in /home/spack/spack/opt/spack/linux-ubuntu18.04-x86_64/gcc-7.4.0/libxml2-2.9.9-fg5evg4bxx4jy3paclojb46lok4fjclf
  ==> mpich is already installed in /home/spack/spack/opt/spack/linux-ubuntu18.04-x86_64/gcc-7.4.0/mpich-3.3.1-6e3rvexzhuij3csp7u2onkjtizsfowz2
  ==> hdf5 is already installed in /home/spack/spack/opt/spack/linux-ubuntu18.04-x86_64/gcc-7.4.0/hdf5-1.10.5-c24mwwta5dws3itb6vetov3ctoza4g6v
  ==> openblas is already installed in /home/spack/spack/opt/spack/linux-ubuntu18.04-x86_64/gcc-7.4.0/openblas-0.3.7-jepvsjbuh6mlpkxvsxyhh2r22cqeow7z
  ==> Installing hypre
  ==> Searching for binary cache of hypre
  ==> Finding buildcaches in /mirror/build_cache
  ==> Fetching file:///mirror/build_cache/linux-ubuntu18.04-x86_64/gcc-7.4.0/hypre-2.18.1/linux-ubuntu18.04-x86_64-gcc-7.4.0-hypre-2.18.1-ubwkr5uqpdtkld327ht2j7ioaig7ibkx.spack
  ########################################################################################################################################### 100.0%
  ==> Installing hypre from binary cache
  gpg: Signature made Thu Oct 31 21:56:43 2019 UTC
  gpg:                using RSA key 7D344E2992071B0AAAE1EDB0E68DE2A80314303D
  gpg: Good signature from "prl" [unknown]
  gpg: WARNING: This key is not certified with a trusted signature!
  gpg:          There is no indication that the signature belongs to the owner.
  Primary key fingerprint: 7D34 4E29 9207 1B0A AAE1  EDB0 E68D E2A8 0314 303D
  ==> Relocating package from
    /spack/opt/spack to /home/spack/spack/opt/spack.
  ==> Successfully installed hypre from binary cache
  [+] /home/spack/spack/opt/spack/linux-ubuntu18.04-x86_64/gcc-7.4.0/hypre-2.18.1-ubwkr5uqpdtkld327ht2j7ioaig7ibkx
  ==> Installing matio
  ==> Searching for binary cache of matio
  ==> Fetching file:///mirror/build_cache/linux-ubuntu18.04-x86_64/gcc-7.4.0/matio-1.5.13/linux-ubuntu18.04-x86_64-gcc-7.4.0-matio-1.5.13-mexumm466bufutty7hjot5pmfo3iaklp.spack
  ########################################################################################################################################### 100.0%
  ==> Installing matio from binary cache
  gpg: Signature made Thu Oct 31 22:16:14 2019 UTC
  gpg:                using RSA key 7D344E2992071B0AAAE1EDB0E68DE2A80314303D
  gpg: Good signature from "prl" [unknown]
  gpg: WARNING: This key is not certified with a trusted signature!
  gpg:          There is no indication that the signature belongs to the owner.
  Primary key fingerprint: 7D34 4E29 9207 1B0A AAE1  EDB0 E68D E2A8 0314 303D
  ==> Relocating package from
    /spack/opt/spack to /home/spack/spack/opt/spack.
  ==> Successfully installed matio from binary cache
  [+] /home/spack/spack/opt/spack/linux-ubuntu18.04-x86_64/gcc-7.4.0/matio-1.5.13-mexumm466bufutty7hjot5pmfo3iaklp
  ==> metis is already installed in /home/spack/spack/opt/spack/linux-ubuntu18.04-x86_64/gcc-7.4.0/metis-5.1.0-q6wvktue4oy654iuyspzahnj7xbgjjry
  ==> Installing netlib-scalapack
  ==> Searching for binary cache of netlib-scalapack
  ==> Fetching file:///mirror/build_cache/linux-ubuntu18.04-x86_64/gcc-7.4.0/netlib-scalapack-2.0.2/linux-ubuntu18.04-x86_64-gcc-7.4.0-netlib-scalapack-2.0.2-tbp3lv6ndjbyt22n4rmt3a3xmtdfnil5.spack
  ########################################################################################################################################### 100.0%
  ==> Installing netlib-scalapack from binary cache
  gpg: Signature made Thu Oct 31 22:17:03 2019 UTC
  gpg:                using RSA key 7D344E2992071B0AAAE1EDB0E68DE2A80314303D
  gpg: Good signature from "prl" [unknown]
  gpg: WARNING: This key is not certified with a trusted signature!
  gpg:          There is no indication that the signature belongs to the owner.
  Primary key fingerprint: 7D34 4E29 9207 1B0A AAE1  EDB0 E68D E2A8 0314 303D
  ==> Relocating package from
    /spack/opt/spack to /home/spack/spack/opt/spack.
  ==> Successfully installed netlib-scalapack from binary cache
  [+] /home/spack/spack/opt/spack/linux-ubuntu18.04-x86_64/gcc-7.4.0/netlib-scalapack-2.0.2-tbp3lv6ndjbyt22n4rmt3a3xmtdfnil5
  ==> Installing mumps
  ==> Searching for binary cache of mumps
  ==> Fetching file:///mirror/build_cache/linux-ubuntu18.04-x86_64/gcc-7.4.0/mumps-5.2.0/linux-ubuntu18.04-x86_64-gcc-7.4.0-mumps-5.2.0-nippo7jgc5x3eshu324uvjqfxane57zy.spack
  ########################################################################################################################################### 100.0%
  ==> Installing mumps from binary cache
  gpg: Signature made Thu Oct 31 22:16:53 2019 UTC
  gpg:                using RSA key 7D344E2992071B0AAAE1EDB0E68DE2A80314303D
  gpg: Good signature from "prl" [unknown]
  gpg: WARNING: This key is not certified with a trusted signature!
  gpg:          There is no indication that the signature belongs to the owner.
  Primary key fingerprint: 7D34 4E29 9207 1B0A AAE1  EDB0 E68D E2A8 0314 303D
  ==> Relocating package from
    /spack/opt/spack to /home/spack/spack/opt/spack.
  ==> Successfully installed mumps from binary cache
  [+] /home/spack/spack/opt/spack/linux-ubuntu18.04-x86_64/gcc-7.4.0/mumps-5.2.0-nippo7jgc5x3eshu324uvjqfxane57zy
  ==> Installing netcdf
  ==> Searching for binary cache of netcdf
  ==> Fetching file:///mirror/build_cache/linux-ubuntu18.04-x86_64/gcc-7.4.0/netcdf-4.7.1/linux-ubuntu18.04-x86_64-gcc-7.4.0-netcdf-4.7.1-vx6vje7u4hsyw7wewzgefhccjnvhzwnh.spack
  ########################################################################################################################################### 100.0%
  ==> Installing netcdf from binary cache
  gpg: Signature made Thu Oct 31 21:54:09 2019 UTC
  gpg:                using RSA key 7D344E2992071B0AAAE1EDB0E68DE2A80314303D
  gpg: Good signature from "prl" [unknown]
  gpg: WARNING: This key is not certified with a trusted signature!
  gpg:          There is no indication that the signature belongs to the owner.
  Primary key fingerprint: 7D34 4E29 9207 1B0A AAE1  EDB0 E68D E2A8 0314 303D
  ==> Relocating package from
    /spack/opt/spack to /home/spack/spack/opt/spack.
  ==> Successfully installed netcdf from binary cache
  [+] /home/spack/spack/opt/spack/linux-ubuntu18.04-x86_64/gcc-7.4.0/netcdf-4.7.1-vx6vje7u4hsyw7wewzgefhccjnvhzwnh
  ==> Installing parmetis
  ==> Searching for binary cache of parmetis
  ==> Fetching file:///mirror/build_cache/linux-ubuntu18.04-x86_64/gcc-7.4.0/parmetis-4.0.3/linux-ubuntu18.04-x86_64-gcc-7.4.0-parmetis-4.0.3-t6gxi6ecsf56ukym5l7x3nqjkm5cfm2b.spack
  ########################################################################################################################################### 100.0%
  ==> Installing parmetis from binary cache
  gpg: Signature made Thu Oct 31 22:16:48 2019 UTC
  gpg:                using RSA key 7D344E2992071B0AAAE1EDB0E68DE2A80314303D
  gpg: Good signature from "prl" [unknown]
  gpg: WARNING: This key is not certified with a trusted signature!
  gpg:          There is no indication that the signature belongs to the owner.
  Primary key fingerprint: 7D34 4E29 9207 1B0A AAE1  EDB0 E68D E2A8 0314 303D
  ==> Relocating package from
    /spack/opt/spack to /home/spack/spack/opt/spack.
  ==> Successfully installed parmetis from binary cache
  [+] /home/spack/spack/opt/spack/linux-ubuntu18.04-x86_64/gcc-7.4.0/parmetis-4.0.3-t6gxi6ecsf56ukym5l7x3nqjkm5cfm2b
  ==> suite-sparse is already installed in /home/spack/spack/opt/spack/linux-ubuntu18.04-x86_64/gcc-7.4.0/suite-sparse-5.3.0-3jghv4qpmozfnfdmulpmap4x5fy2ajaq
  ==> Installing trilinos
  ==> Searching for binary cache of trilinos
  ==> Fetching file:///mirror/build_cache/linux-ubuntu18.04-x86_64/gcc-7.4.0/trilinos-12.14.1/linux-ubuntu18.04-x86_64-gcc-7.4.0-trilinos-12.14.1-ioo4i643shsbor4jfjdtzxju2m4hv4we.spack
  ########################################################################################################################################### 100.0%
  ==> Installing trilinos from binary cache
  gpg: Signature made Thu Oct 31 22:06:12 2019 UTC
  gpg:                using RSA key 7D344E2992071B0AAAE1EDB0E68DE2A80314303D
  gpg: Good signature from "prl" [unknown]
  gpg: WARNING: This key is not certified with a trusted signature!
  gpg:          There is no indication that the signature belongs to the owner.
  Primary key fingerprint: 7D34 4E29 9207 1B0A AAE1  EDB0 E68D E2A8 0314 303D
  ==> Relocating package from
    /spack/opt/spack to /home/spack/spack/opt/spack.
  ==> Successfully installed trilinos from binary cache
  [+] /home/spack/spack/opt/spack/linux-ubuntu18.04-x86_64/gcc-7.4.0/trilinos-12.14.1-ioo4i643shsbor4jfjdtzxju2m4hv4we


We see that every package in the trilinos DAG that depends on MPI now
uses ``mpich``.

.. code-block:: console

  $ spack find -d trilinos
  ==> 2 installed packages
  -- linux-ubuntu18.04-x86_64 / gcc@7.4.0 -------------------------
  trilinos@12.14.1
      boost@1.70.0
          bzip2@1.0.8
          zlib@1.2.11
      glm@0.9.7.1
      hdf5@1.10.5
          mpich@3.3.1
              libpciaccess@0.13.5
              libxml2@2.9.9
                  libiconv@1.16
                  xz@5.2.4
      hypre@2.18.1
          openblas@0.3.7
      matio@1.5.13
      metis@5.1.0
      mumps@5.2.0
          netlib-scalapack@2.0.2
      netcdf@4.7.1
      parmetis@4.0.3
      suite-sparse@5.3.0

  trilinos@12.14.1
      boost@1.70.0
          bzip2@1.0.8
          zlib@1.2.11
      glm@0.9.7.1
      hdf5@1.10.5
          openmpi@3.1.4
              hwloc@1.11.11
                  libpciaccess@0.13.5
                  libxml2@2.9.9
                      libiconv@1.16
                      xz@5.2.4
                  numactl@2.0.12
      hypre@2.18.1
          openblas@0.3.7
      matio@1.5.13
      metis@5.1.0
      mumps@5.2.0
          netlib-scalapack@2.0.2
      netcdf@4.7.1
      parmetis@4.0.3
      suite-sparse@5.3.0



As we discussed before, the ``spack find -d`` command shows the
dependency information as a tree. While that is often sufficient, many
complicated packages, including trilinos, have dependencies that
cannot be fully represented as a tree. Again, the ``spack graph``
command shows the full DAG of the dependency information.

.. code-block:: console

  $ spack graph trilinos
  o  trilinos
  |\
  | |\
  | | |\
  | | | |\
  | | | | |\
  | | | | | |\
  | | | | | | |\
  | | | | | | | |\
  | | | | | | | | |\
  | | | | | | | | | |\
  | | | | | | | | | | |\
  | | | | | | | | | | | |\
  | | | | | | | | | | | | |\
  o | | | | | | | | | | | | |  suite-sparse
  |\ \ \ \ \ \ \ \ \ \ \ \ \ \
  | |_|_|/ / / / / / / / / / /
  |/| | | | | | | | | | | | |
  | |\ \ \ \ \ \ \ \ \ \ \ \ \
  | | |_|_|_|_|_|/ / / / / / /
  | |/| | | | | | | | | | | |
  | | | |_|_|_|_|_|_|_|/ / /
  | | |/| | | | | | | | | |
  | | | o | | | | | | | | |  parmetis
  | | |/| | | | | | | | | |
  | |/|/| | | | | | | | | |
  | | | |/ / / / / / / / /
  | | | | | | o | | | | |  mumps
  | |_|_|_|_|/| | | | | |
  |/| | | |_|/| | | | | |
  | | | |/| |/ / / / / /
  | | | | |/| | | | | |
  | | | | o | | | | | |  netlib-scalapack
  | |_|_|/| | | | | | |
  |/| | |/| | | | | | |
  | | |/|/ / / / / / /
  | o | | | | | | | |  metis
  | |/ / / / / / / /
  | | | | | | | o |  glm
  | | |_|_|_|_|/ /
  | |/| | | | | |
  | o | | | | | |  cmake
  | |\ \ \ \ \ \ \
  | o | | | | | | |  openssl
  | |\ \ \ \ \ \ \ \
  | | | | | o | | | |  netcdf
  | | |_|_|/| | | | |
  | |/| | |/| | | | |
  | | | | | |\ \ \ \ \
  | | | | | | | |_|/ /
  | | | | | | |/| | |
  | | | | | | | o | |  matio
  | | |_|_|_|_|/| | |
  | |/| | | | |/ / /
  | | | | | | | o |  hypre
  | |_|_|_|_|_|/| |
  |/| | | | |_|/ /
  | | | | |/| | |
  | | | | | | o |  hdf5
  | | |_|_|_|/| |
  | |/| | | |/ /
  | | | | |/| |
  | | | | o | |  openmpi
  | | |_|/| | |
  | |/| | | | |
  | | | | |\ \ \
  | | | | | o | |  hwloc
  | | | | |/| | |
  | | | | | |\ \ \
  | | | | | | |\ \ \
  | | | | | | o | | |  libxml2
  | | |_|_|_|/| | | |
  | |/| | | |/| | | |
  | | | | | | |\ \ \ \
  | | | | | | | | | | o  boost
  | | |_|_|_|_|_|_|_|/|
  | |/| | | | | | | | |
  | o | | | | | | | | |  zlib
  |  / / / / / / / / /
  | | | | | o | | | |  xz
  | | | | |  / / / /
  | | | | | | o | |  libpciaccess
  | | | | | |/| | |
  | | | | |/| | | |
  | | | | | | |\ \ \
  | | | | | | o | | |  util-macros
  | | | | | |  / / /
  | | | o | | | | |  numactl
  | | | |\ \ \ \ \ \
  | | | | |_|_|_|/ /
  | | | |/| | | | |
  | | | | |\ \ \ \ \
  | | | | | |_|_|/ /
  | | | | |/| | | |
  | | | | | |\ \ \ \
  | | | | | o | | | |  automake
  | | |_|_|/| | | | |
  | |/| | | | | | | |
  | | | | | |/ / / /
  | | | | | o | | |  autoconf
  | | |_|_|/| | | |
  | |/| | |/ / / /
  | | | |/| | | |
  | o | | | | | |  perl
  | o | | | | | |  gdbm
  | o | | | | | |  readline
  | |/ / / / / /
  | o | | | | |  ncurses
  | | |_|/ / /
  | |/| | | |
  | o | | | |  pkgconf
  |  / / / /
  o | | | |  openblas
   / / / /
  | o | |  libtool
  |/ / /
  o | |  m4
  o | |  libsigsegv
   / /
  | o  bzip2
  | o  diffutils
  |/
  o  libiconv

You can control how the output is displayed with a number of options.

The ASCII output from ``spack graph`` can be difficult to parse for
complicated packages. The output can be changed to the ``graphviz``
``.dot`` format using the ``--dot`` flag.

.. code-block:: console

  $ spack graph --dot trilinos | dot -Tpdf trilinos_graph.pdf

.. _basics-tutorial-uninstall:

---------------------
Uninstalling Packages
---------------------

Earlier we installed many configurations each of zlib and tcl. Now we
will go through and uninstall some of those packages that we didn't
really need.

.. code-block:: console

  $ spack find -d tcl
  ==> 3 installed packages
  -- linux-ubuntu18.04-x86_64 / clang@6.0.0 -----------------------
  tcl@8.6.8
      zlib@1.2.8


  -- linux-ubuntu18.04-x86_64 / gcc@7.4.0 -------------------------
  tcl@8.6.8
      zlib@1.2.11

  tcl@8.6.8
      zlib@1.2.8


  $ spack find zlib
  ==> 6 installed packages
  -- linux-ubuntu18.04-x86_64 / clang@6.0.0 -----------------------
  zlib@1.2.8  zlib@1.2.11

  -- linux-ubuntu18.04-x86_64 / gcc@6.5.0 -------------------------
  zlib@1.2.11

  -- linux-ubuntu18.04-x86_64 / gcc@7.4.0 -------------------------
  zlib@1.2.8  zlib@1.2.8  zlib@1.2.11

We can uninstall packages by spec using the same syntax as install.

.. code-block:: console

  $ spack uninstall zlib %gcc@6.5.0
  ==> The following packages will be uninstalled:

      -- linux-ubuntu18.04-x86_64 / gcc@6.5.0 -------------------------
      qtrzwov zlib@1.2.11%gcc +optimize+pic+shared
  ==> Do you want to proceed? [y/N] y
  ==> Successfully uninstalled zlib@1.2.11%gcc@6.5.0+optimize+pic+shared arch=linux-ubuntu18.04-x86_64/qtrzwov

  $ spack find -lf zlib
  ==> 5 installed packages
  -- linux-ubuntu18.04-x86_64 / clang@6.0.0 -----------------------
  pdfmc5x zlib@1.2.8%clang   5qffmms zlib@1.2.11%clang

  -- linux-ubuntu18.04-x86_64 / gcc@7.4.0 -------------------------
  d6ety7c zlib@1.2.8%gcc   hmvjty5 zlib@1.2.8%gcc  cppflags="-O3"   o2viq7y zlib@1.2.11%gcc

We can also uninstall packages by referring only to their hash.

We can use either ``-f`` (force) or ``-R`` (remove dependents as well) to
remove packages that are required by another installed package.

.. code-block:: console

  $ spack uninstall zlib/pdfmc5x
  ==> Will not uninstall zlib@1.2.8%clang@6.0.0/pdfmc5x
  The following packages depend on it:
      -- linux-ubuntu18.04-x86_64 / clang@6.0.0 -----------------------
      4ef57sw tcl@8.6.8%clang

  ==> Error: There are still dependents.
    use `spack uninstall --dependents` to remove dependents too


  $ spack uninstall -R zlib/pdfmc5x
  ==> The following packages will be uninstalled:

      -- linux-ubuntu18.04-x86_64 / clang@6.0.0 -----------------------
      4ef57sw tcl@8.6.8%clang   pdfmc5x zlib@1.2.8%clang +optimize+pic+shared
  ==> Do you want to proceed? [y/N] y
  ==> Successfully uninstalled tcl@8.6.8%clang@6.0.0 arch=linux-ubuntu18.04-x86_64/4ef57sw
  ==> Successfully uninstalled zlib@1.2.8%clang@6.0.0+optimize+pic+shared arch=linux-ubuntu18.04-x86_64/pdfmc5x


Spack will not uninstall packages that are not sufficiently
specified. The ``-a`` (all) flag can be used to uninstall multiple
packages at once.

.. code-block:: console

  $ spack uninstall trilinos
  ==> Error: trilinos matches multiple packages:

      -- linux-ubuntu18.04-x86_64 / gcc@7.4.0 -------------------------
      mpalhkt trilinos@12.14.1%gcc ~adios2~alloptpkgs+amesos+amesos2+anasazi+aztec+belos+boost build_type=RelWithDebInfo ~cgns~chaco~complex~debug~dtk+epetra+epetraext+exodus+explicit_template_instantiation~float+fortran~fortrilinos+gtest+hdf5+hypre+ifpack+ifpack2~intrepid~intrepid2~isorropia+kokkos+metis~minitensor+ml+muelu+mumps~nox~openmp~phalanx~piro~pnetcdf~python~rol~rythmos+sacado~shards+shared~shylu~stk+suite-sparse~superlu~superlu-dist~teko~tempus+teuchos+tpetra~x11~xsdkflags~zlib+zoltan+zoltan2
      ioo4i64 trilinos@12.14.1%gcc ~adios2~alloptpkgs+amesos+amesos2+anasazi+aztec+belos+boost build_type=RelWithDebInfo ~cgns~chaco~complex~debug~dtk+epetra+epetraext+exodus+explicit_template_instantiation~float+fortran~fortrilinos+gtest+hdf5+hypre+ifpack+ifpack2~intrepid~intrepid2~isorropia+kokkos+metis~minitensor+ml+muelu+mumps~nox~openmp~phalanx~piro~pnetcdf~python~rol~rythmos+sacado~shards+shared~shylu~stk+suite-sparse~superlu~superlu-dist~teko~tempus+teuchos+tpetra~x11~xsdkflags~zlib+zoltan+zoltan2

  ==> Error: You can either:
      a) use a more specific spec, or
      b) use `spack uninstall --all` to uninstall ALL matching specs.


  $ spack uninstall /mpalhkt
  ==> The following packages will be uninstalled:

      -- linux-ubuntu18.04-x86_64 / gcc@7.4.0 -------------------------
      mpalhkt trilinos@12.14.1%gcc ~adios2~alloptpkgs+amesos+amesos2+anasazi+aztec+belos+boost build_type=RelWithDebInfo ~cgns~chaco~complex~debug~dtk+epetra+epetraext+exodus+explicit_template_instantiation~float+fortran~fortrilinos+gtest+hdf5+hypre+ifpack+ifpack2~intrepid~intrepid2~isorropia+kokkos+metis~minitensor+ml+muelu+mumps~nox~openmp~phalanx~piro~pnetcdf~python~rol~rythmos+sacado~shards+shared~shylu~stk+suite-sparse~superlu~superlu-dist~teko~tempus+teuchos+tpetra~x11~xsdkflags~zlib+zoltan+zoltan2
  ==> Do you want to proceed? [y/N] y
  ==> Successfully uninstalled trilinos@12.14.1%gcc@7.4.0~adios2~alloptpkgs+amesos+amesos2+anasazi+aztec+belos+boost build_type=RelWithDebInfo ~cgns~chaco~complex~debug~dtk+epetra+epetraext+exodus+explicit_template_instantiation~float+fortran~fortrilinos+gtest+hdf5+hypre+ifpack+ifpack2~intrepid~intrepid2~isorropia+kokkos+metis~minitensor+ml+muelu+mumps~nox~openmp~phalanx~piro~pnetcdf~python~rol~rythmos+sacado~shards+shared~shylu~stk+suite-sparse~superlu~superlu-dist~teko~tempus+teuchos+tpetra~x11~xsdkflags~zlib+zoltan+zoltan2 arch=linux-ubuntu18.04-x86_64/mpalhkt

-----------------------------
Advanced ``spack find`` Usage
-----------------------------

We will go over some additional uses for the ``spack find`` command not
already covered in the :ref:`basics-tutorial-install` and
:ref:`basics-tutorial-uninstall` sections.

The ``spack find`` command can accept what we call "anonymous specs."
These are expressions in spec syntax that do not contain a package
name. For example, ``spack find ^mpich`` will return every installed
package that depends on mpich, and ``spack find cppflags="-O3"`` will
return every package which was built with ``cppflags="-O3"``.

.. code-block:: console

  $ spack find ^mpich
  ==> 8 installed packages
  -- linux-ubuntu18.04-x86_64 / gcc@7.4.0 -------------------------
  hdf5@1.10.5  hypre@2.18.1  matio@1.5.13  mumps@5.2.0  netcdf@4.7.1  netlib-scalapack@2.0.2  parmetis@4.0.3  trilinos@12.14.1

  $ spack find cppflags=-O3
  ==> 1 installed package
  -- linux-ubuntu18.04-x86_64 / gcc@7.4.0 -------------------------
  zlib@1.2.8

The ``find`` command can also show which packages were installed
explicitly (rather than pulled in as a dependency) using the ``-x``
flag. The ``-X`` flag shows implicit installs only. The ``find`` command can
also show the path to which a spack package was installed using the ``-p``
command.

.. code-block:: console

  $ spack find -px
  ==> 10 installed packages
  -- linux-ubuntu18.04-x86_64 / clang@6.0.0 -----------------------
  zlib@1.2.11  /home/spack/spack/opt/spack/linux-ubuntu18.04-x86_64/clang-6.0.0/zlib-1.2.11-5qffmms6gwykcikh6aag4h3z4scrfdla

  -- linux-ubuntu18.04-x86_64 / gcc@7.4.0 -------------------------
  hdf5@1.10.5       /home/spack/spack/opt/spack/linux-ubuntu18.04-x86_64/gcc-7.4.0/hdf5-1.10.5-fuuwoa2jk65h7xlr4tmhvomswegcpkjo
  hdf5@1.10.5       /home/spack/spack/opt/spack/linux-ubuntu18.04-x86_64/gcc-7.4.0/hdf5-1.10.5-audmuesjjp62dbn2ldwt576f3yurx5cs
  hdf5@1.10.5       /home/spack/spack/opt/spack/linux-ubuntu18.04-x86_64/gcc-7.4.0/hdf5-1.10.5-c24mwwta5dws3itb6vetov3ctoza4g6v
  tcl@8.6.8         /home/spack/spack/opt/spack/linux-ubuntu18.04-x86_64/gcc-7.4.0/tcl-8.6.8-t3gp773osdwptcklekqkqg5742zbq42b
  tcl@8.6.8         /home/spack/spack/opt/spack/linux-ubuntu18.04-x86_64/gcc-7.4.0/tcl-8.6.8-nstkcalz4ryzfzirsyeql5dmmi2chcig
  trilinos@12.14.1  /home/spack/spack/opt/spack/linux-ubuntu18.04-x86_64/gcc-7.4.0/trilinos-12.14.1-ioo4i643shsbor4jfjdtzxju2m4hv4we
  zlib@1.2.8        /home/spack/spack/opt/spack/linux-ubuntu18.04-x86_64/gcc-7.4.0/zlib-1.2.8-d6ety7cr4j2otoiai3cuqparcdifq35n
  zlib@1.2.8        /home/spack/spack/opt/spack/linux-ubuntu18.04-x86_64/gcc-7.4.0/zlib-1.2.8-hmvjty5ey5ism3za5m7yewpa7in22poc
  zlib@1.2.11       /home/spack/spack/opt/spack/linux-ubuntu18.04-x86_64/gcc-7.4.0/zlib-1.2.11-o2viq7yriiaw6nwqpaa7ltpyzqkaonhb

---------------------
Customizing Compilers
---------------------


Spack manages a list of available compilers on the system, detected
automatically from from the user's ``PATH`` variable. The ``spack
compilers`` command is an alias for the command ``spack compiler list``.

.. code-block:: console

  $ spack compilers
  ==> Available compilers
  -- clang ubuntu18.04-x86_64 -------------------------------------
  clang@6.0.0

  -- gcc ubuntu18.04-x86_64 ---------------------------------------
  gcc@7.4.0  gcc@6.5.0

The compilers are maintained in a YAML file. Later in the tutorial you
will learn how to configure compilers by hand for special cases. Spack
also has tools to add compilers, and compilers built with Spack can be
added to the configuration.

.. code-block:: console

  $ spack install gcc @8.3.0
  ==> libsigsegv is already installed in /home/spack/spack/opt/spack/linux-ubuntu18.04-x86_64/gcc-7.4.0/libsigsegv-2.12-3khohgmwhbgvxehlt7rcnnzqfxelyv4p
  ==> m4 is already installed in /home/spack/spack/opt/spack/linux-ubuntu18.04-x86_64/gcc-7.4.0/m4-1.4.18-ut64la6rptcwos3uwl2kp5mle572hlhi
  ==> pkgconf is already installed in /home/spack/spack/opt/spack/linux-ubuntu18.04-x86_64/gcc-7.4.0/pkgconf-1.6.3-eifxmpsduqbsvgrk2sx5pn7cy5eraanr
  ==> ncurses is already installed in /home/spack/spack/opt/spack/linux-ubuntu18.04-x86_64/gcc-7.4.0/ncurses-6.1-s4rsiori6blknfxf2jx4nbfxfzvcww2k
  ==> readline is already installed in /home/spack/spack/opt/spack/linux-ubuntu18.04-x86_64/gcc-7.4.0/readline-8.0-hzwkvqampr3c6mfceyxq4xej7eyxoxoj
  ==> gdbm is already installed in /home/spack/spack/opt/spack/linux-ubuntu18.04-x86_64/gcc-7.4.0/gdbm-1.18.1-surdjxdcankv3xqk5tnnwroz3tor77o7
  ==> perl is already installed in /home/spack/spack/opt/spack/linux-ubuntu18.04-x86_64/gcc-7.4.0/perl-5.30.0-cxcj6eisjsfp3iv6xlio6rvc33fbxfmc
  ==> autoconf is already installed in /home/spack/spack/opt/spack/linux-ubuntu18.04-x86_64/gcc-7.4.0/autoconf-2.69-g23qfulbkb5qtgmpuwyv65o3p2r7w434
  ==> automake is already installed in /home/spack/spack/opt/spack/linux-ubuntu18.04-x86_64/gcc-7.4.0/automake-1.16.1-io3tplo73zw2v5lkbknnvsk7tszjaj2d
  ==> libtool is already installed in /home/spack/spack/opt/spack/linux-ubuntu18.04-x86_64/gcc-7.4.0/libtool-2.4.6-4neu5jwwmuo26mjs6363q6bupczjk6hk
  ==> Installing gmp
  ==> Searching for binary cache of gmp
  ==> Finding buildcaches in /mirror/build_cache
  ==> Fetching file:///mirror/build_cache/linux-ubuntu18.04-x86_64/gcc-7.4.0/gmp-6.1.2/linux-ubuntu18.04-x86_64-gcc-7.4.0-gmp-6.1.2-fz3lzqixnahwwqeqsxwevhek4eejmz3z.spack
  ########################################################################################################################################### 100.0%
  ==> Installing gmp from binary cache
  gpg: Signature made Thu Oct 31 21:59:51 2019 UTC
  gpg:                using RSA key 7D344E2992071B0AAAE1EDB0E68DE2A80314303D
  gpg: Good signature from "prl" [unknown]
  gpg: WARNING: This key is not certified with a trusted signature!
  gpg:          There is no indication that the signature belongs to the owner.
  Primary key fingerprint: 7D34 4E29 9207 1B0A AAE1  EDB0 E68D E2A8 0314 303D
  ==> Relocating package from
    /spack/opt/spack to /home/spack/spack/opt/spack.
  ==> Successfully installed gmp from binary cache
  [+] /home/spack/spack/opt/spack/linux-ubuntu18.04-x86_64/gcc-7.4.0/gmp-6.1.2-fz3lzqixnahwwqeqsxwevhek4eejmz3z
  ==> Installing isl
  ==> Searching for binary cache of isl
  ==> Fetching file:///mirror/build_cache/linux-ubuntu18.04-x86_64/gcc-7.4.0/isl-0.18/linux-ubuntu18.04-x86_64-gcc-7.4.0-isl-0.18-f4xq2neprkyl7n2ietukf7uzlbqhg2pf.spack
  ########################################################################################################################################### 100.0%
  ==> Installing isl from binary cache
  gpg: Signature made Thu Oct 31 22:00:20 2019 UTC
  gpg:                using RSA key 7D344E2992071B0AAAE1EDB0E68DE2A80314303D
  gpg: Good signature from "prl" [unknown]
  gpg: WARNING: This key is not certified with a trusted signature!
  gpg:          There is no indication that the signature belongs to the owner.
  Primary key fingerprint: 7D34 4E29 9207 1B0A AAE1  EDB0 E68D E2A8 0314 303D
  ==> Relocating package from
    /spack/opt/spack to /home/spack/spack/opt/spack.
  ==> Successfully installed isl from binary cache
  [+] /home/spack/spack/opt/spack/linux-ubuntu18.04-x86_64/gcc-7.4.0/isl-0.18-f4xq2neprkyl7n2ietukf7uzlbqhg2pf
  ==> libiconv is already installed in /home/spack/spack/opt/spack/linux-ubuntu18.04-x86_64/gcc-7.4.0/libiconv-1.16-zvmmgjbnfrzbo3hl2ijqxcjpkiv7q3ab
  ==> Installing mpfr
  ==> Searching for binary cache of mpfr
  ==> Fetching file:///mirror/build_cache/linux-ubuntu18.04-x86_64/gcc-7.4.0/mpfr-3.1.6/linux-ubuntu18.04-x86_64-gcc-7.4.0-mpfr-3.1.6-joz6bhq7cyctk45wb62n564dqwyl2njr.spack
  ########################################################################################################################################### 100.0%
  ==> Installing mpfr from binary cache
  gpg: Signature made Thu Oct 31 21:56:12 2019 UTC
  gpg:                using RSA key 7D344E2992071B0AAAE1EDB0E68DE2A80314303D
  gpg: Good signature from "prl" [unknown]
  gpg: WARNING: This key is not certified with a trusted signature!
  gpg:          There is no indication that the signature belongs to the owner.
  Primary key fingerprint: 7D34 4E29 9207 1B0A AAE1  EDB0 E68D E2A8 0314 303D
  ==> Relocating package from
    /spack/opt/spack to /home/spack/spack/opt/spack.
  ==> Successfully installed mpfr from binary cache
  [+] /home/spack/spack/opt/spack/linux-ubuntu18.04-x86_64/gcc-7.4.0/mpfr-3.1.6-joz6bhq7cyctk45wb62n564dqwyl2njr
  ==> Installing mpc
  ==> Searching for binary cache of mpc
  ==> Fetching file:///mirror/build_cache/linux-ubuntu18.04-x86_64/gcc-7.4.0/mpc-1.1.0/linux-ubuntu18.04-x86_64-gcc-7.4.0-mpc-1.1.0-7uvv4z62tyub5ywgulhaf332wwvv3cla.spack
  ########################################################################################################################################### 100.0%
  ==> Installing mpc from binary cache
  gpg: Signature made Thu Oct 31 21:56:39 2019 UTC
  gpg:                using RSA key 7D344E2992071B0AAAE1EDB0E68DE2A80314303D
  gpg: Good signature from "prl" [unknown]
  gpg: WARNING: This key is not certified with a trusted signature!
  gpg:          There is no indication that the signature belongs to the owner.
  Primary key fingerprint: 7D34 4E29 9207 1B0A AAE1  EDB0 E68D E2A8 0314 303D
  ==> Relocating package from
    /spack/opt/spack to /home/spack/spack/opt/spack.
  ==> Successfully installed mpc from binary cache
  [+] /home/spack/spack/opt/spack/linux-ubuntu18.04-x86_64/gcc-7.4.0/mpc-1.1.0-7uvv4z62tyub5ywgulhaf332wwvv3cla
  ==> zlib is already installed in /home/spack/spack/opt/spack/linux-ubuntu18.04-x86_64/gcc-7.4.0/zlib-1.2.11-o2viq7yriiaw6nwqpaa7ltpyzqkaonhb
  ==> Installing gcc
  ==> Searching for binary cache of gcc
  ==> Fetching file:///mirror/build_cache/linux-ubuntu18.04-x86_64/gcc-7.4.0/gcc-8.3.0/linux-ubuntu18.04-x86_64-gcc-7.4.0-gcc-8.3.0-rvoysuvia7pirmb3kee6xjh7zcmhbi5k.spack
  ########################################################################################################################################### 100.0%
  ==> Installing gcc from binary cache
  gpg: Signature made Thu Oct 31 21:51:00 2019 UTC
  gpg:                using RSA key 7D344E2992071B0AAAE1EDB0E68DE2A80314303D
  gpg: Good signature from "prl" [unknown]
  gpg: WARNING: This key is not certified with a trusted signature!
  gpg:          There is no indication that the signature belongs to the owner.
  Primary key fingerprint: 7D34 4E29 9207 1B0A AAE1  EDB0 E68D E2A8 0314 303D
  ==> Relocating package from
    /spack/opt/spack to /home/spack/spack/opt/spack.
  ==> Successfully installed gcc from binary cache
  [+] /home/spack/spack/opt/spack/linux-ubuntu18.04-x86_64/gcc-7.4.0/gcc-8.3.0-rvoysuvia7pirmb3kee6xjh7zcmhbi5k

  $ spack find -p gcc
  spack find -p gcc
  ==> 1 installed package
  -- linux-ubuntu18.04-x86_64 / gcc@7.4.0 -------------------------
  gcc@8.3.0  /home/spack/spack/opt/spack/linux-ubuntu18.04-x86_64/gcc-7.4.0/gcc-8.3.0-rvoysuvia7pirmb3kee6xjh7zcmhbi5k

We can add gcc to Spack as an available compiler using the ``spack
compiler add`` command. This will allow future packages to build with
gcc @8.3.0.

.. code-block:: console

  $ spack compiler add $(spack location -i gcc@8.3.0)
  ==> Added 1 new compiler to /home/spack/.spack/linux/compilers.yaml
      gcc@8.3.0
  ==> Compilers are defined in the following files:
      /home/spack/.spack/linux/compilers.yaml

We can also remove compilers from our configuration using ``spack compiler remove <compiler_spec>``

.. code-block:: console

  $ spack compiler remove gcc@8.3.0
  ==> Removed compiler gcc@8.3.0
