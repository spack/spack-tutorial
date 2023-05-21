FROM ubuntu:22.04 AS stage

ENV DEBIAN_FRONTEND=noninteractive \
    REMOTE_BUILDCACHE_URL="s3://spack-binaries/releases/v0.20/tutorial"

# Install AWS cli
RUN apt-get update -y && \
    apt-get install -y \
    # Requirements for AWS cli
    unzip less groff curl && \
    apt-get autoremove --purge && \
    apt-get clean

RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && \
    unzip awscliv2.zip && ./aws/install && aws --version

# Download the buildcache 
RUN mkdir /mirror
RUN aws --region us-east-1 --no-sign-request s3 sync s3://spack-binaries/releases/v0.20/tutorial /mirror
RUN rm -rf /mirror/buid_cache/_pgp
# TODO: Get the keys from aws as soon as they're fixed
# RUN aws --region us-east-1 --no-sign-request s3 sync s3://spack-binaries/releases/v0.20/build_cache/_pgp /mirror/build_cache/_pgp
COPY tutorial.pub /mirror/build_cache/_pgp/78F3726939CA1B94893B66E8BC86F6FB94429164.pub

FROM ghcr.io/spack/tutorial-ubuntu-22.04:latest

ENV DEBIAN_FRONTEND=noninteractive

COPY --from=stage /mirror /mirror
RUN chmod -R go+r /mirror

COPY /packages.yaml /etc/spack/packages.yaml
COPY /config.yaml /etc/spack/config.yaml
COPY /concretizer.yaml /etc/spack/concretizer.yaml

RUN apt-get remove -y gcc-12 && \
    apt-get update -y && \
    apt-get install -y --no-install-recommends emacs bash-completion less && \
    apt-get -y autoremove --purge && \
    apt-get clean

RUN useradd -ms /bin/bash spack && \
    chmod -R go+r /etc/spack

USER spack

WORKDIR /home/spack

ENTRYPOINT [ "bash" ]
