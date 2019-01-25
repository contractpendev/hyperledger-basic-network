## Basic Network Config

The purpose of this project is to provide a easy way to run hyperledger fabric from docker.

Based upon the basic network from [Basic Network](https://github.com/hyperledger/fabric-samples/tree/master/basic-network)
 AND with the Hyperledger Exploer added to the docker-compose.yml.

I run this on a OSX Mac, but assume that it would also work on Linux.

## To start

1. Run ``./build.sh`` (if your on OSX Mac) to install tools for generate crypto material.
2. Run ``./generate.sh`` to generate environment variable which is used for docker-compose.
3. Run ``./start.sh`` to start the docker containers running.
4. Now http://localhost:8090/ to see Hyperledger explorer is running.

## Creating card file and installing BNA

The creation of the card file and the installation of BNA must happen from within the Docker file execution environment.

5. ``cd cli``
6. ``./shell.sh`` This enters a shell in the docker container /bin/bash.
7. ``cd cli``
8. ``./createcard.sh`` You will notice the PeerAdmin@hlfv12.card file has been created
9. ``./startbna_helloworldstate.sh`` Starts the network and creates another card.
10. ``./ping.sh`` Successfully pings the network.
11. ``./restserver.sh`` Starts composer rest server on port 3000 with the card generated from the ./startbna_helloworldstate.sh.

## Notes

Just for my notes the following changes.

The files which were added when compared with basic-network were.

1. The start.sh script was changed a little to add startup of blockchain-explorer-db and blockchain-explorer (referenced in docker-compose.yml).

2. The docker-compose.yml file changed to add blockchain-explorer-db and blockchain-explorer.

3. The postgreSQLdb folder created with creation script which is run from start.sh to populate the postgreSQL database which Hyperledger Explorer uses. This folders contents came from blockchain-explorer/app/persistence/fabric/postgreSQL/db in the blockchain-explorer project.

4. config.json was added and this file gets added to blockchain-explorer.
Its based upon https://github.com/hyperledger/blockchain-explorer/blob/master/examples/net1/config.json

5. Run ``./start.sh`` to startup all.

To remove crypto materials, run ``clean.sh``.
To stop it, run ``stop.sh``.
To completely remove all on your system, run ``teardown.sh``.

## Good articles

https://topicfly.io/hyperledger-fabric-composer-swarm/

https://console.cloud.google.com/marketplace/details/click-to-deploy-images/hyperledger-fabric-and-composer?pli=1

## Tasks to do

1. Try to make the number of ports open to public minimal and keep all private, identify the minimum private network settings that can be done. I've already done a little of this in docker-compose.yml NOW and need to test if its correct.
2. Make one single script that when given a BNA file it will install the BNA file and open a port for composer rest server to allow REST interaction with the deployed thing. So the inputs are - a) BNA file b) port to open for composer rest service (or it returns it back since each BNA will need its own rest service) c) Blockchain explorer port to provide visibility.
3. Server goes through the process of a) user click to deploy BNA file b) BNA file generated c) server sshs to other machine to control and deploy BNA and deployment happens and ports and given back to server c) server opens page on these ports.
4. 