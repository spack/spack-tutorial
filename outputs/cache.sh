#!/bin/bash

# Source definitions
project=$(dirname "$0")
. $project/defs.sh

rm -rf $raw_outputs/cache
pip install boto3

example cache/up-to-date "git clone https://github.com/spack/spack ~/spack"
example cache/up-to-date "cd ~/spack"
cd ~/spack
example cache/up-to-date "git checkout releases/v0.17"
example cache/up-to-date ". share/spack/setup-env.sh"
. share/spack/setup-env.sh
spack config add "config:suppress_gpg_warnings:true"
spack config add "packages:all:target:[x86_64]"

example cache/up-to-date "spack mirror add tutorial /mirror"
example cache/up-to-date "spack buildcache keys -it"

example cache/mirror-list-0 "spack mirror list"

example cache/setup-scr "cd ~"
cd ~
example cache/setup-scr "mkdir cache-env"
example cache/setup-scr "cd cache-env"
cd cache-env
example cache/setup-scr "spack env create -d ."
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
example cache/spack-mirror-permissions "chmod -R g+rS ~/mirror"
example cache/spack-mirror-permissions "chgrp -R spack ~/mirror"

example cache/spack-mirror-3 "spack add bzip2"
example cache/spack-mirror-3 "spack install"

example cache/spack-mirror-4 "spack mirror create -d ~/mirror --all"


example cache/trust "spack buildcache keys --install --trust --force"

example cache/binary-cache-1 "cd ~"
cd ~
example cache/binary-cache-1 "mkdir cache-binary"
example cache/binary-cache-1 "cd cache-binary"
cd cache-binary
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

example cache/binary-cache-4 '
for ii in $(spack find --format "yyy {version} /{hash}" |
            grep -v -E "^(develop^master)" |
            grep "yyy" |
            cut -f3 -d" ")
do
  spack buildcache create --allow-root --force -d ~/mirror --only=package $ii
done'
