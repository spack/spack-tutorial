#!/bin/bash

if [ ! -d ~/spack ]; then
    git clone https://github.com/spack/spack ~/spack
    cd ~/spack
    git checkout ${tutorial_branch}
else
    cd ~/spack
fi

. share/spack/setup-env.sh
spack tutorial -y
spack bootstrap now

pip install boto3
spack mirror add tutorial /mirror
spack config add 'config:suppress_gpg_warnings:true'
spack config add 'packages:all:target:[x86_64]'
