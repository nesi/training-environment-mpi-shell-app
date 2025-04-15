FROM ubuntu:22.04

# run unminimise
RUN yes | unminimize

# install system dependencies
# TODO: move ldap-utils, libnss-ldapd, libpam-ldapd, nscd, nslcd to base image??
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y \
        bioawk \
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
        rsync \
        unzip \
        vim \
        wget \
        zip \
    && rm -rf /var/lib/apt/lists/* \
    && localedef -i en_NZ -c -f UTF-8 -A /usr/share/locale/locale.alias en_NZ.UTF-8

ENV LANG en_NZ.utf8

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


# download the required data into the container image and make sure permission are ok
RUN wget -nv https://github.com/GenomicsAotearoa/shell-for-bioinformatics/releases/download/v2.0/puzzles_da.tar.gz \
        -O /var/lib/puzzles_da.tar.gz \
    && tar -xzf /var/lib/puzzles_da.tar.gz -C /var/lib \
    && rm -f /var/lib/puzzles_da.tar.gz \
    && chown -R root:root /var/lib/puzzles_da \
    && chmod -R o+rX /var/lib/puzzles_da \
    && wget -nv https://github.com/GenomicsAotearoa/shell-for-bioinformatics/releases/download/v2.0/shell4b_data.tar.gz \
        -O /var/lib/shell4b_data.tar.gz \
    && tar -xzf /var/lib/shell4b_data.tar.gz -C /var/lib \
    && rm -f /var/lib/shell4b_data.tar.gz \
    && chown -R root:root /var/lib/shell4b_data \
    && chmod -R o+rX /var/lib/shell4b_data

# install jupyterlab
RUN pip3 --no-cache-dir install jupyterlab
