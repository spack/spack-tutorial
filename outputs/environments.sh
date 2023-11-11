#!/bin/bash

# Source definitions
project=$(dirname "$0")
. "$project/defs.sh"

rm -rf "${raw_outputs:?}/environments"
. "$project/init_spack.sh"

# In the basics section a bunch of packages were already installed,
# they are referenced here. Reinstall them so we can generate outputs
# independently.
spack install zlib-ng \
              zlib-ng %clang \
              zlib-ng@2.0.7 \
              zlib-ng@2.0.7 cflags=-O3 \
              tcl \
              tcl ^zlib-ng cflags=-O3 \
              hdf5 \
              hdf5~mpi \
              hdf5+hl+mpi ^mpich \
              trilinos +hdf5 ^hdf5+hl+mpi ^mpich

example environments/find-no-env-1   "spack find"

example environments/env-create-1    "spack env create myproject"

example environments/env-list-1      "spack env list"

example --tee environments/env-activate-1  "spack env activate myproject"
spack env activate myproject

example environments/find-env-1      "spack find"

example environments/env-status-1    "spack env status"

example --tee environments/env-status-2    "despacktivate    # short alias for 'spack env deactivate'"
spack env deactivate
example environments/env-status-2    "spack env status"
example environments/env-status-2    "spack find"

example --tee environments/env-fail-install-1   "spack env activate myproject"
spack env activate myproject
example --expect-error environments/env-fail-install-1   "spack install tcl"

example environments/env-add-1            "spack add tcl"
example environments/env-add-1            "spack add trilinos"
example environments/env-add-1            "spack find"

example environments/env-install-1        "spack install"

example environments/find-env-2           "spack find"

example environments/use-tcl-1       "which tclsh"

example environments/env-create-2         "spack env create myproject2"
example --tee environments/env-create-2    "spack env activate myproject2"
spack env activate myproject2
example environments/env-create-2    "spack add scr trilinos"
example environments/env-create-2    "spack install"
example environments/env-create-2    "spack find"

example --expect-error environments/env-uninstall-1 "spack uninstall -y trilinos"
example environments/env-uninstall-1 "spack find"

example environments/env-remove-1    "spack remove trilinos"
example environments/env-remove-1    "spack find"

example --tee environments/env-swap-1      "spack env activate myproject"
spack env activate myproject
example environments/env-swap-1      "spack find"

example environments/config-get-1    "spack config get"

# The file is edited by hand here
# We mock that by using `spack config add`
spack config add packages:mpi:require:[mpich]

example environments/concretize-f-1 "spack concretize --force"
# spack install

example --tee environments/incremental-1 "spack env activate --temp"
spack env activate --temp
example environments/incremental-1 "spack install --add python"
example environments/incremental-1 "spack install --add py-numpy@1.20 2>&1 | tail -n1"
example environments/incremental-2 "spack add py-numpy@1.20"
example environments/incremental-2 "spack concretize -f"
spack env deactivate

example --tee environments/show-mpicc-1      "spack env activate myproject2"
spack env activate myproject2
example environments/show-mpicc-1    "spack env status"
example environments/show-mpicc-1    "which mpicc"

example environments/show-paths-1    "env | grep PATH="

# mock hand-edited file
cat > mpi-hello.c <<EOF
#include <stdio.h>
#include <mpi.h>
#include <zlib.h>

int main(int argc, char **argv) {
  int rank;
  MPI_Init(&argc, &argv);

  MPI_Comm_rank(MPI_COMM_WORLD, &rank);
  printf("Hello world from rank %d\n", rank);

  if (rank == 0) {
    printf("zlib version: %s\n", ZLIB_VERSION);
  }

  MPI_Finalize();
}
EOF
example environments/use-mpi-1       'mpicc ./mpi-hello.c -I$(spack location -i zlib-ng)/include'
example environments/use-mpi-1       "mpirun -n 2 ./a.out"

example environments/myproject-zlib-ng-1     "spack find zlib-ng"

example --tee environments/filenames-1     "spack cd -e myproject"
spack cd -e myproject
example environments/filenames-1     "pwd"
example environments/filenames-1     "ls"

example environments/env-list-2      "spack env list"

example environments/cat-config-1 "cat spack.yaml"

example environments/anonymous-create-1 "cd"
cd || exit
example environments/anonymous-create-1 "mkdir code"
example environments/anonymous-create-1 "cd code"
cd code || exit
example environments/anonymous-create-1 "spack env create -d ."

example environments/anonymous-create-2 "ls"
example environments/anonymous-create-2 "cat spack.yaml"

example environments/env-list-3      "spack env list"

example --tee environments/install-anonymous-1 "spack env activate ."
spack env activate .
# mock a hand-edit from before we activated
spack add trilinos
spack add openmpi
example environments/install-anonymous-1 "spack install"

example environments/add-anonymous-1     "spack add hdf5@5.5.1"
example environments/add-anonymous-1     "cat spack.yaml"

example environments/remove-anonymous-1     "spack remove hdf5"
example environments/remove-anonymous-1     "cat spack.yaml"

example environments/lockfile-1          "jq < spack.lock | head -30"

example environments/create-from-file-1  "spack env create abstract spack.yaml"

example --tee environments/find-env-abstract-1   "spack env activate abstract"
spack env activate abstract
example environments/find-env-abstract-1   "spack find"

example environments/create-from-file-2  "spack env create concrete spack.lock"

example --tee environments/find-env-concrete-1   "spack env activate concrete"
spack env activate concrete
example environments/find-env-concrete-1   "spack find"
