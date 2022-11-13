#!/bin/bash

# Source definitions
project=$(dirname "$0")
. $project/defs.sh

rm -rf $raw_outputs/packaging
. $project/init_spack.sh
mpileaks_package_py=$SPACK_ROOT/var/spack/repos/tutorial/packages/mpileaks/package.py

example packaging/repo-add   "spack repo add \$SPACK_ROOT/var/spack/repos/tutorial/"
example packaging/repo-add   "spack config add concretizer:enable_node_namespace:true"

# make the editor automatically exit
export EDITOR="bash -c exit 0"
example packaging/create     "spack create --skip-editor https://github.com/LLNL/mpileaks/releases/download/v1.0/mpileaks-1.0.tar.gz"

example packaging/checksum-mpileaks-1  "spack checksum mpileaks 1.0"

example packaging/install-mpileaks-1  "spack install tutorial.mpileaks"

cp ${PROJECT}/package-py-files/1.package.py $mpileaks_package_py
example packaging/info-mpileaks       "spack info mpileaks"

spack uninstall -ay mpileaks
cp ${PROJECT}/package-py-files/2.package.py $mpileaks_package_py
example packaging/install-mpileaks-2  "spack install tutorial.mpileaks"

stage_dir=$(spack location -s tutorial.mpileaks)
example packaging/build-output        "cat $stage_dir/spack-build-out.txt"

#prefix=$(spack python -c \
#    'import spack.spec; print(spack.spec.Spec("mpileaks").concretized().prefix)')
#spack cd mpileaks
#echo "configure --prefix=$prefix" | example packaging/build-env-configure "spack build-env mpileaks bash"

cp ${PROJECT}/package-py-files/3.package.py $mpileaks_package_py
example packaging/install-mpileaks-3  "spack install tutorial.mpileaks"

cp ${PROJECT}/package-py-files/4.package.py $mpileaks_package_py
example packaging/install-mpileaks-4  "spack install --verbose tutorial.mpileaks stackstart=4"

example packaging/cleanup  "spack uninstall -ay mpileaks"
example packaging/cleanup  "spack repo remove tutorial"
example packaging/cleanup  "spack config remove concretizer:enable_node_namespace:true"
example packaging/cleanup  "rm -rf \$SPACK_ROOT/var/spack/repos/tutorial/packages/mpileaks"
