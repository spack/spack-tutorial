#!/bin/bash

# Source definitions
project=$(dirname "$0")
. $project/defs.sh

rm -rf $raw_outputs/stacks
. $project/init_spack.sh
. share/spack/setup-env.sh

spack install zlib%clang
spack install trilinos+hdf5 ^mpich
spack install openmpi

mkdir -p ~/code
example stacks/setup-0 "cd ~/code"
cd ~/code

cat $project/stacks/examples/0.spack.yaml.example > spack.yaml
fake_example stacks/setup-0 "spack env activate ." ". /home/spack/spack/share/spack/setup-env.sh && spack env activate ."
spack env activate .

fake_example stacks/setup-0 "spack config edit" "/bin/true"

example stacks/concretize-0 "spack concretize"
example stacks/concretize-0 "spack find -c"

cat $project/stacks/examples/1.spack.yaml.example > spack.yaml

example stacks/concretize-1 "spack concretize -f"
example stacks/concretize-1 "spack find -c"

cat $project/stacks/examples/2.spack.yaml.example > spack.yaml

example stacks/concretize-2 "spack concretize -f"
example stacks/concretize-2 "spack find -c"

cat $project/stacks/examples/3.1.spack.yaml.example > spack.yaml

example stacks/concretize-3 "spack concretize -f"
example stacks/concretize-3 "spack find -c"

cat $project/stacks/examples/4.spack.yaml.example > spack.yaml

example stacks/concretize-4 "spack concretize -f"
example stacks/concretize-4 "spack find -c"
example stacks/concretize-4 "export SPACK_STACK_USE_CLANG=1"
export SPACK_STACK_USE_CLANG=1
example stacks/concretize-4 "spack concretize -f"
example stacks/concretize-4 "spack find -c"

cat $project/stacks/examples/5.spack.yaml.example > spack.yaml

example stacks/view-0       "spack concretize"
example stacks/view-0       "ls views/default"
example stacks/view-0       "ls views/default/lib"
example stacks/view-0       "ls views/full"
example stacks/view-0       "ls views/full/zlib"
example stacks/view-0       "ls views/full/zlib/zlib-1.2.13-gcc-7.5.0"
example stacks/view-0       "ls views/full/zlib/zlib-1.2.13-gcc-7.5.0/lib"

cat $project/stacks/examples/6.spack.yaml.example > spack.yaml

example stacks/view-1       "spack concretize"
example stacks/view-1       "ls views/default"
example stacks/view-1       "ls views/default/lib"
example stacks/view-1       "ls views/full"
