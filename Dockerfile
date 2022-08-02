# Base image
FROM ubuntu:18.04

ENV DEBIAN_FRONTEND=noninteractive

# Enable Networking on port 8001 (apache)
EXPOSE 8001

# Install dependencies
RUN apt-get update && apt-get install -y \
    locales \
    git \
    wget curl gnupg \
    python3-pip virtualenv libsm6 libxrender1 libfontconfig1 \
    apache2 libapache2-mod-wsgi-py3 \
    && rm -rf /var/lib/apt/lists/*

# install latest node
RUN curl -sL https://deb.nodesource.com/setup_16.x  | bash - && apt-get -y install nodejs

# setup locale
RUN locale-gen en_US.UTF-8

# setup basic npm packages
RUN npm install npm@latest -g && npm install -g @angular/cli

# basic dirs
RUN mkdir -p /opt

# Clone this deployment repository
RUN git clone --recursive http://github.com/SMNF-Project/chantlab_deploy.git

# Set up apache
RUN cp chantlab_deploy/chantlab_deploy/deploy/apache2.conf /etc/apache2/sites-available/chantlab.conf && a2ensite chantlab.conf && apachectl configtest

# Run deploy script steps
RUN cd chantlab_deploy && python3 chantlab_deploy/deploy.py --client --dbdir /opt/chantlab/storage
RUN cd chantlab_deploy && python3 chantlab_deploy/deploy.py --venv --dbdir /opt/chantlab/storage
RUN cd chantlab_deploy && python3 chantlab_deploy/deploy.py --server --dbdir /opt/chantlab/storage
RUN cd chantlab_deploy && python3 chantlab_deploy/deploy.py --serversettings --dbdir /opt/chantlab/storage
RUN cd chantlab_deploy && python3 chantlab_deploy/deploy.py --staticfiles --dbdir /opt/chantlab/storage
RUN cd chantlab_deploy && python3 chantlab_deploy/deploy.py --migrations --dbdir /opt/chantlab/storage

# launch apache
CMD apachectl -D FOREGROUND
