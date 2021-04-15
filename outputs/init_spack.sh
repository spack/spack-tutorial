#!/bin/bash

if [ ! -d ~/spack ]; then
    git clone https://github.com/spack/spack ~/spack
    cd ~/spack
    git checkout releases/v0.16
else
    cd ~/spack
fi

. share/spack/setup-env.sh

pip install boto3
spack mirror add tutorial /mirror
spack buildcache keys --install --trust
spack config add 'config:suppress_gpg_warnings:true'
spack config add 'packages:all:target:[x86_64]'
