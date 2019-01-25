#!/bin/sh
# $1 The docker image name to run the command in
# $2 is logical name from package.json inside the bna file
# $3 is the version from package.json inside the bna file
# $4 is the BNA file name with BNA at the end
docker exec $1 ./cli/startbna.sh $2 $3 $4
