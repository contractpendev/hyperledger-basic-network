#!/bin/bash
DOES_DOCKER_NETWORK_EXIST=$(docker network ls | grep hyperledger-network-no-internet-0)
if [ ${#DOES_DOCKER_NETWORK_EXIST} -lt 1 ]
then
i=0
end=255
while [ $i -le $end ]; do
    docker network create -d bridge --subnet=172.18.$i.0/24 hyperledger-network-no-internet-$i
    docker network create -d bridge --subnet=172.19.$i.0/24 hyperledger-network-public-$i
    i=$(($i+1))
done
fi
