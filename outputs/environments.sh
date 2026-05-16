#!/bin/bash

# Source definitions
project=$(dirname "$0")
. "$project/defs.sh"

rm -rf "${raw_outputs:?}/environments"

export SPACK_COLOR=never

. "$project/init_spack.sh"
echo $PWD
. share/spack/setup-env.sh

####
# Introduction for "basic" installation if basics section not being used
####
#example environments/clone           "git clone --depth=2 --branch=develop https://github.com/spack/spack.git"
#example environments/clone           "cd ~/spack"

#cd ~/spack || exit
#export SPACK_ROOT=~/spack

#git clone --depth=2 --branch=develop https://github.com/spack/spack
#. spack/share/spack/setup-env.sh
#spack repo update builtin --commit 79fd9821dceebf719a4cb544ba67c3b2f39132ca
#spack bootstrap now
#spack compiler find
spack mirror add --unsigned cineca26 /buildcache

#spack config add "config:suppress_gpg_warnings:true"

#example environments/source-setup     ". share/spack/setup-env.sh"

#example environments/gmake      "spack install gmake"

#example environments/gmake-1    "spack install gmake@4.3"

#example environments/find-gmake "spack find -p gmake"

#example environments/ls-dot-spack 'ls "$(spack location -i gmake@4.4)/.spack"'

#example environments/mirror     "spack mirror add tutorial /mirror"
#example environments/mirror     "spack buildcache keys --install --trust"

####
# Usual Environment output
####

example environments/find-no-env-1   "spack compiler list"
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

spack env activate myproject

example environments/env-add-1            "spack add quantum-espresso"
example environments/env-add-1            "spack add py-numpy"

example environments/env-add-find-1       "spack find"

example environments/env-install-1        "spack concretize"

spack install

example environments/find-env-2           "spack find"

example environments/use-pwx-1       "which pw.x"
example environments/show-paths-1    "env | grep PATH="

example environments/find-l-1         "spack find -l"
example environments/spec-openmpi-1  "spack spec openmpi"

spack env deactivate
example --expect-error environments/env-deactivate-1 "which pw.x"

spack env activate myproject
example environments/env-remove-1    "spack remove py-numpy"
example environments/env-remove-1    "spack find"

example environments/env-concretize-remove-1    "spack concretize"
example environments/env-concretize-remove-1    "spack find"

example environments/env-uninstall-1    "spack -E find py-numpy"
example environments/env-uninstall-1    "spack -E uninstall -y py-numpy"

example environments/env-restore-1     "spack install --add py-numpy"

example --tee environments/filenames-1     "spack cd -e myproject"
spack cd -e myproject
example environments/filenames-1     "pwd"
example environments/filenames-1     "ls"

example environments/cat-config-1 "cat spack.yaml"

example environments/lockfile-1          "jq < spack.lock | head -30"

example environments/create-from-file-1  "spack env create abstract spack.yaml"

example --tee environments/find-env-abstract-1   "spack env activate abstract"
spack env activate abstract
example environments/find-env-abstract-1   "spack find"

spack env deactivate
example environments/create-from-file-2  "spack env create concrete spack.lock"

example --tee environments/find-env-concrete-1   "spack env activate concrete"
spack env activate concrete
example environments/find-env-concrete-1   "spack find"

spack env deactivate
spack env activate myproject

cd || exit

# The file is edited by hand here; mock by writing spack.yaml directly
cat > "$SPACK_ENV/spack.yaml" << 'EOF'
spack:
  specs:
  - group: compiler
    specs:
    - gcc@16 build_type=Release +profiled +strip
  - group: gcc-16-specs
    needs: [compiler]
    specs:
    - quantum-espresso %mpi=mpich
    override:
      packages:
        c:
          prefer: [gcc@16]
        cxx:
          prefer: [gcc@16]
        fortran:
          prefer: [gcc@16]
  view: false
  concretizer:
    unify: true
EOF

example environments/concretize-f-1 "spack concretize --force"
spack install
example environments/find-gcc16-1 "spack find"

# Add named views
cat > "$SPACK_ENV/spack.yaml" << 'EOF'
spack:
  specs:
  - group: compiler
    specs:
    - gcc@16 build_type=Release +profiled +strip
  - group: gcc-16-specs
    needs: [compiler]
    specs:
    - quantum-espresso %mpi=mpich
    override:
      packages:
        c:
          prefer: [gcc@16]
        cxx:
          prefer: [gcc@16]
        fortran:
          prefer: [gcc@16]
  view:
    apps:
      root: ./views/qe
      group: gcc-16-specs
    compilers:
      root: ./views/compilers
      group: compiler
  concretizer:
    unify: true
EOF

example environments/view-regenerate-1 "spack env view regenerate"

spack env deactivate
example --tee environments/view-apps-1 "spack env activate -v apps myproject"
spack env activate -v apps myproject
example environments/view-apps-1 "which pw.x"

spack env deactivate
example --tee environments/view-compilers-1 "spack env activate -v compilers myproject"
spack env activate -v compilers myproject
example environments/view-compilers-1 "which gcc"

spack env deactivate
spack env rm -y myproject abstract concrete
