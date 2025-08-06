#!/bin/bash

# Source definitions
name="tutorial"
repo_root="\$HOME/mypkgs"
tutorial_root="$repo_root/spack_repo/$name"
project="$(dirname "$0")"
. "$project/defs.sh"

rm -rf "${raw_outputs:?}/packaging"
. "$project/init_spack.sh"
mpileaks_package_py="$tutorial_root/packages/tutorial_mpileaks/package.py"

export SPACK_COLOR=never

example packaging/repo-create   "spack repo create $repo_root $name"
example packaging/repo-create   "spack repo add $tutorial_root"

# make the editor automatically exit
export EDITOR=true
# use the archive file that has autoreconf
example packaging/create     "spack create --name tutorial-mpileaks https://github.com/LLNL/mpileaks/releases/download/v1.0/mpileaks-1.0.tar.gz"

example packaging/checksum-mpileaks-1  "spack checksum tutorial-mpileaks 1.0"

example --expect-error packaging/install-mpileaks-1  "spack install tutorial-mpileaks"

# This gets a failure ("Error: invalid width -2 (must be > 0)") in CI that
# does not occur when run at the command line.
#cp "$PROJECT/package-py-files/1.package.py" "$mpileaks_package_py"
#example packaging/info-mpileaks       "spack info --phases tutorial-mpileaks"

cp "$PROJECT/package-py-files/2.package.py" "$mpileaks_package_py"
example --expect-error packaging/install-mpileaks-2  "spack install tutorial-mpileaks"

stage_dir="$(spack location -s tutorial-mpileaks)"
example packaging/build-output        "cat $stage_dir/spack-build-out.txt"


prefix=$(spack python -c \
    'import spack.spec; print(spack.spec.Spec("tutorial-mpileaks").concretized().prefix)')

run_configure() (
    spack cd tutorial-mpileaks
    spack build-env tutorial-mpileaks bash
    example --expect-error $PROJECT/packaging/build-env-configure "./configure --prefix=$prefix"
)
run_configure
cd $PROJECT

cp "$PROJECT/package-py-files/3.package.py" "$mpileaks_package_py"
example packaging/install-mpileaks-3  "spack install tutorial-mpileaks"

cp "$PROJECT/package-py-files/4.package.py" "$mpileaks_package_py"
example packaging/install-mpileaks-4  "spack install --verbose tutorial-mpileaks stackstart=4"

example packaging/install-mpileaks-5  "spack uninstall -ay tutorial-mpileaks"
cp "$PROJECT/package-py-files/5.package.py" "$mpileaks_package_py"
example --expect-error packaging/install-mpileaks-5  "spack install --test=root tutorial-mpileaks"

cp "$PROJECT/package-py-files/6.package.py" "$mpileaks_package_py"
example packaging/install-mpileaks-6  "spack install --test=root tutorial-mpileaks"

example packaging/cleanup  "spack uninstall -ay tutorial-mpileaks"
example packaging/cleanup  "spack repo remove $name"
example packaging/cleanup  "rm -rf $repo_root"
