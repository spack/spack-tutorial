FROM ghcr.io/haampie/cineca-2026-base:latest@sha256:8c45cfae569be8c75603ff6c851d3e69653bb73633dedade14dd8a5e65a46b92 AS builder

RUN chmod -R go+r /buildcache


FROM ubuntu:26.04

ENV DEBIAN_FRONTEND=noninteractive

COPY packages.yaml /etc/spack/packages.yaml
COPY config.yaml /etc/spack/config.yaml
COPY concretizer.yaml /etc/spack/concretizer.yaml
COPY find_elpa_fix.diff /etc/patches/find_elpa_fix.diff

COPY --from=builder /buildcache /buildcache

RUN apt-get update -y && \
    apt-get install -y --no-install-recommends \
    gcc g++ gfortran patch git python3 xz-utils bzip2 ca-certificates file \
    bash-completion \
    emacs \
    jq \
    less \
    vim && \
    rm -rf /var/lib/apt/lists/*


RUN useradd -ms /bin/bash spack && \
    chmod -R go+r /etc/spack

USER spack

WORKDIR /home/spack

ENTRYPOINT [ "bash" ]
