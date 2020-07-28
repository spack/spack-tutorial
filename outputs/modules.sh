#!/bin/bash

# Source definitions
project=$(dirname "$0")
. $project/defs.sh

rm -rf $raw_outputs/modules
. $project/init_spack.sh

spack install lmod
. $(spack location -i lmod)/lmod/lmod/init/bash
. share/spack/setup-env.sh
spack install gcc@8.3.0
spack load gcc@8.3.0

example modules/show-loaded   "spack find --loaded"

example modules/add-compiler  "spack compiler add"
example modules/add-compiler  "spack compiler list"

spack install netlib-scalapack ^openmpi ^openblas
spack install netlib-scalapack ^mpich ^openblas
spack install netlib-scalapack ^openmpi ^netlib-lapack
spack install netlib-scalapack ^mpich ^netlib-lapack
spack install py-scipy ^openblas

example modules/module-avail-1 "module avail"

gcc_hash=$(spack find --format {hash:7} gcc)
gcc_module="gcc-8.3.0-gcc-7.5.0-${gcc_hash}"

example modules/module-show-1  "module show $gcc_module"

spack config add modules:tcl:all:filter:environment_blacklist:['CPATH', 'LIBRARY_PATH']

echo "y
" | example modules/tcl-refresh-1 "spack module tcl refresh"

example modules/module-show-2  "module show $gcc_module"

spack config add modules:tcl:blacklist:['%gcc@7.5.0']

echo "y
" | example modules/tcl-refresh-2 "spack module tcl refresh --delete-tree"
example modules/tcl-refresh-2     "module avail"

spack config add modules:tcl:whitelist:[gcc]

example modules/tcl-refresh-3     "spack module tcl refresh -y"

example modules/module-avail-2    "module avail $gcc_module"

spack config add modules:tcl:hash_length:0

example modules/tcl-refresh-4     "spack module tcl refresh --delete-tree -y"

spack config add modules:tcl:projections:all:'{name}/{version}-{compiler.name}-{compiler.version}'
spack config add modules:tcl:projections:'^mpi^lapack':'{name}/{version}-{compiler.name}-{compiler.version}-{^lapack.name}-{^mpi.version}'
spack config add modules:tcl:projections:'^lapack':'{name}/{version}-{compiler.name}-{compiler.version}-{^lapack.name}'
spack config add modules:tcl:projections:'^mpi':'{name}/{version}-{compiler.name}-{compiler.version}-{^mpi.name}'
spack config add modules:tcl:all:conflict:['{name}']

example modules/tcl-refresh-5     "spack module tcl refresh --delete-tree -y"
example modules/tcl-refresh-5     "module avail"

spack config add "modules:tcl:all:environment:set:'{name}_ROOT':'{prefix}'"

example modules/tcl-refresh-6     "spack module tcl refresh -y"
example modules/tcl-refresh-6     "module show gcc"

spack config add modules:tcl:openmpi:environment:set:SLURM_MPI_TYPE:pmi2
spack config add "modules:tcl:openmpi:environment:set:OMPI_MCA_btl_openib_warn_default_git_prefix:'0'"

example modules/tcl-refresh-7     "spack module tcl refresh -y openmpi"
example modules/tcl-refresh-7     "module show openmpi"

spack config add modules:tcl:verbose:true
spack config add modules:tcl:^python:autoload:direct

example modules/tcl-refresh-8     "spack module tcl refresh -y ^python"

example modules/load-direct       "module load py-scipy"
