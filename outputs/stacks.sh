#!/bin/bash

# Source definitions
project="$(dirname "$0")"
. "$project/defs.sh"

rm -rf "${raw_outputs:?}/stacks"
. "$project/init_spack.sh"
. share/spack/setup-env.sh

example stacks/setup-0 "mkdir -p ~/stacks && cd ~/stacks"
mkdir -p ~/stacks && cd ~/stacks || exit
spack compiler find

example stacks/setup-0 "spack env create -d ."
spack env create -d .
fake_example stacks/setup-0 "spack env activate ." ". /home/spack/spack/share/spack/setup-env.sh && spack env activate ."
spack env activate .
example stacks/setup-0 "spack add gcc@8.4.0 %gcc@7.5.0"

cat "$project/stacks/examples/0.spack.stack.yaml" > spack.yaml

fake_example stacks/setup-0 "spack config edit" "/bin/true"

spack concretize
spack install
example stacks/compiler-find-0 "spack location -i gcc"
example stacks/compiler-find-0 'spack compiler find "$(spack location -i gcc)"'
example stacks/compiler-list-0 "spack compiler list"

cat "$project/stacks/examples/2.spack.stack.yaml" > spack.yaml
example stacks/concretize-0 "spack concretize -f"
example stacks/concretize-0 "spack install"
example stacks/concretize-0 "spack find"

cat "$project/stacks/examples/3.spack.stack.yaml" > spack.yaml
spack concretize -f
spack install
example stacks/concretize-1 "spack find -l py-scipy"

cat "$project/stacks/examples/5.spack.stack.yaml" > spack.yaml
example stacks/concretize-2 "spack concretize -f"
example stacks/concretize-2 "spack find -c"

example stacks/concretize-3 "export SPACK_STACK_USE_OPENMPI=1"
export SPACK_STACK_USE_OPENMPI=1
example stacks/concretize-3 "spack concretize -f"
example stacks/concretize-3 "spack find -c"

cat "$project/stacks/examples/6.spack.stack.yaml" > spack.yaml

example stacks/view-0       "spack concretize"
example stacks/view-0       "ls views/default"
example stacks/view-0       "ls views/default/lib"
example stacks/view-0       "ls views/full"
example stacks/view-0       "ls views/full/gcc-8.4.0"

cat "$project/stacks/examples/7.spack.stack.yaml" > spack.yaml

example stacks/view-1       "spack concretize"
example stacks/view-1       "ls views/default"
example stacks/view-1       "ls views/default/lib"
example stacks/view-1       "ls views/full"

example stacks/modules-0 "spack add lmod%gcc@7.5.0"
example stacks/modules-0 "spack concretize"
example stacks/modules-0 "spack install"

. "$(spack location -i lmod)/lmod/lmod/init/bash"

example --tee stacks/modules-1 "module --version"

cat "$project/stacks/examples/8.spack.stack.yaml" > spack.yaml
spack module lmod refresh -y
module use "$PWD/modules/linux-ubuntu18.04-x86_64/Core"

example --tee stacks/modules-2 "module av"

example --tee stacks/modules-3 "module load gcc"
module load gcc
example stacks/modules-3 "which gcc"
example stacks/modules-3 "gcc --version"
example --tee stacks/modules-3 "module av"

example --tee stacks/modules-3 "module unload gcc"
module unload gcc

cat "$project/stacks/examples/9.spack.stack.yaml" > spack.yaml
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
