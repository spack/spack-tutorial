FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

# Install AWS cli
RUN apt-get update -y && \
    apt-get install -y --no-install-recommends \
    gcc gfortran g++ \
    gcc-10 gfortran-10 g++-10 \
    clang \
    libc-dev \
    awscli \
    bash-completion \
    emacs \
    jq \
    less \
    vim \
    && rm -rf /var/lib/apt/lists/*

# Download the buildcache
RUN mkdir /mirror
RUN aws --region us-east-1 --no-sign-request s3 sync --only-show-errors s3://spack-binaries/v0.23.1/tutorial /mirror

RUN chmod -R go+r /mirror

COPY packages.yaml /etc/spack/packages.yaml
COPY config.yaml /etc/spack/config.yaml
COPY concretizer.yaml /etc/spack/concretizer.yaml

RUN useradd -ms /bin/bash spack && \
    chmod -R go+r /etc/spack

USER spack

WORKDIR /home/spack

ENTRYPOINT [ "bash" ]
