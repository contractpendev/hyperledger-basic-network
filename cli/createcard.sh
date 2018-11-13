#PRIVATE_KEY=./../crypto-config/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/msp/keystore/21ca26615fc28e4da5b7057cd862ea78477b871ab9cb7df83801c6bc840ffa0f_sk
#CERT=./../crypto-config/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/msp/admincerts/Admin@org1.example.com-cert.pem

PRIVATE_KEY=./../crypto-config/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp/keystore/ee740c18c4ea0c4c3f013a0bd3cd64a3b18827ab81a3e6fe3fe93473581e1346_sk
CERT=./../crypto-config/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp/admincerts/Admin@org1.example.com-cert.pem
composer card create -p ./connection.json -u PeerAdmin -n net_basic -c "$CERT" -k "$PRIVATE_KEY" -r PeerAdmin -r ChannelAdmin --file ./PeerAdmin@net_basic.card
composer card import --file ./PeerAdmin@net_basic.card 


