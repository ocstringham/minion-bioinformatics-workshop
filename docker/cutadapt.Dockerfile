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
    curl \
    python3 \
    python3-dev \
    python3-pip


# install cutadapt
RUN pip3 install cutadapt