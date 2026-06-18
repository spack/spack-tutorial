FROM ghcr.io/spack/tutorial-ubuntu-26.04

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

# Remove GCC 14 from container
RUN apt-get remove -y gcc-14

# Download the buildcache
RUN mkdir /mirror
RUN rclone copy :s3:spack-binaries/develop/tutorial /mirror

RUN chmod -R go+r /mirror

COPY packages.yaml /etc/spack/packages.yaml
COPY config.yaml /etc/spack/config.yaml
COPY concretizer.yaml /etc/spack/concretizer.yaml

RUN useradd -ms /bin/bash spack && \
    chmod -R go+r /etc/spack

USER spack

WORKDIR /home/spack

ENTRYPOINT [ "bash" ]
