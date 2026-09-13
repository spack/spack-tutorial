# Multi-stage variant of ./Dockerfile.
#
# Instead of pulling a prebuilt buildcache, this builds the buildcache
# locally from container/spack.yaml in a "builder" stage, then copies
# it into the tutorial image. Use it to try out new specs: edit
# container/spack.yaml and rebuild.
#
#   docker build -f container/buildcache.dockerfile -t tutorial:experimental container
#

# ---- stage 1: build the buildcache ----
FROM ghcr.io/spack/tutorial-ubuntu-26.04:v2026-06-09 AS builder

ENV DEBIAN_FRONTEND=noninteractive
ENV SPACK_ROOT=/spack/spack
ENV PATH=$SPACK_ROOT/bin:$PATH
ENV SPACK_COMMIT=63943396d634faa92cb59474df3558ec9b9b2425
ENV SPACK_PACKAGES_COMMIT=688a7045fbcaea7b4965ac51e266408a0b591b9d

# Base image has no spack, so clone it and pin to a specific commit.
RUN git clone --depth 1 https://github.com/spack/spack.git $SPACK_ROOT && \
    git -C $SPACK_ROOT fetch --depth 1 origin $SPACK_COMMIT && \
    git -C $SPACK_ROOT checkout $SPACK_COMMIT

# Pin the builtin package repository to a specific commit.
RUN spack repo update builtin --commit $SPACK_PACKAGES_COMMIT

COPY spack.yaml /opt/spack-environment/spack.yaml

RUN --mount=type=cache,target=/home/software/spack \
    spack -e /opt/spack-environment concretize -f && \
    spack -e /opt/spack-environment install --fail-fast

RUN --mount=type=cache,target=/home/software/spack \
    spack -e /opt/spack-environment buildcache push --unsigned --update-index /mirror && \
    chmod -R go+r /mirror

# ---- stage 2: the tutorial image ----
FROM ghcr.io/spack/tutorial-ubuntu-26.04:v2026-06-09

ENV DEBIAN_FRONTEND=noninteractive

# Same tooling as ./Dockerfile, minus rclone (no longer needed).
RUN apt-get update -y && \
    apt-get install -y --no-install-recommends \
    bash-completion \
    ca-certificates \
    emacs \
    jq \
    less \
    vim

# Bring in the buildcache produced by the builder stage.
COPY --from=builder /mirror /mirror

COPY packages.yaml /etc/spack/packages.yaml
COPY config.yaml /etc/spack/config.yaml
COPY concretizer.yaml /etc/spack/concretizer.yaml

RUN useradd -ms /bin/bash spack && \
    chmod -R go+r /etc/spack

USER spack

WORKDIR /home/spack

ENTRYPOINT [ "bash" ]
