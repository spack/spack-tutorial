#!/bin/bash

# Source definitions
project=$(dirname "$0")
. $project/defs.sh

rm -rf $raw_outputs/environments
. $project/init_spack.sh

mkdir -p ~/code
cd ~/code

cat $project/stacks/examples/0.spack.yaml.example > spack.yaml
spack env activate .

example concretize-0 "spack concretize"
example concretize-0 "spack find -c"

cat $project/stacks/examples/1.spack.yaml.example > spack.yaml

example concretize-1 "spack concretize -f"
example concretize-1 "spack find -c"

cat $project/stacks/examples/2.spack.yaml.example > spack.yaml

example concretize-2 "spack concretize"
example concretize-2 "spack find -c"

cat $project/stacks/examples/3.1.spack.yaml.example > spack.yaml

example concretize-3 "spack concretize"
example concretize-3 "spack find -c"

cat $project/stacks/examples/4.spack.yaml.example > spack.yaml

example concretize-4 "spack concretize"
example concretize-4 "spack find -c"
example concretize-4 "export SPACK_STACK_USE_CLANG=1"
export SPACK_STACK_USE_CLANG=1
example concretize-4 "spack concretize"
example concretize-4 "spack find -c"

cat $project/stacks/examples/5.spack.yaml.example > spack.yaml

example view-0       "spack concretize"
example view-0       "ls views/default"
example view-0       "ls view/default/lib"
example view-0       "ls views/full"
example view-0       "ls views/full/zlib"
example view-0       "views/full/zlib/zlib-1.2.11-gcc-7.5.0"
example view-0       "views/full/zlib/zlib-1.2.11-gcc-7.5.0/lib"

cat $project/stacks/examples/6.spack.yaml.example > spack.yaml

example view-1       "spack concretize"
example view-1       "ls views/default"
example view-1       "ls views/full"
