FROM ubuntu:18.04 AS stage

ENV DEBIAN_FRONTEND=noninteractive \
    REMOTE_BUILDCACHE_URL="s3://spack-binaries-develop/tutorial"

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
RUN mkdir /mirror && \
    aws --no-sign-request s3 sync s3://spack-binaries-develop/tutorial /mirror

FROM ubuntu:18.04 as builder

ENV DEBIAN_FRONTEND=noninteractive

COPY --from=stage /mirror /mirror
RUN chmod -R go+r /mirror

RUN apt-get update -y && \
    apt-get install -y --no-install-recommends \
        autoconf \
        build-essential \
        ca-certificates \
        curl \
        clang \
        emacs \
        file \
        g++ g++-6 g++-8 \
        gcc gcc-6 gcc-8 \
        gfortran gfortran-6 gfortran-8 \
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

FROM builder AS final

RUN useradd -ms /bin/bash spack && \
    chmod -R go+r /etc/spack

USER spack

WORKDIR /home/spack

ENTRYPOINT [ "bash" ]
