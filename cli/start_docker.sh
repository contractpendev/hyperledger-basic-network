#!/bin/bash
#
# Copyright IBM Corp All Rights Reserved
#
# SPDX-License-Identifier: Apache-2.0
#
# Exit on first error, print all commands.
#
# $1 is the project name
cp docker-compose.yml data/$1
cd data/$1
set -ev
# don't rewrite paths for Windows Git Bash users
export MSYS_NO_PATHCONV=1
docker-compose -f docker-compose.yml up -d ca.example.com orderer.example.com peer0.org1.example.com couchdb blockchain-explorer-db
#echo '1 Sleeping for 40 seconds, please wait'
sleep 30s
docker exec -i $1.blockchain-explorer-db bash /opt/createdb.sh
# Create the channel
docker exec -e "CORE_PEER_LOCALMSPID=Org1MSP" -e "CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/msp/users/Admin@org1.example.com/msp" $1.peer0.org1.example.com peer channel create -o $1.orderer.example.com:7050 -c mychannel -f /etc/hyperledger/configtx/channel.tx
# Join peer0.org1.example.com to the channel.
docker exec -e "CORE_PEER_LOCALMSPID=Org1MSP" -e "CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/msp/users/Admin@org1.example.com/msp" $1.peer0.org1.example.com peer channel join -b mychannel.block
docker exec -e "CORE_PEER_LOCALMSPID=Org1MSP" -e "CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/msp/users/Admin@org1.example.com/msp" $1.peer0.org1.example.com peer channel list
docker-compose -f docker-compose.yml up -d blockchain-explorer
docker exec $1.blockchain-explorer /bin/sh -c 'cd /opt/explorer/client; npm run build'
docker-compose -f docker-compose.yml up -d cli
docker-compose -f docker-compose.yml up -d hyperledgerclient
