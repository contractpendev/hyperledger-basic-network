## Basic Network Config

The goal of this project is to have a simple Hyperledger network working via docker based upon the basic network from [Basic Network](https://github.com/hyperledger/fabric-samples/tree/master/basic-network)
 AND with the Hyperledger Exploer added to the docker-compose.yml.

 Currently Hyperledger Explorer Browser cannot connect to the blockchain network. So if after starting with ``./start.sh`` then if ``docker logs blockchain-explorer`` it will show the problem is that here it cannot connect:

 Please open web browser to access ：http://localhost:8080/

```
pid is 6


postgres://hppoc:password@blockchain-explorer-db:5432/explorer_db_name

Sync process is started for the network : [network-1] and client : [client-1]
<<<<<<<<<<<<<<<<<<<<<<<<<< Synchronizer Error >>>>>>>>>>>>>>>>>>>>>
Error :  [ 'Failed to connect client peer, please check the configuration and peer status' ]
<<<<<<<<<<<<<<<<<<<<<<<<<< Closing client processor >>>>>>>>>>>>>>>>>>>>>
```

The files which were added when compared with basic-network were.

1. The start.sh script was changed a little to add startup of blockchain-explorer-db and blockchain-explorer (referenced in docker-compose.yml).

2. The docker-compose.yml file changed to add blockchain-explorer-db and blockchain-explorer.

3. The postgreSQLdb folder created with creation script which is run from start.sh to populate the postgreSQL database which Hyperledger Explorer uses. This folders contents came from blockchain-explorer/app/persistence/fabric/postgreSQL/db in the blockchain-explorer project.

4. config.json was added and this file gets added to blockchain-explorer.

## To start

To start the network on Mac OSX do step 1, other continue at step 2.

1. Run ``./build.sh`` to install tools for generate crypto material.
2. Create the config.json file in folder blockchain-explorer/examples/dockerConfig/config.json to match crypt-config.yaml and configtx.yaml
3. Run ``./generate.sh`` to generate the crypto materials.
4. Run ``./start.sh`` to startup all.

To stop it, run ``stop.sh``
To completely remove all incriminating evidence of the network
on your system, run ``teardown.sh``.
