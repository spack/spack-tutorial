#!/bin/bash

# Source definitions
project="$(dirname "$0")"
. "$project/defs.sh"

# clean things up before starting this first script
# rm -rf "$raw_outputs" ~/spack ~/.spack ~/.gnupg

export SPACK_COLOR=never

# Setting Up Spack
example basics/clone           "git clone --depth=2 --branch=$tutorial_branch https://github.com/spack/spack.git ~/spack"
example basics/clone           "cd ~/spack"

cd ~/spack || exit
export SPACK_ROOT=~/spack

. share/spack/setup-env.sh
spack config add "config:suppress_gpg_warnings:true"

example basics/source-setup     ". share/spack/setup-env.sh"

spack repo update

# Installing Packages
example basics/list            "spack list"
example basics/list-py         "spack list 'py-*'"

# spack install
example --tee basics/gmake           "spack install gmake"

example basics/compiler-list   "spack compilers"

example basics/mirror          "spack mirror add --unsigned tutorial /mirror"
#example basics/mirror          "spack buildcache keys --install --trust"

# The Spec Syntax
example basics/versions-zlib  "spack versions zlib-ng"
example --tee basics/zlib-2.0.7       "spack install zlib-ng@2.0.7"

example basics/info-zlib      "spack info --no-dependencies --no-versions zlib-ng"

example --tee basics/zlib-ipo        "spack install zlib-ng +ipo"
example --tee basics/zlib-build-type "spack install zlib-ng build_type=Debug"

example --tee basics/zlib-clang     "spack install zlib-ng %clang"
example --tee basics/zlib-gcc-14    "spack install zlib-ng %gcc@14"

example basics/spec-tcl-zlib-clang  "spack spec -l tcl ^zlib-ng@2.0.7 %clang"
example --tee basics/tcl-zlib-clang "spack install tcl ^zlib-ng@2.0.7 %clang"

# Refer to the zlib-ng@2.0.7 %clang build we just installed by its hash
zlib_hash=$(spack find --format "{hash:3}" zlib-ng@2.0.7 %clang)
example basics/spec-tcl-zlib-hash   "spack spec tcl ^/${zlib_hash}"

example basics/graph-tcl       "spack graph tcl"

example basics/providers-mpi   "spack providers mpi"
example basics/hdf5-spec       "spack spec hdf5"
example --tee basics/hdf5            "spack install hdf5"
example --tee basics/hdf5-no-mpi     "spack install hdf5~mpi"

example --tee basics/hdf5-mpich      "spack install hdf5 ^mpich"
example basics/spec-hdf5-compilers   "spack spec hdf5 %c,cxx=clang %fortran=gcc"

# Querying Installations
example basics/find            "spack find"
example basics/find-l          "spack find -l"
example basics/find-d-tcl      "spack find -d tcl"
example basics/find-dep-mpich  "spack find ^mpich"
example basics/find-px         "spack find -px"

# A Realistic Example
example --tee basics/trilinos        "spack install trilinos"
example --tee basics/trilinos-hdf5   "spack install trilinos +hdf5 ^mpich"
example basics/trilinos-find-mpich   "spack find ^mpich"

# Uninstalling Packages
example basics/find-zlib      "spack find zlib-ng"

example basics/uninstall-zlib "spack uninstall -y zlib-ng %gcc@14"

example basics/find-lf-zlib   "spack find -lf zlib-ng"

zlib_hash="$(spack find --format '{hash:3}' zlib-ng@2.0.7 %clang)"
example --expect-error basics/uninstall-needed "spack uninstall zlib-ng/$zlib_hash"
example basics/uninstall-r-needed "spack uninstall -y -R zlib-ng/$zlib_hash"

example --expect-error basics/uninstall-ambiguous "spack uninstall trilinos"

trilinos_hash="$(spack find --format '{hash:3}' trilinos ^openmpi)"
echo y | example basics/uninstall-specific  "spack uninstall /$trilinos_hash"

# Customizing Compilers
example --tee basics/install-gcc-16   "spack install gcc@16"

example basics/compilers-2           "spack compilers"

example basics/spec-zziplib          "spack spec zziplib %gcc@16"

example basics/compiler-uninstall       'spack uninstall -y gcc@16'
