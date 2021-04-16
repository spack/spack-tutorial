#!/bin/bash

# Source definitions
project=$(dirname "$0")
. $project/defs.sh

rm -rf $raw_outputs/environments
. $project/init_spack.sh

. ~/spack/share/spack/setup-env.sh

example environments/find-no-env-1   "spack find"

example environments/env-create-1    "spack env create myproject"

example environments/env-list-1      "spack env list"

example -tee environments/env-activate-1  "spack env activate myproject"
spack env activate myproject

example environments/find-env-1      "spack find"

example environments/env-status-1    "spack env status"

example -tee environments/env-status-2    "despacktivate    # short alias for `spack env deactivate`"
spack env deactivate
example environments/env-status-2    "spack env status"
example environments/env-status-2    "spack find"

example -tee environments/env-install-1   "spack env activate myproject"
spack env activate myproject
example environments/env-install-1   "spack install tcl"
example environments/env-install-1   "spack install trilinos"
example environments/env-install-1   "spack find"

example environments/use-tcl-1       "which tclsh"
# don't change tclsh example

example environments/use-trilinos-1  "which algebra"
example environments/use-trilinos-1  "algebra"

example environments/env-create-2    "spack env create myproject2"
example -tee environments/env-create-2    "spack env activate myproject2"
spack env activate myproject2
example environments/env-create-2    "spack install hdf5+hl"
example environments/env-create-2    "spack install trilinos"
example environments/env-create-2    "spack find"

echo "y
" | example environments/env-uninstall-1 "spack uninstall trilinos"
example environments/env-uninstall-1 "spack find"

example -tee environments/env-swap-1      "despacktivate"
spack env deactivate
example -tee environments/env-swap-1      "spack env activate myproject"
spack env activate myproject
example environments/env-swap-1      "spack find"

example environments/add-1           "spack add hdf5+hl"
example environments/add-1           "spack add gmp"
example environments/add-1           "spack find"

example environments/add-2           "spack install"

example environments/add-3           "spack find"

example environments/spec-1          "spack spec hypre"

example environments/config-get-1    "spack config get"

# The file is edited by hand here
# We mock that by using `spack config add`
spack config add packages:all:providers:mpi:[mpich]

example environments/spec-2          "spack spec hypre"

example environments/concretize-f-1 "spack concretize --force"

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
example environments/use-mpi-1       "mpicc ./mpi-hello.c"
example environments/use-mpi-1       "mpirun -n 4 ./a.out"

example -tee environments/filenames-1     "spack cd -e myproject"
spack cd -e myproject
example environments/filenames-1     "pwd"
example environments/filenames-1     "ls"

example environments/anonymous-create-1 "cd"
cd
example environments/anonymous-create-1 "mkdir code"
mkdir code
example environments/anonymous-create-1 "cd code"
cd code
example environments/anonymous-create-1 "spack env create -d ."

example environments/anonymous-create-2 "ls"
example environments/anonymous-create-2 "cat spack.yaml"

example -tee environments/install-anonymous-1 "spack env activate ."
spack env activate .
# mock a hand-edit from before we activated
spack add boost
spack add trilinos
spack add openmpi
example environments/install-anonymous-1 "spack install"

example environments/add-anonymous-1     "spack add hdf5@5.5.1"
example environments/add-anonymous-1     "cat spack.yaml"
example environments/add-anonymous-1     "spack remove hdf5"

example environments/lockfile-1          "head -30 spack.lock"

example environments/create-from-file-1  "spack env create abstract spack.yaml"
example environments/create-from-file-1  "spack env create concrete spack.lock"
