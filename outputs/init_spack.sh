#!/bin/bash

. $project/init_vars.sh

if [ ! -d ~/spack ]; then
    git clone https://github.com/spack/spack ~/spack
    cd ~/spack
    git checkout ${tutorial_branch}
else
    cd ~/spack
fi

. share/spack/setup-env.sh

# install boto3 (pre-v0.17.0)
pip3 install boto3

spack mirror add tutorial ${tutorial_mirror}
spack buildcache keys --install --trust
. $project/init_config.sh
