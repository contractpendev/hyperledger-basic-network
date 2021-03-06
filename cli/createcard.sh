cd ..
cd cli
cd ./../crypto-config/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp/keystore
export PRIV_KEYFILE=$(ls *_sk)
echo $PRIV_KEYFILE
PRIVATE_KEY=./../crypto-config/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp/keystore/$PRIV_KEYFILE
cd ../../../../../../../cli
CERT=./../crypto-config/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp/signcerts/Admin@org1.example.com-cert.pem
# Should the next line have the following network? -n helloworldstate to specify the network
composer card create -p ./connection.json -u PeerAdmin -c "$CERT" -k "$PRIVATE_KEY" -r PeerAdmin -r ChannelAdmin --file ./../crypto-config/PeerAdmin@hlfv12.card
composer card import --file ./../crypto-config/PeerAdmin@hlfv12.card 
composer card list



