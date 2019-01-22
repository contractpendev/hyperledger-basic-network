#!/bin/bash
# $1 is the project name
# @todo Check git, docker and node are installed
docker swarm init --advertise-addr 172.17.0.1 --listen-addr 0.0.0.0
cd docker
cd command-line
. ./build.sh
cd ..
cd hyperledger-explorer-patched
. ./build.sh
cd ..
cd ..
cd contractpen-hyperledger-client
npm install
npm run compile
node src/EntryPoint.js startOutsideDocker --name=$1


