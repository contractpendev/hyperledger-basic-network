#!/bin/sh
# $1 is logical name from package.json inside the bna file
# $2 is the version from package.json inside the bna file
# $3 is the BNA file name with BNA at the end
cd ..
cd cli
echo $1
echo $2
echo $3
echo "Installing card"
composer network install --archiveFile ./../bna/$3 --card PeerAdmin@net_basic
echo "Starting"
composer network start --card PeerAdmin@net_basic -n $1 -V $2 -A admin -S adminpw -f ./../crypto-config/admin@$1
composer card import --file ./../crypto-config/admin@$1 --card admin@$1
composer card list
