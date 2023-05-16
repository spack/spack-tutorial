#!/bin/bash

if [ ! -d ~/spack ]; then
    git clone --quiet "--branch=$tutorial_branch" --depth=100 https://github.com/spack/spack ~/spack
fi

cd ~/spack || exit
. share/spack/setup-env.sh
spack tutorial -y
spack bootstrap now
