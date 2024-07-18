FROM ubuntu:22.04 AS stage

ENV DEBIAN_FRONTEND=noninteractive

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
RUN aws --region us-east-1 --no-sign-request s3 sync --only-show-errors s3://spack-binaries/releases/v0.22/tutorial /mirror

FROM ghcr.io/spack/tutorial-ubuntu-22.04:v2023-10-30

COPY --from=stage /mirror /mirror
RUN chmod -R go+r /mirror

COPY /packages.yaml /etc/spack/packages.yaml
COPY /config.yaml /etc/spack/config.yaml
COPY /concretizer.yaml /etc/spack/concretizer.yaml

RUN DEBIAN_FRONTEND=noninteractive apt-get remove -y gcc-12 && \
    apt-get update -y && \
    apt-get install -y --no-install-recommends emacs bash-completion less jq && \
    apt-get -y autoremove --purge && \
    apt-get clean

RUN useradd -ms /bin/bash spack && \
    chmod -R go+r /etc/spack

USER spack

WORKDIR /home/spack

ENTRYPOINT [ "bash" ]
