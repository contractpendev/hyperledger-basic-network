#!/bin/sh
# Inputs are a) the hyperledger folders name which is name of docker running and
# b) the bna file name
# c) The bna file name without extension
DATA_FOLDER="./data/$1/"
BNA_FILE_PATH="./data/$1/bna/$2"
DOCKER_COMMAND_IMAGE="$1.commandline"
echo "Current working directory is"
cwd
echo "The data folder relative to this path"
echo "${DATA_FOLDER}"
echo "The bna file path relative to this path"
echo "${BNA_FILE_PATH}"
echo "The docker image to execute commands inside is"
echo "${DOCKER_COMMAND_IMAGE}"
docker exec ${DOCKER_COMMAND_IMAGE} ./cli/startbna.sh $3 $2
