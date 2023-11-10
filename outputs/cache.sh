#!/bin/bash

# Source definitions
project="$(dirname "$0")"
. "$project/defs.sh"

rm -rf "${raw_outputs:?}/cache"
. "$project/init_spack.sh"

example cache/mirror-list-0 "spack mirror list"

example cache/setup-scr "cd ~"
cd ~ || exit
example cache/setup-scr "spack env create -d cach-env"
example cache/setup-scr "cd cache-env"
cd cache-env || exit
fake_example cache/setup-scr "spacktivate ." "spack env activate ."
spack env activate .
example cache/setup-scr "# for now, disable fortran support in all packages"
example cache/setup-scr 'spack config add "packages:all:variants: ~fortran"'
example cache/setup-scr "spack add macsio+scr"

# The packages will already be installed by the dev tutorial
spack install
rm spack.lock
example cache/setup-scr "spack install"

example cache/spack-mirror-single "spack mirror create -d ~/mirror scr"

example cache/spack-mirror-config "spack mirror add mymirror ~/mirror"

example cache/spack-mirror-all "spack mirror create -d ~/mirror --all"

example cache/spack-mirror-permissions "umask 750"
example cache/spack-mirror-permissions "chmod -R g+rs ~/mirror"
example cache/spack-mirror-permissions "chgrp -R spack ~/mirror"

example cache/spack-mirror-3 "spack add unzip"
example cache/spack-mirror-3 "spack install"

example cache/spack-mirror-4 "spack mirror create -d ~/mirror --all"

example cache/trust "spack buildcache keys --install --trust --force"

example cache/binary-cache-1 "cd ~"
cd ~ || exit
example cache/binary-cache-1 "mkdir cache-binary"
example cache/binary-cache-1 "cd cache-binary"
cd cache-binary || exit
example cache/binary-cache-1 "spack env create -d ."
fake_example cache/binary-cache-1 "spacktivate ." "spack env activate ."
spack env activate .
example cache/binary-cache-1 "spack add bzip2"
example cache/binary-cache-1 "spack add zlib"

example cache/binary-cache-2 'spack config add "config:install_tree:padded_length:128"'
example cache/binary-cache-2 "spack install --no-cache"

example cache/binary-cache-3 'spack gpg create "My Name" "<my.email@my.domain.com>"'

example cache/binary-cache-3 'mkdir ~/private_gpg_backup'
example cache/binary-cache-3 'cp ~/spack/opt/spack/gpg/*.gpg ~/private_gpg_backup'
example cache/binary-cache-3 'cp ~/spack/opt/spack/gpg/pubring.* ~/mirror'

example cache/binary-cache-4 'spack buildcache push ~/mirror'

# Remove installations from customized prefix
spack uninstall -ay

example cache/bootstrap-1 'spack bootstrap mirror --binary-packages ~/mirror'
