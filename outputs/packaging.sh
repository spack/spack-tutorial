#!/bin/bash

# TODO: Need to resolve duplication of #.package.py files in 
# TODO:   /project/package-py-files (mounted in the container)
# TODO:   and tutorial/examples/packaging (referenced in tutorial)

# Source definitions
project=$(dirname "$0")
. $project/defs.sh

rm -rf $raw_outputs/packaging
. $project/init_spack.sh
mympileaks_package_py=$SPACK_ROOT/var/spack/repos/tutorial/packages/mympileaks/package.py

example packaging/repo-add   "spack repo add \$SPACK_ROOT/var/spack/repos/tutorial/"

# make the editor automatically exit
export EDITOR="bash -c exit 0"
example packaging/create     "spack create --name mympileaks --skip-editor https://github.com/LLNL/mpileaks/releases/download/v1.0/mpileaks-1.0.tar.gz"

example packaging/checksum-mympileaks-1  "spack checksum mympileaks 1.0"

example packaging/install-mympileaks-1  "spack install mympileaks"

cp ${PROJECT}/package-py-files/1.package.py $mympileaks_package_py
example packaging/info-mympileaks       "spack info -a mympileaks"

spack uninstall -ay mympileaks
cp ${PROJECT}/package-py-files/2.package.py $mympileaks_package_py
example packaging/install-mympileaks-2  "spack install mympileaks"

stage_dir=$(spack location -s mympileaks)
example packaging/build-output        "cat $stage_dir/spack-build-out.txt"

#prefix=$(spack python -c \
#    'import spack.spec; print(spack.spec.Spec("mympileaks").concretized().prefix)')
#spack cd mympileaks
#echo "configure --prefix=$prefix" | example packaging/build-env-configure "spack build-env mympileaks bash"

cp ${PROJECT}/package-py-files/3.package.py $mympileaks_package_py
example packaging/install-mympileaks-3  "spack install mympileaks"

cp ${PROJECT}/package-py-files/4.package.py $mympileaks_package_py
example packaging/install-mympileaks-4  "spack install --verbose mympileaks stackstart=4"

example packaging/cleanup  "spack uninstall -ay mympileaks"
example packaging/cleanup  "spack repo remove tutorial"
example packaging/cleanup  "rm -rf \$SPACK_ROOT/var/spack/repos/tutorial/packages/mympileaks"
