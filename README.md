## Basic Network Config

The goal of this project is to have a simple Hyperledger network working via docker based upon the basic network from https://github.com/hyperledger/fabric-samples/tree/master/basic-network.

To start the network on Mac OSX do step 1, other continue at step 2.

1. Run ``./build.sh`` to install tools for generate crypto material.
2. Create the config.json file in folder blockchain-explorer/examples/dockerConfig/config.json to match crypt-config.yaml and configtx.yaml
3. Run ``./generate.sh`` to generate the crypto materials.
4. Run ``./start.sh`` to startup all.

To stop it, run ``stop.sh``
To completely remove all incriminating evidence of the network
on your system, run ``teardown.sh``.
