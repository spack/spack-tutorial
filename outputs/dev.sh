#!/bin/bash

# Source definitions
project="$(dirname "$0")"
. "$project/defs.sh"

rm -rf "${raw_outputs:?}/dev"
. "$project/init_spack.sh"

example dev/setup-scr "cd ~"
cd ~ || exit
example dev/setup-scr "mkdir devel-env"
example dev/setup-scr "cd devel-env"
cd devel-env || exit
example dev/setup-scr "spack env create -d ."
fake_example dev/setup-scr "spacktivate ." "spack env activate ."
spack env activate .
example dev/setup-scr "# for now, disable fortran support in all packages"
example dev/setup-scr 'spack config add "packages:all:variants: ~fortran"'
example dev/setup-scr "spack add macsio+scr"
example dev/setup-scr "spack install"

example dev/develop-1 "spack develop scr@2.0.0"
example dev/develop-1 "grep -3 develop: spack.yaml"

example dev/develop-conc "spack concretize -f"

example dev/develop-2 "spack install"

export EDITOR=true
fake_example dev/edit-1 '$EDITOR scr/src/scr_copy.c' "/bin/true"
sed -i~ s'|\(static char hostname\[256\] = "UNKNOWN_HOST"\);|\1|' scr/src/scr_copy.c | head -n 70

example --expect-error dev/develop-3 "spack install"

fake_example dev/develop-4 '$EDITOR scr/src/scr_copy.c' "/bin/true"
sed -i~ s'|\(static char hostname\[256\] = "UNKNOWN_HOST"\)|\1;|' scr/src/scr_copy.c | head -n 70
example dev/develop-4 "spack install"

example dev/develop-5 "spack develop macsio@1.1"
example dev/develop-5 "spack concretize -f"

example dev/otherdevel "cd ~"
cd ~ || exit
example dev/otherdevel "mkdir devel-other"
example dev/otherdevel "cd devel-other"
cd devel-other || exit
example dev/otherdevel "cp ../devel-env/spack.yaml ."
fake_example dev/otherdevel "spacktivate ." "spack env activate ."
spack env activate .
example dev/otherdevel "spack develop"
example dev/otherdevel "ls"

example dev/wrapup "spack undevelop scr macsio"
