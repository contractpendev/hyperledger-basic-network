#!/bin/bash
#
# Copyright IBM Corp All Rights Reserved
#
# SPDX-License-Identifier: Apache-2.0
#
# Exit on first error, print all commands.
#
# $1 is the project name
cd data/$1
set -ev
cd ..

# don't rewrite paths for Windows Git Bash users
export MSYS_NO_PATHCONV=1

#docker-compose -f docker-compose.yml down
#mkdir data/$1
#mkdir data/$1/config
#mkdir data/$1/crypto-config

docker-compose -p $1 -f docker-compose.yml up -d ca.example.com orderer.example.com peer0.org1.example.com couchdb blockchain-explorer-db
#docker-compose -p test -f docker-compose.yml up ca.example.com
echo 'Sleeping for 10 seconds, please wait'
sleep 10s

docker exec -i "blockchain-explorer-db" bash /opt/createdb.sh

# docker-compose -f docker-compose.yml up -d hyperledger-explorer

# wait for Hyperledger Fabric to start
# incase of errors when running later commands, issue export FABRIC_START_TIMEOUT=<larger number>
export FABRIC_START_TIMEOUT=10
#echo ${FABRIC_START_TIMEOUT}
sleep ${FABRIC_START_TIMEOUT}

# Create the channel
docker exec -e "CORE_PEER_LOCALMSPID=Org1MSP" -e "CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/msp/users/Admin@org1.example.com/msp" peer0.org1.example.com peer channel create -o orderer.example.com:7050 -c mychannel -f /etc/hyperledger/configtx/channel.tx
# Join peer0.org1.example.com to the channel.
docker exec -e "CORE_PEER_LOCALMSPID=Org1MSP" -e "CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/msp/users/Admin@org1.example.com/msp" peer0.org1.example.com peer channel join -b mychannel.block

docker exec -e "CORE_PEER_LOCALMSPID=Org1MSP" -e "CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/msp/users/Admin@org1.example.com/msp" peer0.org1.example.com peer channel list
# peer channel list

docker-compose -p $1 -f docker-compose.yml up -d blockchain-explorer
docker-compose -p $1 -f docker-compose.yml up -d cli

docker-compose -p $1 -f docker-compose.yml up -d commandline

docker-compose -p $1 -f docker-compose.yml up -d hyperledgerclient