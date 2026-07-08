#!/bin/bash

# Source definitions
project="$(dirname "$0")"
. "$project/defs.sh"

rm -rf "${raw_outputs:?}/cache"
. "$project/init_spack.sh"

export SPACK_COLOR=never

# Clean up any state from a previous run
rm -rf ~/myenv
docker rm -f registry >/dev/null 2>&1 || true

# Installing julia from the build cache
example cache/install-julia "mkdir ~/myenv && cd ~/myenv"
mkdir -p ~/myenv
cd ~/myenv || exit
example cache/install-julia "spack env create --with-view view ."
example cache/install-julia "spack -e . add julia"

example --tee cache/install "spack -e . install"

example cache/julia-run "./view/bin/julia -e 'println(1 + 1)'"

# Setting up a local OCI build cache
example cache/registry "docker run -d --rm -p 5000:5000 --name registry registry"

example cache/mirror-add "spack -e . mirror add --unsigned my-registry oci+http://localhost:5000/buildcache"

# Pushing to the OCI build cache
example --tee cache/push "spack -e . buildcache push --without-build-dependencies my-registry"

# Re-running the push detects that nothing needs to be uploaded
example --tee cache/push-again "spack -e . buildcache push --without-build-dependencies my-registry"

# Reinstalling from the OCI build cache
# Disable the filesystem "tutorial" mirror by changing mirrors: to mirrors::
sed -i~ 's/^\( *\)mirrors:$/\1mirrors::/' spack.yaml

example --tee cache/reinstall "spack -e . install --overwrite -y julia"

# Creating runnable container images
julia_tag="$(spack -e . find --format '{name}-{version}-{hash}' julia).spack"

# Running the image without a base image fails: it has no glibc
example --tee --expect-error cache/docker-run-fail "docker run --rm localhost:5000/buildcache:${julia_tag} julia -e 'println(1 + 1)'"

# Push again with a base image that provides a compatible glibc
example --tee cache/push-base-image "spack -e . buildcache push --force --without-build-dependencies --base-image ubuntu:26.04 my-registry"

# The image now runs; --pull always fetches the rebuilt image with the base layer
example --tee cache/docker-run "docker run --rm --pull always localhost:5000/buildcache:${julia_tag} julia -e 'println(1 + 1)'"

# Spack environments as container images
# Re-enable the "tutorial" mirror so vim is installed from the cache
sed -i~ 's/^\( *\)mirrors::$/\1mirrors:/' spack.yaml

example --tee cache/install-vim "spack -e . install --add vim"

example --tee cache/push-tag "spack -e . buildcache push --without-build-dependencies --base-image ubuntu:26.04 --tag julia-and-vim my-registry"

# The combined image is run interactively in the tutorial:
#   $ docker run -it --rm localhost:5000/buildcache:julia-and-vim

# Clean up the local registry
docker rm -f registry >/dev/null 2>&1 || true
