#!/bin/sh
#
# Copyright IBM Corp All Rights Reserved
#
# SPDX-License-Identifier: Apache-2.0
#
export PATH=$GOPATH/src/github.com/hyperledger/fabric/build/bin:${PWD}/../bin:${PWD}:$PATH
export FABRIC_CFG_PATH=${PWD}/data/$1/
CHANNEL_NAME=mychannel

# remove previous crypto material and config transactions
rm -fr data/$1/config/*
rm -fr data/$1/crypto-config/*

mkdir data/$1/config
mkdir data/$1/crypto-config

cp *.yaml data/$1
cp config.json data/$1/config.json

# generate crypto material
cryptogen generate --config=./crypto-config.yaml --output=./data/$1/crypto-config
if [ "$?" -ne 0 ]; then
  echo "Failed to generate crypto material..."
  exit 1
fi

# generate genesis block for orderer
configtxgen -profile OneOrgOrdererGenesis -outputBlock ./data/$1/config/genesis.block
if [ "$?" -ne 0 ]; then
  echo "Failed to generate orderer genesis block..."
  exit 1
fi

# generate channel configuration transaction
configtxgen -profile OneOrgChannel -outputCreateChannelTx ./data/$1/config/channel.tx -channelID $CHANNEL_NAME
if [ "$?" -ne 0 ]; then
  echo "Failed to generate channel configuration transaction..."
  exit 1
fi

# generate anchor peer transaction
configtxgen -profile OneOrgChannel -outputAnchorPeersUpdate ./data/$1/config/Org1MSPanchors.tx -channelID $CHANNEL_NAME -asOrg Org1MSP
if [ "$?" -ne 0 ]; then
  echo "Failed to generate anchor peer update for Org1MSP..."
  exit 1
fi

# environment variables
rm data/$1/.env
cp .env_original data/$1/.env
cd ./data/$1/crypto-config/peerOrganizations/org1.example.com/ca/
OUTPUT="$(ls *_sk)"
echo "${OUTPUT}"
cd ../../../../
cp data/$1/.env_original data/$1/.env
echo "${OUTPUT}" >> .env


