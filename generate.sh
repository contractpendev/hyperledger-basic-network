#!/bin/sh

export PATH=$GOPATH/src/github.com/hyperledger/fabric/build/bin:${PWD}/../bin:${PWD}:$PATH
export FABRIC_CFG_PATH=${PWD}/data/$1/
CHANNEL_NAME=mychannel

# remove previous crypto material and config transactions
rm -fr data/$1/config/*
rm -fr data/$1/bna/*
rm -fr data/$1

mkdir data/$1
mkdir data/$1/config
mkdir data/$1/bna

cp *.yaml data/$1/config/
cp config.json data/$1/config/config.json

# environment variables
rm -f data/$1/.env
#cd ./data/$1/crypto-config/peerOrganizations/org1.example.com/ca/
#OUTPUT="$(ls *_sk)"
#echo "${OUTPUT}"
#cd ../../../../../../
cp .env_original data/$1/.env
echo "COMPOSE_PROJECT_NAME=$1\n" > data/$1/.env
echo "COMPOSE_CONTROLLER_UUID=$2\n" >> data/$1/.env
echo "FABRIC_SERVER_CERTIFICATE_FILE=\n" >> data/$1/.env
#echo "FABRIC_SERVER_CERTIFICATE_FILE=${OUTPUT}\n" >> data/$1/.env

cp docker-compose.yml data/$1
cd data/$1
set -ev
docker-compose -f docker-compose.yml up -d hyperledgerfabrictools

# generate crypto material
docker exec $1.hyperledgerfabrictools cryptogen generate --config=/home/config/crypto-config.yaml --output=/home/config/crypto-config
# generate genesis block for orderer
docker exec $1.hyperledgerfabrictools configtxgen -profile OneOrgOrdererGenesis -outputBlock /home/config/genesis.block -configPath /home/config
# generate channel configuration transaction
docker exec $1.hyperledgerfabrictools configtxgen -profile OneOrgChannel -outputCreateChannelTx /home/config/channel.tx -channelID $CHANNEL_NAME -configPath /home/config
# generate anchor peer transaction
docker exec $1.hyperledgerfabrictools configtxgen -profile OneOrgChannel -outputAnchorPeersUpdate /home/config/Org1MSPanchors.tx -channelID $CHANNEL_NAME -asOrg Org1MSP -configPath /home/config

# Assume we are in data/$1/
rm -f .env
cd ./config/crypto-config/peerOrganizations/org1.example.com/ca/
OUTPUT="$(ls *_sk)"
echo "${OUTPUT}"
cd ../../../../../
cp ../../.env_original .env
echo "COMPOSE_PROJECT_NAME=$1\n" > .env
echo "COMPOSE_CONTROLLER_UUID=$2\n" >> .env
echo "FABRIC_SERVER_CERTIFICATE_FILE=${OUTPUT}\n" >> .env
cd ..
cd ..



