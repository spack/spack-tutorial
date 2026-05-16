#!/bin/bash

# Source definitions
project="$(dirname "$0")"
. "$project/defs.sh"

rm -rf "${raw_outputs:?}/dev"
. "$project/init_spack.sh"

export SPACK_COLOR=never

echo $PWD
. share/spack/setup-env.sh
spack mirror add --unsigned cineca26 /buildcache

# ---------------------------------------------------------------------------
# Setup: create and populate the qe-dev environment
# ---------------------------------------------------------------------------

cd ~ || exit

spack env create qe-dev

# Write the manifest directly (mirrors what the user does via spack config edit)
cat > "$(spack location -e qe-dev)/spack.yaml" << 'YAML'
spack:
  specs:
  - quantum-espresso +elpa %elpa +openmp
  view: view
  concretizer:
    unify: true
  mirrors:
    local:
      url: /buildcache
      signed: false
  packages:
    c:
      prefer: [gcc@15]
    cxx:
      prefer: [gcc@15]
    fortran:
      prefer: [gcc@15]
YAML

spack env activate qe-dev

example dev/setup "spack concretize"

# ---------------------------------------------------------------------------
# Clone upstream QE at the qe-7.5 tag (shallow to reduce size)
# ---------------------------------------------------------------------------

example dev/clone "git clone -c advice.detachedHead=false --depth 2 --branch qe-7.5 https://gitlab.com/QEF/q-e.git"
example dev/clone "git -C q-e switch -c qe-7.5-dev"

# ---------------------------------------------------------------------------
# Register the clone as the dev_path for quantum-espresso@7.5.
# --no-clone tells spack develop to use the existing source at the given
# path without downloading or overwriting it.
# ---------------------------------------------------------------------------

example dev/develop "spack develop --path ~/q-e quantum-espresso@7.5 +elpa %elpa+openmp"

# ---------------------------------------------------------------------------
# Relax the recipe constraint so cmake+elpa+openmp is concretizable.
# Shown as spack edit (no output); real action is a targeted sed.
# Following the old tutorial pattern: do the real edit first, then
# fake_example records the "shown" command with a no-op real command.
# ---------------------------------------------------------------------------

spack cd --repo builtin
git apply /project/qe.7.5-elpa-openmp-relax.diff
cd - || exit

fake_example dev/relax "spack edit quantum-espresso" "true"

# ---------------------------------------------------------------------------
# Update the env spec and concretize, then attempt the build (expected to fail)
# ---------------------------------------------------------------------------

example dev/build-fail-concretize "spack concretize -f"

example dev/build-fail-install "spack install | cat"

# ---------------------------------------------------------------------------
# Apply the FindELPA fix to the local clone.
# Shown as $EDITOR (no output); real action fetches and applies the patch.
# ---------------------------------------------------------------------------

git -C ~/q-e apply /project/517a7bba47628af8f93f985765d7ab7d23077c4c.diff

fake_example dev/fix "\$EDITOR q-e/cmake/FindELPA.cmake" "true"

# ---------------------------------------------------------------------------
# Rebuild from the patched local source (should succeed)
# ---------------------------------------------------------------------------

example dev/build-ok "spack -v install --until cmake | cat"

# ---------------------------------------------------------------------------
# Drop the dev_path registration
# ---------------------------------------------------------------------------

example dev/undevelop "spack undevelop quantum-espresso"

# ---------------------------------------------------------------------------
# Add patch() directive and narrow the depends_on constraint in the recipe.
# Shown as spack edit (no output); real action uses python to modify the file.
# ---------------------------------------------------------------------------

spack cd --repo builtin
git stash
git apply /project/qe.7.5-elpa-openmp-fix.diff
cd - || exit

# ---------------------------------------------------------------------------
# Reinstall from the upstream tarball + patch (no local clone required)
# ---------------------------------------------------------------------------

example dev/reinstall-concretize "spack concretize -f --fresh-roots"
example dev/reinstall-install "spack install | cat"

# ---------------------------------------------------------------------------
# Cleanup
# ---------------------------------------------------------------------------

spack env deactivate
fake_example dev/wrapup "despacktivate" "true"
example dev/wrapup "spack env rm -y qe-dev"
