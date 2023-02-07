#!/usr/bin/bash
cd "${HOME}"
rm -rf "${HOME}/spack"
git clone https://github.com/spack/spack
. spack/share/spack/setup-env.sh
spack tutorial -y
spack clean -m
