#!/bin/bash

if [ ! -d ~/spack ]; then
    git clone --quiet https://github.com/spack/spack ~/spack
    cd ~/spack && git checkout --quiet "$spack_commit"
fi

cd ~/spack || exit
. share/spack/setup-env.sh
spack bootstrap now
