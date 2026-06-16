#!/bin/bash

# Source definitions
project="$(dirname "$0")"
. "$project/defs.sh"

# clean things up before starting this first script
# rm -rf "$raw_outputs" ~/spack ~/.spack ~/.gnupg

export SPACK_COLOR=never

# basic installation
example basics/clone           "git clone --depth=2 --branch=$tutorial_branch https://github.com/spack/spack.git ~/spack"
example basics/clone           "cd ~/spack"

cd ~/spack || exit
export SPACK_ROOT=~/spack

. share/spack/setup-env.sh
spack config add "config:suppress_gpg_warnings:true"

example basics/source-setup     ". share/spack/setup-env.sh"

spack repo update

# spack list
example basics/list            "spack list"
example basics/list-py         "spack list 'py-*'"

# spack install
example --tee basics/gmake           "spack install gmake"

example basics/compiler-list   "spack compilers"

example basics/mirror          "spack mirror add --unsigned tutorial /mirror"
#example basics/mirror          "spack buildcache keys --install --trust"

# NOTE: specs reordered (spec-syntax subsections regrouped; querying moved to its
# own section after the spec syntax; zlib-ng variant examples added; hdf5 moved to
# the virtual-dependencies block). Outputs under outputs/basics/ need regeneration.
example basics/versions-zlib  "spack versions zlib-ng"
example --tee basics/zlib-2.0.7       "spack install zlib-ng@2.0.7"

example --tee basics/zlib-ipo        "spack install zlib-ng +ipo"
example --tee basics/zlib-build-type "spack install zlib-ng build_type=Debug"

example --tee basics/zlib-clang     "spack install zlib-ng %clang"
example --tee basics/zlib-gcc-10    "spack install zlib-ng %gcc@14"

# Capture the hash now, before installing tcl. Installing tcl pulls a
# zlib-ng@2.3.3 %gcc@14 from the build cache as a dependency, which would otherwise
# make this query ambiguous (matching both the cache dependency and our explicit
# %gcc@14 build above).
zlib_hash=$(spack find --format "{hash:3}" zlib-ng %gcc@14)

example --tee basics/tcl            "spack install tcl"
example --tee basics/tcl-zlib-clang "spack install tcl ^zlib-ng@2.0.7 %clang"

example --tee basics/tcl-zlib-hash  "spack install tcl ^/${zlib_hash}"

example basics/find-ldf        "spack find -ldf"

example basics/graph-tcl       "spack graph tcl"

example basics/hdf5-spec       "spack spec hdf5"
example --tee basics/hdf5            "spack install hdf5"
example --tee basics/hdf5-no-mpi     "spack install hdf5~mpi"

example --tee basics/hdf5-hl-mpi     "spack install hdf5+hl+mpi ^mpich"

example basics/find-ldf-2      "spack find -ldf"

example --tee basics/trilinos        "spack install trilinos"

example --tee basics/trilinos-hdf5   "spack install trilinos +hdf5 ^hdf5+hl+mpi ^mpich"

example basics/find-d-trilinos "spack find -d trilinos"

example basics/graph-trilinos  "spack graph trilinos"

# Querying Installations (now its own doc section, after The Spec Syntax)
example basics/find            "spack find"
example basics/find-lf         "spack find -l"
example basics/find-dep-mpich  "spack find ^mpich"
example basics/find-px         "spack find -px"

example basics/find-d-tcl      "spack find -d tcl"

example basics/find-zlib      "spack find zlib-ng"

#example basics/uninstall-zlib "spack uninstall -y zlib-ng %gcc@14"

example basics/find-lf-zlib   "spack find -lf zlib-ng"

zlib_hash="$(spack find --format '{hash:3}' zlib-ng@2.0.7 %clang)"
example --expect-error basics/uninstall-needed "spack uninstall zlib-ng/$zlib_hash"
example basics/uninstall-r-needed "spack uninstall -y -R zlib-ng/$zlib_hash"

example --expect-error basics/uninstall-ambiguous "spack uninstall trilinos"

trilinos_hash="$(spack find --format '{hash:3}' trilinos ^openmpi)"
echo y | example basics/uninstall-specific  "spack uninstall /$trilinos_hash"

example basics/compilers           "spack compilers"

example --tee basics/install-gcc-16   "spack install gcc@16"

example basics/compilers-2           "spack compilers"

example basics/spec-zziplib          "spack spec zziplib %gcc@16"

echo y | example basics/compiler-uninstall       'spack uninstall gcc@16'
