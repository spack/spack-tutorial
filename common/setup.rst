.. admonition:: Tutorial setup

   If you have not done the prior sections, you'll need to start the docker image::

       docker run -it ghcr.io/spack/tutorial:hpcic25

   and then set Spack up like this::

       git clone --depth=2 --branch=releases/v1.0 https://github.com/spack/spack
       . spack/share/spack/setup-env.sh
       spack repo update builtin --tag v2025.07.0
       spack mirror add --unsigned tutorial /mirror
       spack compiler find

   See the :ref:`basics-tutorial` for full details on setup.
   For more help, join us in the ``#tutorial`` channel on Slack -- get an invitation at `slack.spack.io <https://slack.spack.io/>`_

   .. warning::

      The ``spack tutorial -y`` command is intended for use in a container or VM.
      Use with care in other environments since it replaces some configuration files in order to establish suitable settings for the tutorial.
