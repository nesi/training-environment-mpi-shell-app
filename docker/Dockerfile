FROM ubuntu:22.04

# install system dependencies
# TODO: move ldap-utils, libnss-ldapd, libpam-ldapd, nscd, nslcd to base image??
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y \
        bioawk \
        curl \
        git \
        ldap-utils \
        libnss-ldapd \
        libpam-ldapd \
        less \
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
    && rm -rf /var/lib/apt/lists/*

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
