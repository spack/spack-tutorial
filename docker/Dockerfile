FROM ubuntu:18.04 AS stage

ENV DEBIAN_FRONTEND=noninteractive \
    REMOTE_BUILDCACHE_URL="s3://spack-binaries/releases/v0.18/tutorial"

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
RUN aws --region us-east-1 --no-sign-request s3 sync s3://spack-binaries/releases/v0.18/tutorial /mirror
RUN rm -rf /mirror/buid_cache/_pgp
RUN aws --region us-east-1 --no-sign-request s3 sync s3://spack-binaries/releases/v0.18/build_cache/_pgp /mirror/build_cache/_pgp

FROM ubuntu:18.04 as builder

ENV DEBIAN_FRONTEND=noninteractive

COPY --from=stage /mirror /mirror
RUN chmod -R go+r /mirror

RUN apt-get update -y && \
    apt-get install -y --no-install-recommends \
        autoconf \
        build-essential \
        bsdmainutils \
        ca-certificates \
        curl \
        clang-7 \
        emacs \
        file \
        g++ g++-6 \
        gcc gcc-6 \
        gfortran gfortran-6 \
        git \
        gnupg2 \
        iproute2 \
        make \
        openssh-server \
        python3 \
        python3-pip \
        tcl \
        unzip \
        vim \
        wget && \
    python3 -m pip install --upgrade pip setuptools wheel && \
    python3 -m pip install --upgrade gnureadline && \
    update-alternatives --install /usr/bin/python python /usr/bin/python3 1 && \
    apt-get autoremove --purge && \
    apt-get clean

COPY /packages.yaml /etc/spack/packages.yaml
COPY /config.yaml /etc/spack/config.yaml

RUN useradd -ms /bin/bash spack && \
    chmod -R go+r /etc/spack

USER spack

WORKDIR /home/spack

ENTRYPOINT [ "bash" ]
