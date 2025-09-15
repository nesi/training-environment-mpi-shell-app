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
    && chmod -R o+rX /var/lib/puzzles_da

# install jupyterlab
RUN pip3 --no-cache-dir install jupyterlab

# Install Python-based tools in a virtual environment
RUN python3 -m venv /opt/venv && \
    /opt/venv/bin/pip install --upgrade pip && \
    /opt/venv/bin/pip install \
    multiqc \
    cutadapt && \
    # Create symlinks to the venv binaries
    ln -s /opt/venv/bin/multiqc /usr/local/bin/ && \
    ln -s /opt/venv/bin/cutadapt /usr/local/bin/

# Install FastQC
RUN wget https://www.bioinformatics.babraham.ac.uk/projects/fastqc/fastqc_v0.12.1.zip && \
    unzip fastqc_v0.12.1.zip && \
    mv FastQC /opt/ && \
    chmod +x /opt/FastQC/fastqc && \
    ln -s /opt/FastQC/fastqc /usr/local/bin/fastqc && \
    rm fastqc_v0.12.1.zip

# Install samtools
RUN wget https://github.com/samtools/samtools/releases/download/1.18/samtools-1.18.tar.bz2 && \
    tar -xjf samtools-1.18.tar.bz2 && \
    cd samtools-1.18 && \
    ./configure --prefix=/usr/local && \
    make && \
    make install && \
    cd .. && \
    rm -rf samtools-1.18*

# Install hisat2
RUN wget https://cloud.biohpc.swmed.edu/index.php/s/fE9QCsX3NH4QwBi/download -O hisat2-2.2.1-Linux_x86_64.zip && \
    unzip hisat2-2.2.1-Linux_x86_64.zip && \
    cd hisat2-2.2.1/ && \
    make && \
    cd .. && \
    mv hisat2-2.2.1/hisat2* /usr/local/bin/ && \
    mv hisat2-2.2.1/extract_exons* /usr/local/bin/ && \
    rm -rf hisat2-2.2.1*

# Install subread
RUN wget https://sourceforge.net/projects/subread/files/subread-2.0.3/subread-2.0.3-Linux-x86_64.tar.gz/download -O subread-2.0.3-Linux-x86_64.tar.gz && \
    tar -xzf subread-2.0.3-Linux-x86_64.tar.gz && \
    cp -r subread-2.0.3-Linux-x86_64/bin/* /usr/local/bin/ && \
    rm -rf subread-2.0.3*

# Install bamtools
RUN apt-get update && apt-get install -y cmake && \
    git clone https://github.com/pezmaster31/bamtools.git && \
    cd bamtools && \
    mkdir build && \
    cd build && \
    cmake -DCMAKE_INSTALL_PREFIX=/usr/local .. && \
    make && \
    make install && \
    cd ../.. && \
    rm -rf bamtools && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Install salmon
RUN wget https://github.com/COMBINE-lab/salmon/releases/download/v1.10.0/salmon-1.10.0_linux_x86_64.tar.gz && \
    tar -xzf salmon-1.10.0_linux_x86_64.tar.gz  && \
    cp -r salmon-latest_linux_x86_64/bin/* /usr/local/bin/ && \
    cp -r salmon-latest_linux_x86_64/lib/* /usr/local/lib/ && \
    rm -rf salmon-1.10.1*


# Install STAR with required dependencies
RUN wget https://github.com/alexdobin/STAR/releases/download/2.7.11b/STAR_2.7.11b.zip && \
    unzip STAR_2.7.11b.zip && \
    cp STAR_2.7.11b/Linux_x86_64/STAR* /usr/local/bin/ && \
    rm -rf STAR_2.7.11b*

# Install QualiMap
RUN wget https://bitbucket.org/kokonech/qualimap/downloads/qualimap_v2.3.zip && \
    unzip qualimap_v2.3.zip && \
    mv qualimap_v2.3 /opt/qualimap && \
    echo '#!/bin/bash\njava -Xms32m -Xmx2g -jar /opt/qualimap/qualimap.jar "$@"' > /usr/local/bin/qualimap && \
    chmod +x /usr/local/bin/qualimap && \
    rm qualimap_v2.3.zip


#create a symlink for python as hisat2 hashbangs are set for python and not python3
RUN ln -s /usr/bin/python3 /usr/bin/python 

# Set up environment variables for the virtual environment
ENV PATH="/opt/venv/bin:$PATH"

# copy data
COPY docker/MPI/ /var/lib/MPI/
