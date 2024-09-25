# Use a base image minconda
FROM continuumio/miniconda3


# Install software / dependencies for the bioinformatics tools, add nano, curl
# not sure which ones are needed for vsearch only but doesn't hurt to have them all (except build time)
RUN apt-get update && apt-get install -y \
    wget \
    build-essential \
    ca-certificates \
    gcc \
    git \
    ntpdate \
    make \
    libz-dev \
    git \
    tar \
    autoconf \
    automake \
    libtool \
    unzip \ 
    nano \ 
    curl

# Install VSEARCH: https://github.com/torognes/vsearch
RUN wget https://github.com/torognes/vsearch/archive/refs/tags/v2.28.1.tar.gz && \
    tar xf v2.28.1.tar.gz && \
    cd vsearch-2.28.1 && \
    ./autogen.sh && \
    ./configure && \
    make && \
    make install