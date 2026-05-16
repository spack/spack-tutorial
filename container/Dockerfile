FROM ghcr.io/haampie/cineca-2026-base:latest@sha256:8c45cfae569be8c75603ff6c851d3e69653bb73633dedade14dd8a5e65a46b92

ENV DEBIAN_FRONTEND=noninteractive

# Install AWS cli
RUN apt-get update -y && \
    apt-get install -y --no-install-recommends \
    bash-completion \
    ca-certificates \
    emacs \
    jq \
    less \
    vim \
    rclone


# Download the buildcache
# RUN mkdir /mirror
# RUN rclone copy :s3:spack-binaries/v2025.11.0/tutorial /mirror

RUN chmod -R go+r /buildcache

COPY packages.yaml /etc/spack/packages.yaml
COPY config.yaml /etc/spack/config.yaml
COPY concretizer.yaml /etc/spack/concretizer.yaml

RUN useradd -ms /bin/bash spack && \
    chmod -R go+r /etc/spack

USER spack

WORKDIR /home/spack

ENTRYPOINT [ "bash" ]
