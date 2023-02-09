#!/bin/bash

# Source definitions
project="$(dirname "$0")"
. $project/defs.sh

rm -rf "${raw_outputs:?}/packaging"
. "$project/init_spack.sh"
mpileaks_package_py="$SPACK_ROOT/var/spack/repos/tutorial/packages/tutorial-mpileaks/package.py"

example packaging/repo-add   "spack repo add \$SPACK_ROOT/var/spack/repos/tutorial/"

# make the editor automatically exit
export EDITOR=true
example packaging/create     "spack create --name tutorial-mpileaks https://github.com/LLNL/mpileaks/releases/download/v1.0/mpileaks-1.0.tar.gz"

example packaging/checksum-mpileaks-1  "spack checksum tutorial-mpileaks 1.0"

example packaging/install-mpileaks-1  "spack install tutorial-mpileaks"

cp ${PROJECT}/package-py-files/1.package.py $mpileaks_package_py
example packaging/info-mpileaks       "spack info tutorial-mpileaks"

cp ${PROJECT}/package-py-files/2.package.py $mpileaks_package_py
example packaging/install-mpileaks-2  "spack install tutorial-mpileaks"

stage_dir=$(spack location -s tutorial-mpileaks)
example packaging/build-output        "cat $stage_dir/spack-build-out.txt"

#prefix=$(spack python -c \
#    'import spack.spec; print(spack.spec.Spec("tutorial-mpileaks").concretized().prefix)')
#spack cd tutorial-mpileaks
#echo "configure --prefix=$prefix" | example packaging/build-env-configure "spack build-env tutorial-mpileaks -- bash"

cp ${PROJECT}/package-py-files/3.package.py $mpileaks_package_py
example packaging/install-mpileaks-3  "spack install tutorial-mpileaks"

cp ${PROJECT}/package-py-files/4.package.py $mpileaks_package_py
example packaging/install-mpileaks-4  "spack install --verbose tutorial-mpileaks stackstart=4"

example packaging/cleanup  "spack uninstall -ay tutorial-mpileaks"
example packaging/cleanup  "spack repo remove tutorial"
example packaging/cleanup  "rm -rf \$SPACK_ROOT/var/spack/repos/tutorial/packages/tutorial-mpileaks"
