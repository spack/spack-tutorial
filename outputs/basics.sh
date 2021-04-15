#!/bin/bash

# Source definitions
project=$(dirname "$0")
. $project/defs.sh

# clean things up before starting this first script
rm -rf $raw_outputs ~/spack ~/.spack ~/.gnupg

# install boto3
pip3 install boto3

# basic installation
example basics/clone         "git clone https://github.com/spack/spack ~/spack"

example basics/checkout      "cd ~/spack"
cd ~/spack
example basics/checkout      "git checkout releases/v0.16"

example basics/source-setup  ". share/spack/setup-env.sh"

# actually source the script (needs to be done in this shell)
. share/spack/setup-env.sh
spack config add "config:suppress_gpg_warnings:true"

# spack list
example basics/list            "spack list"
example basics/list-py         "spack list 'py-*'"

# spack install
example basics/zlib            "spack install zlib"

example basics/mirror          "spack mirror add tutorial s3://spack-binaries-prs/tutorial/ecp21/mirror"
example basics/mirror          "spack buildcache keys -it"

example basics/zlib-clang      "spack install zlib %clang"

example basics/versions-zlib   "spack versions zlib"
example basics/zlib-1.2.8      "spack install zlib@1.2.8"
example basics/zlib-gcc-6.5.0  "spack install zlib %gcc@6.5.0"

example basics/zlib-O3         "spack install zlib @1.2.8 cppflags=-O3"

example basics/find            "spack find"
example basics/find-lf         "spack find -lf"

example basics/tcl             "spack install tcl"

example basics/tcl-zlib-clang  "spack install tcl ^zlib @1.2.8 %clang"

zlib_hash=$(spack find --format "{hash:3}" zlib cppflags=-O3)
example basics/tcl-zlib-hash   "spack install tcl ^/${zlib_hash}"

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

example basics/find-zlib       "spack find zlib"

echo y | example basics/uninstall-zlib  "spack uninstall zlib %gcc@6.5.0"

example basics/find-lf-zlib    "spack find -lf zlib"

zlib_hash=$(spack find --format "{hash:3}" zlib@1.2.8 %clang)
example basics/uninstall-needed "spack uninstall zlib/${zlib_hash}"
echo y | example basics/uninstall-r-needed "spack uninstall -R zlib/${zlib_hash}"

example basics/uninstall-ambiguous "spack uninstall trilinos"

trilinos_hash=$(spack find --format "{hash:3}" trilinos ^openmpi)
echo y | example basics/uninstall-specific  "spack uninstall /${trilinos_hash}"

example basics/find-dep-mpich      "spack find ^mpich"

example basics/find-O3             "spack find cppflags=-O3"

example basics/find-px             "spack find -px"

example basics/compilers           "spack compilers"

example basics/install-gcc-8.3.0   "spack install gcc @8.3.0"

example basics/find-p-gcc          "spack find -p gcc"

example basics/compiler-add-location 'spack compiler add $(spack location -i gcc@8.3.0)'

example basics/compiler-remove       'spack compiler remove gcc@8.3.0'
