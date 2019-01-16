#!/bin/sh
# $1 is logical name from package.json inside the bna file
# $2 is the version from package.json inside the bna file
# $3 is the BNA file name with BNA at the end
echo "one"
composer network install --archiveFile ./bna/$3 --card PeerAdmin@net_basic
echo "two"
# composer network start --card PeerAdmin@net_basic -n acceptance-of-delivery_awzqs9zlr -V 0.8.0 -A admin -S adminpw -f ./crypto-config/admin@test
composer network start --card PeerAdmin@net_basic -n $1 -V $2 -A admin -S adminpw -f ./crypto-config/admin@$1
echo "three"
composer card import --file ./crypto-config/admin@$1 --card admin@$1
echo "four"
composer card list
