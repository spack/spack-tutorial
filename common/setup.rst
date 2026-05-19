.. admonition:: Tutorial setup

   If you have not done the prior sections, you'll need to start the docker image::

       docker pull ghcr.io/spack/tutorial:cineca26
       docker run -it ghcr.io/spack/tutorial:cineca26

   and then set Spack up like this::

       git clone --depth=2 --branch=workshops/cineca26 https://github.com/spack/spack
       . spack/share/spack/setup-env.sh
       spack mirror add --unsigned tutorial /buildcache

