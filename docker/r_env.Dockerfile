#Set the image based on Ubuntu
FROM ubuntu:24.04

# Install necessary system dependencies & install python & install R
RUN apt-get update -y && apt-get install -y \
    wget \
    build-essential \
    python3 \
    python3-dev \
    python3-pip \
    r-base \
    locales


# install cutadapt
# RUN wget https://files.pythonhosted.org/packages/35/b4/f1a7401c3503c17998fb9547b04353217a18323d5d85a3b957f1049ab800/cutadapt-4.6.tar.gz && \
#     pip3 install cutadapt-4.6.tar.gz --break-system-packages

# Install R packages
RUN R -e "install.packages(c('ggplot2', 'scales', 'stringr', 'tidyr', 'dplyr', 'openxlsx', 'argparse', 'data.table'), repos='http://cran.rstudio.com/')"

# run to rm initial warning messages from R
RUN echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen \
   && locale-gen en_US.utf8 \
   && /usr/sbin/update-locale LANG=en_US.UTF-8