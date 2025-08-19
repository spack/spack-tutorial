#!/bin/bash

# Source definitions
dir="my_pkgs"
# Use \$HOME to make copying-and-pasting from the examples easier in most cases
repo_root="\$HOME/$dir"
name="tutorial"
tutorial_subdir="spack_repo/$name"

project="$(dirname "$0")"
. "$project/defs.sh"

rm -rf "${raw_outputs:?}/packaging"
. "$project/init_spack.sh"
# Cannot use \$HOME (in CI)
mpileaks_package_py="$HOME/$dir/$tutorial_subdir/packages/tutorial_mpileaks/package.py"

export SPACK_COLOR=never

# Packaging commands

# tutorial repository set up
example packaging/repo-create   "spack repo create $repo_root $name"
example packaging/repo-create   "spack repo add $repo_root/$tutorial_subdir"

example packaging/repo-list     "spack repo list"

example packaging/repo-config   "spack config get repos"

# make the editor automatically exit
export EDITOR=true
example packaging/create     "spack create --name tutorial-mpileaks https://github.com/LLNL/mpileaks/archive/refs/tags/v1.0.tar.gz"

example packaging/checksum-mpileaks-1  "spack checksum tutorial-mpileaks 1.0"

example --expect-error packaging/install-mpileaks-1  "spack install tutorial-mpileaks"

# TODO: Update info-mpileaks.out output manually since automation fails.
#
# This fails ("Error: invalid width -2 (must be > 0)") in CI when preparing
# variants BUT not when run on the command line.
#cp "$PROJECT/package-py-files/1.package.py" "$mpileaks_package_py"
#example packaging/info-mpileaks       "spack info --phases tutorial-mpileaks"

cp "$PROJECT/package-py-files/2.package.py" "$mpileaks_package_py"
example --expect-error packaging/install-mpileaks-2  "spack install tutorial-mpileaks"

stage_dir="$(spack location -s tutorial-mpileaks)"
example packaging/build-output        "cat $stage_dir/spack-build-out.txt"

# TODO: Update build-env-configure.out manually since automation fails.
#
# 1. Original approach fails claiming configure cannot be found.
#prefix=$(spack python -c \
#    'import spack.concretize; print(spack.concretize.concretize_one("tutorial-mpileaks").prefix)')
#spack cd tutorial-mpileaks
#echo "configure --prefix=$prefix" | example packaging/build-env-configure "spack build-env tutorial-mpileaks -- bash"
#
# 2. Using a bash function .. seems to encounter excessive delays on the order
#    of over 10 minutes when watched in CI
run_configure() (
    prefix=$(spack python -c \
        'import spack.concretize; print(spack.concretize.concretize_one("tutorial-mpileaks").prefix)')
    spack cd tutorial-mpileaks
    spack build-env tutorial-mpileaks bash
    example --expect-error $PROJECT/packaging/build-env-configure "./configure --prefix=$prefix"
    cd $PROJECT
)
run_configure

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
