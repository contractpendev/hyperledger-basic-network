#!/bin/bash
# $1 is the project name
# @todo Check git, docker and node are installed
cd contractpen-hyperledger-client
npm install
npm run compile
node src/EntryPoint.js startOutsideDocker --name=$1


