#!/bin/bash

# Source definitions
project="$(dirname "$0")"
. "$project/defs.sh"

rm -rf "${raw_outputs:?}/modules"
. "$project/init_spack.sh"

# reinit modules
rm -f ~/.spack/modules.yaml ~/.spack/linux/modules.yaml
rm -f ~/.spack/compilers.yaml ~/.spack/linux/compilers.yaml
spack config add "modules:default:enable:[tcl]"
spack module tcl refresh -y

#
# Initial setup (no output)
#
spack uninstall -ay

spack install lmod

. "$(spack location -i lmod)/lmod/lmod/init/bash"
. share/spack/setup-env.sh
spack install gcc@12

example --tee modules/spack-load-gcc "spack load gcc@12"
spack load gcc@12
example      modules/spack-load-gcc "which gcc"

example      modules/add-compiler   "spack compiler add"
example      modules/list-compiler  "spack compiler list"

example      modules/show-loaded    "spack find --loaded"
example --tee modules/module-avail-1 "module avail"


spack install netlib-scalapack ^openmpi ^openblas
spack install netlib-scalapack ^mpich ^openblas
spack install netlib-scalapack ^openmpi ^netlib-lapack
spack install netlib-scalapack ^mpich ^netlib-lapack
spack install py-scipy ^openblas

example --tee modules/module-avail-2 "module avail"

gcc_hash="$(spack find --format '{hash:7}' gcc)"
gcc_module="gcc/12.3.0-gcc-11.4.0-${gcc_hash}"
example --tee modules/module-show-1  "module show $gcc_module"

spack config add "modules:default:tcl:all:filter:exclude_env_vars:['C_INCLUDE_PATH', 'CPLUS_INCLUDE_PATH', 'LIBRARY_PATH']"

example  modules/tcl-refresh-1          "spack module tcl refresh -y"
example --tee modules/module-show-2     "module show $gcc_module"


spack config add                        "modules:default:tcl:exclude:['%gcc@11']"
example      modules/tcl-refresh-2      "spack module tcl refresh --delete-tree -y"
example --tee modules/module-avail-3    "module avail"


spack config add                        "modules:default:tcl:include:[gcc]"
example      modules/tcl-refresh-3      "spack module tcl refresh -y"
example --tee modules/module-avail-4    "module avail $gcc_module"


spack config add                        "modules:default:tcl:hash_length:0"
example --expect-error modules/tcl-refresh-4           "spack module tcl refresh --delete-tree -y"


# use new projections
spack config add                        "modules:default:tcl:projections:all:'{name}/{version}-{compiler.name}-{compiler.version}'"
spack config add                        "modules:default:tcl:projections:netlib-scalapack:'{name}/{version}-{compiler.name}-{compiler.version}-{^lapack.name}-{^mpi.name}'"
spack config add                        "modules:default:tcl:projections:^python^lapack:'{name}/{version}-{compiler.name}-{compiler.version}-{^lapack.name}'"
spack config add                        "modules:default:tcl:all:conflict:['{name}']"
example      modules/tcl-refresh-5      "spack module tcl refresh --delete-tree -y"
example --tee modules/module-avail-5    "module avail"


spack config add                        "modules:default:tcl:all:environment:set:\"{name}_ROOT\":\"{prefix}\""
example      modules/tcl-refresh-6      "spack module tcl refresh -y"
example --tee modules/module-show-3     "module show gcc"


spack config add                        "modules:default:tcl:openmpi:environment:set:SLURM_MPI_TYPE:pmi2"
spack config add                        "modules:default:tcl:openmpi:environment:set:OMPI_MCA_btl_openib_warn_default_git_prefix:'0'"
example      modules/tcl-refresh-7      "spack module tcl refresh -y openmpi"
example --tee modules/module-show-4     "module show openmpi"


spack config add                        "modules:default:tcl:verbose:true"
spack config add                        "modules:default:tcl:^python:autoload:direct"
example      modules/tcl-refresh-8      "spack module tcl refresh -y ^python"
example --tee modules/load-direct       "module load py-scipy"


# Lmod stuff

example --tee modules/lmod-intro-avail     "module avail"


example --tee modules/lmod-intro-conflict  "module purge"
module purge
example --tee modules/lmod-intro-conflict  "module load netlib-lapack openblas"
module load netlib-lapack openblas
example --tee modules/lmod-intro-conflict  "module list"


cp "$PROJECT/module-configs/lmod.1.yaml" ~/.spack/modules.yaml
example      modules/lmod-refresh-1     "spack module lmod refresh --delete-tree -y"
module purge
module unuse "$HOME/spack/share/spack/modules/linux-ubuntu22.04-x86_64_v3"
module use "$HOME/spack/share/spack/lmod/linux-ubuntu22.04-x86_64/Core"
example --tee modules/module-avail-6     "module avail"


example --tee modules/module-avail-7     "module load gcc"
module load gcc
example --tee modules/module-avail-7     "module avail"


example --tee modules/module-avail-8     "module load mpich"
module load mpich
example --tee modules/module-avail-8     "module avail"

example --tee modules/module-load-openblas-scalapack    "module load openblas netlib-scalapack/2.2.0-openblas"
module load openblas netlib-scalapack/2.2.0-openblas
example --tee modules/module-load-openblas-scalapack    "module list"

export LMOD_AUTO_SWAP=yes
example --tee modules/module-swap-mpi    "export LMOD_AUTO_SWAP=yes"
example --tee modules/module-swap-mpi    "module load openmpi"
module load openmpi


example --tee modules/lapack-conflict    "module list"
example --tee modules/lapack-conflict    "module avail"
example --tee modules/lapack-conflict    "module load netlib-scalapack/2.2.0-netlib-lapack"
module load netlib-scalapack/2.2.0-netlib-lapack
example --tee modules/lapack-conflict    "module list"


cp "$PROJECT/module-configs/lmod.2.yaml" ~/.spack/modules.yaml
example --tee modules/lmod-refresh-2    "module purge"
example --tee modules/lmod-refresh-2    "spack module lmod refresh --delete-tree -y"


example --tee modules/lapack-hier       "module load gcc"
module load gcc
example --tee modules/lapack-hier       "module load openblas"
module load openblas
example --tee modules/lapack-hier       "module avail"
example --tee modules/lapack-hier       "module load openmpi"
module load openmpi
example --tee modules/lapack-hier       "module avail"


example --tee modules/lapack-correct    "module load py-numpy netlib-scalapack"
module load py-numpy netlib-scalapack
example --tee modules/lapack-correct    "module load mpich"
module load mpich
example --tee modules/lapack-correct    "module load netlib-lapack"
