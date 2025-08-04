#!/bin/bash

# Source definitions
project="$(dirname "$0")"
. "$project/defs.sh"

rm -rf "${raw_outputs:?}/stacks"
. "$project/init_spack.sh"
. share/spack/setup-env.sh

spack compiler find
export SPACK_COLOR=never

spack env activate --create ~/stacks
fake_example stacks/setup-0 "spack env activate --create ~/stacks" "/bin/true"
example stacks/setup-0 "spack env status"

example stacks/setup-1 "spack add gcc@12 %gcc@11"
example stacks/setup-1 "spack env view disable"
fake_example stacks/setup-1 "spack config edit" "/bin/true"

example stacks/setup-2 "spack concretize"
example stacks/setup-2 "spack install"

example stacks/compiler-find-0 'spack compiler find "$(spack location -i gcc@12)"'
example stacks/compiler-find-1 "spack location -i gcc@12"

example stacks/compiler-list-0 "spack compiler list"

example stacks/unify-0 "spack add netlib-scalapack %gcc@12 ^openblas ^openmpi"
example stacks/unify-0 "spack add netlib-scalapack %gcc@12 ^openblas ^mpich"

example --expect-error stacks/unify-1 "spack concretize"

example stacks/unify-2 "spack config get concretizer | grep unify"

example stacks/unify-3 "spack config add concretizer:unify:false"
example stacks/unify-3 "spack concretize"

example stacks/unify-4 "spack add netlib-scalapack %gcc@12 ^netlib-lapack ^openmpi"
example stacks/unify-4 "spack add netlib-scalapack %gcc@12 ^netlib-lapack ^mpich"

cat "$project/stacks/examples/2.spack.stack.yaml" > ~/stacks/spack.yaml
example stacks/concretize-0 "spack concretize"
example stacks/concretize-0 "spack install"

example stacks/concretize-01 "spack find"

cat "$project/stacks/examples/3.spack.stack.yaml" > ~/stacks/spack.yaml
example stacks/concretize-1 "spack concretize"
example stacks/concretize-1 "spack find -l"

cat "$project/stacks/examples/4bis.spack.stack.yaml" > ~/stacks/spack.yaml
example stacks/concretize-3 "spack concretize"
example stacks/concretize-3 "spack install"

example stacks/concretize-4 "spack find -ld py-scipy"

cat "$project/stacks/examples/5.spack.stack.yaml" > ~/stacks/spack.yaml
example stacks/concretize-5 "spack concretize"
example stacks/concretize-5 "spack find -cl netlib-scalapack"

example stacks/concretize-6 "export SPACK_STACK_USE_OPENMPI=1"
export SPACK_STACK_USE_OPENMPI=1
fake_example stacks/concretize-6 "spack concretize" "/bin/true"
spack concretize
example stacks/concretize-6 "spack find -cl netlib-scalapack"

cat "$project/stacks/examples/6.spack.stack.yaml" > ~/stacks/spack.yaml

example stacks/view-0       "spack concretize"
example stacks/view-0       "ls ~/stacks/views/default"
example stacks/view-0       "ls ~/stacks/views/default/lib"
example stacks/view-0       "ls ~/stacks/views/full"
example stacks/view-0       "ls ~/stacks/views/full/gcc-12.3.0"

cat "$project/stacks/examples/7.spack.stack.yaml" > ~/stacks/spack.yaml

example stacks/view-1       "spack concretize"
example stacks/view-1       "ls ~/stacks/views/default"
example stacks/view-1       "ls ~/stacks/views/default/lib"
example stacks/view-1       "ls ~/stacks/views/full"

example stacks/modules-0 "spack add lmod@8.7.18 %gcc@11"
example stacks/modules-0 "spack concretize"
example stacks/modules-0 "spack install"

. "$(spack location -i lmod)/lmod/lmod/init/bash"

example --tee stacks/modules-1 "module --version"

cat "$project/stacks/examples/8.spack.stack.yaml" > ~/stacks/spack.yaml
spack module lmod refresh -y
module use "$HOME/stacks/modules/linux-ubuntu22.04-x86_64/Core"

example --tee stacks/modules-2 "module av"

example --tee stacks/modules-3 "module load gcc"
module load gcc
example stacks/modules-3 "which gcc"
example stacks/modules-3 "gcc --version"
example --tee stacks/modules-3 "module av"

example --tee stacks/modules-3 "module unload gcc"
module unload gcc

cat "$project/stacks/examples/9.spack.stack.yaml" > ~/stacks/spack.yaml
example stacks/modules-4 "spack module lmod refresh --delete-tree -y"

example --tee stacks/modules-5 "module load gcc"
module load gcc
example --tee stacks/modules-5 "module load openmpi openblas netlib-scalapack py-scipy"
example --tee stacks/modules-5 "module av"
module load openmpi openblas netlib-scalapack
example --tee stacks/modules-5 "module load mpich"
module load mpich
example --tee stacks/modules-5 "module load netlib-lapack"
module load netlib-lapack
example --tee stacks/modules-5 "module purge"
module purge
