#!/bin/bash
# $1 is the project name
docker swarm init
cd contractpen_hyperledger_client
npm install
npm run compile
node src/EntryPoint.js startOutsideDocker --name=$1


