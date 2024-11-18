FROM ghcr.io/spack/tutorial-ubuntu-22.04:v2024-05-07

ENV DEBIAN_FRONTEND=noninteractive

# Install AWS cli
RUN apt-get update -y && \
    apt-get install -y --no-install-recommends \
    awscli \
    bash-completion \
    emacs \
    jq \
    less \
    vim

# Remove GCC 12 from container
RUN apt-get remove -y gcc-12

# Download the buildcache
RUN mkdir /mirror
RUN aws --region us-east-1 --no-sign-request s3 sync --only-show-errors s3://spack-binaries/releases/v0.23/tutorial /mirror

RUN chmod -R go+r /mirror

COPY packages.yaml /etc/spack/packages.yaml
COPY config.yaml /etc/spack/config.yaml
COPY concretizer.yaml /etc/spack/concretizer.yaml

RUN useradd -ms /bin/bash spack && \
    chmod -R go+r /etc/spack

USER spack

WORKDIR /home/spack

ENTRYPOINT [ "/bin/bash", "-l", "-c" ]
