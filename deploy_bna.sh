#!/bin/sh
echo "./cli/startbna.sh $2 $3 $4"
docker exec $1 -c "./cli/startbna.sh $2 $3 $4"
