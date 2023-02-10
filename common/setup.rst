.. admonition:: Tutorial setup

   If you have not done the prior sections, you'll need to start the docker image::

       docker run -it ghcr.io/spack/tutorial:cineca23

   and then set Spack up like this::

       git clone --depth=100 --branch=releases/v0.19 https://github.com/spack/spack
       . spack/share/spack/setup-env.sh
       spack tutorial

   See the :ref:`basics-tutorial` for full details on setup. For more
   help, join us in the ``#tutorial`` channel on Slack -- get an
   invitation at `spackpm.herokuapp.com <https://spackpm.herokuapp.com>`_
