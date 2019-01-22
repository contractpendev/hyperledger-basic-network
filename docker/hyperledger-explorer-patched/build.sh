#!/bin/bash
git clone https://github.com/hyperledger/blockchain-explorer.git
rm ./blockchain-explorer/client/src/services/request.js
cp ./hyperledger-explorer-patch/request.js ./blockchain-explorer/client/src/services/
cd ./blockchain-explorer
docker build -t contractpen/hyperledger-explorer-patched .
cd ..