#!/bin/bash

# Source definitions
project="$(dirname "$0")"
. "$project/defs.sh"

# clean things up before starting this first script
# rm -rf "$raw_outputs" ~/spack ~/.spack ~/.gnupg

# basic installation
example basics/clone           "git clone --depth=100 --branch=$tutorial_branch https://github.com/spack/spack.git ~/spack"
example basics/clone           "cd ~/spack"

cd ~/spack || exit
. share/spack/setup-env.sh
spack config add "config:suppress_gpg_warnings:true"

example basics/source-setup     ". share/spack/setup-env.sh"

# spack list
example basics/list            "spack list"
example basics/list-py         "spack list 'py-*'"

# spack install
example basics/gmake           "spack install gmake"

example basics/mirror          "spack mirror add tutorial /mirror"
example basics/mirror          "spack buildcache keys --install --trust"

example basics/gmake-clang     "spack install gmake %clang"

example basics/versions-gmake  "spack versions gmake"
example basics/gmake-4.3       "spack install gmake@4.3"
example basics/gmake-gcc-10    "spack install gmake %gcc@10"

example basics/gmake-O3        "spack install gmake@4.3 cflags=-O3"

example basics/find            "spack find"
example basics/find-lf         "spack find -lf"

example basics/tcl             "spack install tcl"

example basics/tcl-gmake-clang "spack install tcl ^gmake@4.3 %clang"

gmake_hash=$(spack find --format "{hash:3}" gmake cflags=-O3)
example basics/tcl-gmake-hash  "spack install tcl ^/${gmake_hash}"

example basics/find-ldf        "spack find -ldf"

example basics/hdf5            "spack install hdf5"
example basics/hdf5-no-mpi     "spack install hdf5~mpi"

example basics/hdf5-hl-mpi     "spack install hdf5+hl+mpi ^mpich"

example basics/find-ldf-2      "spack find -ldf"

example basics/graph-hdf5      "spack graph hdf5+hl+mpi ^mpich"

example basics/trilinos        "spack install trilinos"

example basics/trilinos-hdf5   "spack install trilinos +hdf5 ^hdf5+hl+mpi ^mpich"

example basics/find-d-trilinos "spack find -d trilinos"

example basics/graph-trilinos  "spack graph trilinos"

example basics/find-d-tcl      "spack find -d tcl"

example basics/find-gmake      "spack find gmake"

example basics/uninstall-gmake "spack uninstall -y gmake %gcc@10"

example basics/find-lf-gmake   "spack find -lf gmake"

gmake_hash="$(spack find --format '{hash:3}' gmake@4.3 %clang)"
example --expect-error basics/uninstall-needed "spack uninstall gmake/$gmake_hash"
example basics/uninstall-r-needed "spack uninstall -y -R gmake/$gmake_hash"

example --expect-error basics/uninstall-ambiguous "spack uninstall trilinos"

trilinos_hash="$(spack find --format '{hash:3}' trilinos ^openmpi)"
echo y | example basics/uninstall-specific  "spack uninstall /$trilinos_hash"

example basics/find-dep-mpich      "spack find ^mpich"

example basics/find-O3             "spack find cflags=-O3"

example basics/find-px             "spack find -px"

example basics/compilers           "spack compilers"

example basics/install-gcc-12.1.0   "spack install gcc@12"

example basics/find-p-gcc          "spack find -p gcc"

example basics/compiler-add-location 'spack compiler add "$(spack location -i gcc@12)"'

example basics/compiler-remove       'spack compiler remove gcc@12'
