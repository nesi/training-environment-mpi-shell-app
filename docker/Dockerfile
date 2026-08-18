FROM ubuntu:22.04

# run unminimise so man pages and the usual interactive tooling are present
RUN yes | unminimize

# install system dependencies
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y \
        bioawk \
        bzip2 \
        ca-certificates \
        curl \
        dnsutils \
        git \
        ldap-utils \
        libnss-ldapd \
        libpam-ldapd \
        less \
        locales \
        man-db \
        nano \
        nodejs \
        nscd \
        nslcd \
        python-is-python3 \
        python3 \
        python3-pip \
        python3-venv \
        python3-distutils \
        rsync \
        tree \
        unzip \
        vim \
        wget \
        zip \
    && rm -rf /var/lib/apt/lists/* \
    && localedef -i en_NZ -c -f UTF-8 -A /usr/share/locale/locale.alias en_NZ.UTF-8

ENV LANG=en_NZ.utf8

# make a dummy module command: the OnDemand job_script_content.sh calls it, and
# workshop material copied from mahuika may still contain "module load" lines.
# Every tool in this image is already on PATH, so this is a no-op.
RUN printf '%s\n' \
        '#!/bin/bash' \
        '# No modules in this container - every tool is already on PATH.' \
        '# Run "mpi-tools" to list what is installed.' \
        'exit 0' \
        > /bin/module \
    && chmod +x /bin/module

# install kubectl, required for running on the k8s cluster
ARG KUBECTL_VERSION=v1.28.5
RUN curl -LO https://dl.k8s.io/release/$KUBECTL_VERSION/bin/linux/amd64/kubectl \
    && mv kubectl /usr/local/bin/kubectl \
    && chmod +x /usr/local/bin/kubectl

# copy in ood k8s utils
ARG UTILS_HASH=6298fb01f7a7c66a8454e3f0fd74437a32491423
RUN git clone https://github.com/nesi/training-environment-k8s-utils.git /opt/ood-k8s-utils \
    && cd /opt/ood-k8s-utils \
    && git checkout $UTILS_HASH \
    && chmod +x /opt/ood-k8s-utils/files/* \
    && mv /opt/ood-k8s-utils/files/* /bin/ \
    && rm -rf /opt/ood-k8s-utils

# install jupyterlab
RUN pip3 --no-cache-dir install jupyterlab

# install micromamba, used to install every bioinformatics tool at a pinned version
ARG MICROMAMBA_VERSION=1.5.8
ENV MAMBA_ROOT_PREFIX=/opt/conda
RUN curl -Ls "https://micro.mamba.pm/api/micromamba/linux-64/${MICROMAMBA_VERSION}" \
        | tar -xj -C /usr/local bin/micromamba \
    && chmod +x /usr/local/bin/micromamba

# bioinformatics tools, one environment per set of mutually compatible pins.
# They are split because the pinned versions cannot coexist: DIAMOND 2.2.1 needs
# zlib >= 1.3.2 while SAMtools 1.16.1 pins zlib < 1.3, and SPAdes 3.15.2 needs
# Python < 3.10 while Flye 2.9.1 pulls in 3.10.
COPY envs/ /opt/envs/
RUN micromamba create -y -f /opt/envs/assembly.yml \
    && micromamba create -y -f /opt/envs/spades.yml \
    && micromamba create -y -f /opt/envs/diamond.yml \
    && micromamba create -y -f /opt/envs/qc.yml \
    && micromamba clean --all --yes \
    && rm -rf /opt/conda/pkgs

# expose every tool on PATH through a wrapper, so all tools start the same way
COPY tools.tsv /opt/tools.tsv
COPY make-wrappers.sh /opt/make-wrappers.sh
COPY mpi-tools /usr/local/bin/mpi-tools
RUN chmod +x /opt/make-wrappers.sh /usr/local/bin/mpi-tools \
    && /opt/make-wrappers.sh /opt/tools.tsv

ENV PATH="/usr/local/bin:${PATH}"

# smoke test: fail the build if any declared tool cannot start
COPY smoke-test.sh /opt/smoke-test.sh
RUN chmod +x /opt/smoke-test.sh && /opt/smoke-test.sh

# end-to-end test, run by hand (too slow for the build):
#   docker run --rm <image> bash /opt/functional-test.sh
COPY functional-test.sh /opt/functional-test.sh
RUN chmod +x /opt/functional-test.sh

# copy data
# COPY docker/data/ /var/lib/data/
