#!/bin/sh
# $1 is the BNA file name without file extension BNA at the end
# $2 is the BNA file name with BNA at the end
# Assume card exists at ./../crypto-config/PeerAdmin@hlfv12.card 
composer network install --archiveFile ./../bna/$2 --card PeerAdmin@net_basic
composer network start --card PeerAdmin@net_basic -n $1 -V 0.9.1 -A admin -S adminpw -f ./../crypto-config/admin@$1
composer card import --file ./../crypto-config/admin@$1 --card admin@$1
composer card import --file ./../crypto-config/admin@$1
composer card list
