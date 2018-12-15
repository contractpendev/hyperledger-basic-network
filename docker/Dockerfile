# set the base image to Debian
# https://hub.docker.com/_/debian/
FROM debian:latest

# replace shell with bash so we can source files
RUN rm /bin/sh && ln -s /bin/bash /bin/sh

# update the repository sources list
# and install dependencies
RUN apt-get update \
    && apt-get install -y curl \
    && apt-get -y autoclean

# nvm environment variables
ENV NVM_DIR /usr/local/nvm
ENV NODE_VERSION 8.12.0

# install nvm
# https://github.com/creationix/nvm#install-script
RUN curl --silent -o- https://raw.githubusercontent.com/creationix/nvm/v0.31.2/install.sh | bash

# install node and npm
RUN source $NVM_DIR/nvm.sh \
    && nvm install $NODE_VERSION \
    && nvm alias default $NODE_VERSION \
    && nvm use default

# add node and npm to path so the commands are available
ENV NODE_PATH $NVM_DIR/v$NODE_VERSION/lib/node_modules
ENV PATH $NVM_DIR/versions/node/v$NODE_VERSION/bin:$PATH

# confirm installation
RUN node -v
RUN npm -v

RUN apt-get update && apt-get install -y --no-install-recommends python3.5 python3-pip
RUN apt-get install -y build-essential libssl-dev libffi-dev python-dev
#RUN ln -s /usr/bin/python3 /usr/bin/python

RUN npm config set unsafe-perm=true
RUN npm install -g composer-rest-server
RUN npm install -g composer-cli

# Needed for reverse ssh tunnel code
RUN apt-get install -y openssh-client
RUN apt-get install -y sshpass

#RUN composer card import --file ./PeerAdmin@hlfv12.card


