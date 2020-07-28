#!/bin/bash

if [ ! -d spack ]; then
    git clone https://github.com/spack/spack
    cd spack
    git checkout releases/v0.15
else
    cd spack
fi

. share/spack/setup-env.sh

spack mirror add tutorial /mirror
spack gpg trust /mirror/public.key
spack config add 'config:suppress_gpg_warnings:true'
