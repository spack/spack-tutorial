.. admonition:: Tutorial setup

   If you have not done the prior sections, you'll need to start the docker image::

       docker run -it ghcr.io/spack/tutorial:sc24

   and then set Spack up like this::

       git clone --depth=100 --branch=releases/v0.23 https://github.com/spack/spack
       . spack/share/spack/setup-env.sh
       spack tutorial -y
       spack bootstrap now
       spack compiler find

   See the :ref:`basics-tutorial` for full details on setup. For more
   help, join us in the ``#tutorial`` channel on Slack -- get an
   invitation at `slack.spack.io <https://slack.spack.io/>`_
