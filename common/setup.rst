.. admonition:: Tutorial setup

   If you have not done the prior sections, you'll need to start the docker image::

       docker pull ghcr.io/spack/tutorial:cineca26
       docker run -it ghcr.io/spack/tutorial:cineca26

   and then set Spack up like this::

       git clone --depth=2 --branch=develop https://github.com/spack/spack
       . spack/share/spack/setup-env.sh
       spack repo update builtin --commit 79fd9821dceebf719a4cb544ba67c3b2f39132ca
       spack bootstrap now
       spack compiler find
       spack mirror add --unsigned tutorial /buildcache

   See the basics tutorial for full details on setup.
   For more help, join us in the ``#tutorial`` channel on Slack -- get an invitation at `slack.spack.io <https://slack.spack.io/>`_
