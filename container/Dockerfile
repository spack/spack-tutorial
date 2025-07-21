FROM ghcr.io/spack/tutorial-ubuntu-22.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update -y && \
    apt-get install -y --no-install-recommends \
    bash-completion \
    emacs \
    jq \
    less \
    rclone \
    vim \
    && rm -rf /var/lib/apt/lists/*


# Download the buildcache
RUN mkdir /mirror
RUN rclone copy :s3:spack-binaries/v0.23.1/tutorial /mirror

RUN chmod -R go+r /mirror

COPY packages.yaml /etc/spack/packages.yaml
COPY config.yaml /etc/spack/config.yaml
COPY concretizer.yaml /etc/spack/concretizer.yaml

RUN useradd -ms /bin/bash spack && \
    chmod -R go+r /etc/spack

USER spack

WORKDIR /home/spack

ENTRYPOINT [ "bash" ]
