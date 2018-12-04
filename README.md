## Basic Network Config

The purpose of this project is to provide a easy way to run hyperledger fabric from docker.

Based upon the basic network from [Basic Network](https://github.com/hyperledger/fabric-samples/tree/master/basic-network)
 AND with the Hyperledger Exploer added to the docker-compose.yml.

Follow the startup steps at end of this document then open web browser to see Hyperledger Explorer at this URL ：http://localhost:8090/

I run this on a OSX Mac, but assume that it would also work on Linux.

## To start

1. Run ``./build.sh`` (if your on OSX Mac) to install tools for generate crypto material.
2. Run ``./gen1.sh`` to generate the crypto materials.
3. Run ``./gen2.sh`` to generate the channel crypto materials.
4. Run ``./gen3.sh`` to generate environment variable which is used for docker-compose.
5. Run ``./start.sh`` to start the docker containers running.
6. Now http://localhost:8090/ to see Hyperledger explorer is running.

## Creating card file and installing BNA

The creation of the card file and the installation of BNA must happen from within the Docker file execution environment.

7. ``docker exec -ti commandline /bin/bash``
8. ``cd cli``
9. ``./createcard.sh`` You will notice the PeerAdmin@hlfvv12.card file has been created
10. ``./startbna1.sh`` Should start fabcar@0.0.1.bna but it is timeout, why? cannot connect? The second line in startbna1.sh fails with timeout.

## Notes

Just for my notes the following changes.

The files which were added when compared with basic-network were.

1. The start.sh script was changed a little to add startup of blockchain-explorer-db and blockchain-explorer (referenced in docker-compose.yml).

2. The docker-compose.yml file changed to add blockchain-explorer-db and blockchain-explorer.

3. The postgreSQLdb folder created with creation script which is run from start.sh to populate the postgreSQL database which Hyperledger Explorer uses. This folders contents came from blockchain-explorer/app/persistence/fabric/postgreSQL/db in the blockchain-explorer project.

4. config.json was added and this file gets added to blockchain-explorer.
Its based upon https://github.com/hyperledger/blockchain-explorer/blob/master/examples/net1/config.json

5. Run ``./start.sh`` to startup all.

To stop it, run ``stop.sh``
To completely remove all on your system, run ``teardown.sh``.

## Good articles

https://topicfly.io/hyperledger-fabric-composer-swarm/

