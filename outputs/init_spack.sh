#!/bin/bash

if [ ! -d ~/spack ]; then
    git clone --quiet "--branch=$tutorial_branch" --depth=100 https://github.com/spack/spack ~/spack
fi

cd ~/spack || exit
. share/spack/setup-env.sh
spack tutorial -y
spack bootstrap now

pip install --quiet boto3
spack config add 'config:suppress_gpg_warnings:true'
spack config add 'packages:all:target:[x86_64]'
