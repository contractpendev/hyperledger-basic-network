# Its NOT these keys because it says the following
# Error: Error trying to ping. Error: 2 UNKNOWN: access denied: channel [mychannel] creator org [Org1MSP]
#PRIVATE_KEY=./../crypto-config/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/msp/keystore/21ca26615fc28e4da5b7057cd862ea78477b871ab9cb7df83801c6bc840ffa0f_sk
#CERT=./../crypto-config/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/msp/admincerts/Admin@org1.example.com-cert.pem
# I think these keys are correct BECAUSE it allows connection
PRIVATE_KEY=./../crypto-config/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp/keystore/ee740c18c4ea0c4c3f013a0bd3cd64a3b18827ab81a3e6fe3fe93473581e1346_sk
CERT=./../crypto-config/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp/admincerts/Admin@org1.example.com-cert.pem
# Should the next line have the following network? -n net_basic
composer card create -p ./connection.json -n fabcar -u PeerAdmin -c "$CERT" -k "$PRIVATE_KEY" -r PeerAdmin -r ChannelAdmin --file ./PeerAdmin@fabcar.card
composer card import --file ./PeerAdmin@fabcar.card 
composer card list




