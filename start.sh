#!/bin/bash
# $1 is the project name
docker swarm init --advertise-addr 172.17.0.1 --listen-addr 0.0.0.0
cd docker
. ./build.sh
cd ..
cd contractpen-hyperledger-client
npm install
npm run compile
node src/EntryPoint.js startOutsideDocker --name=$1


