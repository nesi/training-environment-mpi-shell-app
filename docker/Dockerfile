FROM ubuntu:22.04

# run unminimise
RUN yes | unminimize

# install system dependencies
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
        python3-venv \
        python3-distutils \
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
#RUN wget -nv https://github.com/GenomicsAotearoa/shell-for-bioinformatics/releases/download/v2.0/puzzles_da.tar.gz \
#        -O /var/lib/puzzles_da.tar.gz \
#    && tar -xzf /var/lib/puzzles_da.tar.gz -C /var/lib \
#    && rm -f /var/lib/puzzles_da.tar.gz \
#    && chown -R root:root /var/lib/puzzles_da \
#    && chmod -R o+rX /var/lib/puzzles_da

# install jupyterlab
RUN pip3 --no-cache-dir install jupyterlab

# Install Python-based tools in a virtual environment
RUN python3 -m venv /opt/venv \
    && /opt/venv/bin/pip install --upgrade pip \
    && /opt/venv/bin/pip install pycoQC \
    && /opt/venv/bin/pip install nanofilt \
    # Create symlinks to the venv binaries
    && ln -s /opt/venv/bin/pycoQC /usr/local/bin/ \
    && ln -s /opt/venv/bin/NanoFilt /usr/local/bin/ \
    # porechop
    && git clone https://github.com/rrwick/Porechop.git \
    && cd Porechop \
    && /opt/venv/bin/python3 setup.py install \
    && chmod a+x porechop \
    && ln -s porechop /usr/local/bin/

# Install FastQC
RUN wget https://www.bioinformatics.babraham.ac.uk/projects/fastqc/fastqc_v0.12.1.zip && \
    unzip fastqc_v0.12.1.zip && \
    mv FastQC /opt/ && \
    chmod +x /opt/FastQC/fastqc && \
    ln -s /opt/FastQC/fastqc /usr/local/bin/fastqc && \
    rm fastqc_v0.12.1.zip

# Install fastp  (1.0.1)
RUN wget http://opengene.org/fastp/fastp && \
    chmod a+x fastp && \
    mv fastp /opt/ && \
    ln -s /opt/fastp /usr/local/bin/fastp

# Set up environment variables for the virtual environment
ENV PATH="/opt/venv/bin:$PATH"

# copy data
# COPY docker/MPI/ /var/lib/MPI/
