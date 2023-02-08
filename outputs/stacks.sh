#!/bin/bash

# Source definitions
project=$(dirname "$0")
. $project/defs.sh

rm -rf $raw_outputs/stacks
. $project/init_spack.sh
. share/spack/setup-env.sh

example stacks/setup-0 "mkdir -p ~/stacks && cd ~/stacks"
mkdir -p ~/stacks && cd ~/stacks
spack compiler find

example stacks/setup-0 "spack env create -d ."
spack env create -d .
fake_example stacks/setup-0 "spack env activate ." ". /home/spack/spack/share/spack/setup-env.sh && spack env activate ."
spack env activate .
example stacks/setup-0 "spack add gcc@8.4.0 %gcc@7.5.0"

cat $project/stacks/examples/0.spack.stack.yaml > spack.yaml

fake_example stacks/setup-0 "spack config edit" "/bin/true"

spack concretize
spack install
example stacks/compiler-find-0 "spack location -i gcc"
example stacks/compiler-find-0 "spack compiler find $(spack location -i gcc)"
example stacks/compiler-list-0 "spack compiler list"

cat $project/stacks/examples/2.spack.stack.yaml > spack.yaml
example stacks/concretize-0 "spack concretize -f"
example stacks/concretize-0 "spack install"
example stacks/concretize-0 "spack find"

cat $project/stacks/examples/3.spack.stack.yaml > spack.yaml
spack concretize -f
spack install
example stacks/concretize-1 "spack find -l py-scipy"

cat $project/stacks/examples/5.spack.stack.yaml > spack.yaml
example stacks/concretize-2 "spack concretize -f"
example stacks/concretize-2 "spack find -c"

example stacks/concretize-3 "export SPACK_STACK_USE_OPENMPI=1"
export SPACK_STACK_USE_OPENMPI=1
example stacks/concretize-3 "spack concretize -f"
example stacks/concretize-3 "spack find -c"

cat $project/stacks/examples/6.spack.stack.yaml > spack.yaml

example stacks/view-0       "spack concretize"
example stacks/view-0       "ls views/default"
example stacks/view-0       "ls views/default/lib"
example stacks/view-0       "ls views/full"
example stacks/view-0       "ls views/full/gcc-8.4.0"

cat $project/stacks/examples/7.spack.stack.yaml > spack.yaml

example stacks/view-1       "spack concretize"
example stacks/view-1       "ls views/default"
example stacks/view-1       "ls views/default/lib"
example stacks/view-1       "ls views/full"
