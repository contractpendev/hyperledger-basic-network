#!/bin/bash
peer chaincode install -n cicero -v 1.0 -p "/root/nodejs/chaincode/" -l "node"
peer chaincode instantiate -o orderer.example.com:7050 -C mychannel -n cicero -l "node" -v 1.0 -c '{"Args":[""]}' -P "OR ('Org1MSP.member','Org2MSP.member')"
sleep 10
peer chaincode invoke -o orderer.example.com:7050 -C mychannel -n cicero -c '{"function":"initLedger","Args":[""]}'
rm -rf hfc-key-store
node enrollAdmin.js
node registerUser.js
node deploy.js "helloworld.cta" sample.txt
#node submitRequest.js request.json 
#node deploy.js helloworld@0.8.0.cta sample.txt
