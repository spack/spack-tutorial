#!/bin/bash

# Source definitions
project=$(dirname "$0")
. $project/defs.sh

rm -rf $raw_outputs/dev
pip install boto3

example dev/up-to-date "git clone https://github.com/spack/spack ~/spack"
example dev/up-to-date "cd ~/spack"
cd ~/spack
example dev/up-to-date "git checkout releases/v0.15"
example dev/up-to-date ". share/spack/setup-env.sh"
. share/spack/setup-env.sh
spack config add "config:suppress_gpg_warnings:true"
spack config add "packages:all:target:[x86_64]"

example dev/up-to-date "spack mirror add tutorial s3://spack-tutorial-container/mirror/"
example dev/up-to-date "spack gpg trust share/spack/keys/tutorial.pub"

example dev/setup-hwloc "cd ~"
cd ~
example dev/setup-hwloc "git clone https://github.com/open-mpi/hwloc.git"
example dev/setup-hwloc "cd hwloc"
cd hwloc

example dev/dev-build-1 "spack dev-build hwloc@master"

example dev/info "spack info hwloc"

echo y | example dev/dev-build-2 "spack uninstall hwloc"
fake_example dev/dev-build-2 "spack dev-build --until configure --drop-in bash hwloc@master" "spack dev-build --until configure hwloc@master"

export EDITOR="bash -c exit 0"
fake_example dev/edit-1 '$EDITOR hwloc/base64.c' "/bin/true"
sed -i~ s'|\("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"\);|\1|' hwloc/base64.c | head -n 70

fake_example dev/hand-build-1 "make" "spack build-env hwloc@master -- make"

fake_example dev/hand-build-2 '$EDITOR hwloc/base64.c' "/bin/true"
sed -i~ s'|\("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"\)|\1;|' hwloc/base64.c | head -n 70
fake_example dev/hand-build-2 "make" "spack build-env hwloc@master -- make"
