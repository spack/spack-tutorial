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

# Simple compiler-only environment (before introducing spec groups)
cat "$project/stacks/examples/compiler.spack.stack.yaml" > ~/stacks/spack.yaml
example stacks/compiler-0 "spack concretize"
example --tee stacks/compiler-0 "spack install"

# Spec groups section: one spec with explicit %gcc@16
cat "$project/stacks/examples/groups-0.spack.stack.yaml" > ~/stacks/spack.yaml
example stacks/groups-0 "spack concretize"

# Introduce override: same spec without %gcc@16 (no output captured)
cat "$project/stacks/examples/groups-1.spack.stack.yaml" > ~/stacks/spack.yaml

# Tuning concretizer section: load yaml with two conflicting specs
example stacks/unify-2 "spack config get concretizer | grep unify"

cat "$project/stacks/examples/1.spack.stack.yaml" > ~/stacks/spack.yaml
example stacks/unify-3 "spack concretize"

# Spec matrices section
cat "$project/stacks/examples/2.spack.stack.yaml" > ~/stacks/spack.yaml
example stacks/concretize-0 "spack concretize"

# Reusable definitions section
cat "$project/stacks/examples/3.spack.stack.yaml" > ~/stacks/spack.yaml
example stacks/concretize-1 "spack concretize"

# py-scipy with exclude
cat "$project/stacks/examples/4bis.spack.stack.yaml" > ~/stacks/spack.yaml
example stacks/concretize-3 "spack concretize"

# Conditional definitions section
cat "$project/stacks/examples/5.spack.stack.yaml" > ~/stacks/spack.yaml
example stacks/concretize-5 "spack concretize"
example stacks/concretize-5 "spack find -cl netlib-scalapack"

example stacks/concretize-6 "export SPACK_STACK_USE_OPENMPI=1"
export SPACK_STACK_USE_OPENMPI=1
fake_example stacks/concretize-6 "spack concretize" "/bin/true"
spack concretize
example stacks/concretize-6 "spack find -cl netlib-scalapack"

# Install the full stack
example --tee stacks/install-0 "spack install"

# Environment Views section
cat "$project/stacks/examples/6.spack.stack.yaml" > ~/stacks/spack.yaml

example stacks/view-0       "spack concretize"
example stacks/view-0       "ls ~/stacks/views/default"
example stacks/view-0       "ls ~/stacks/views/default/lib"
example stacks/view-0       "ls ~/stacks/views/full"
example stacks/view-0       "ls ~/stacks/views/full/gcc/"
gcc_dir=$(ls ~/stacks/views/full/gcc/ | head -1)
example stacks/view-0       "ls ~/stacks/views/full/gcc/$gcc_dir"

cat "$project/stacks/examples/7.spack.stack.yaml" > ~/stacks/spack.yaml

example stacks/view-1       "spack concretize"
example stacks/view-1       "ls ~/stacks/views/default"
example stacks/view-1       "ls ~/stacks/views/default/lib"
example stacks/view-1       "ls ~/stacks/views/full"

# Module Files section: lmod is already installed as part of the compiler group
. "$(spack location -i lmod)/lmod/lmod/init/bash"

example --tee stacks/modules-1 "module --version"

cat "$project/stacks/examples/8.spack.stack.yaml" > ~/stacks/spack.yaml
spack module lmod refresh -y
module use "$HOME/stacks/modules/linux-ubuntu26.04-x86_64/Core"

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
