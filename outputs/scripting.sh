#!/bin/bash

# Source definitions
project=$(dirname "$0")
. $project/defs.sh

rm -rf $raw_outputs/scripting
. $project/init_spack.sh

example setup           "spack uninstall -ay"
example setup           "spack compiler rm gcc@8.3.0"
example setup           "spack install hdf5"
example setup           "spack install zlib%clang"

example find-format     'spack find --format "{name} {version} {hash:10}"'

example find-json       "spack find --json zlib"

echo "exit()
" | example spack-python-1  "spack python"

fake_example edit '$EDITOR find_exclude.py' "/bin/true"

cat <<EOF | tee /project/raw/0.find_exclude.py.example find_exclude.py
from spack.spec import Spec
import spack.store
import spack.cmd
import sys

include_spec = Spec(sys.argv[1])
exclude_spec = Spec(sys.argv[2])

all_included = spack.store.db.query(include_spec)
result = filter(lambda spec: not spec.satisfies(exclude_spec), all_included)

spack.cmd.display_specs(result)
EOF

example find-exclude-1 "spack python find_exclude.py %gcc ^mpich"

{ echo "#!/usr/bin/env spack python" & cat find_exclude.py; } | tee /project/raw/1.find_exclude.py.example find_exclude.py

example find-exclude-2 "chmod u+x find_exclude.py"
example find-exclude-2 "./find_exclude.py %gcc ^mpich"

sed s'|spack python|spack-python|' find_exclude.py | tee /project/raw/2.find_exclude.py.example find_exclude.py

example find-exclude-3 "./find_exclude.py %gcc ^mpich"
