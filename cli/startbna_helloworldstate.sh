composer network install --archiveFile basic-sample-network.bna --card PeerAdmin@net_basic
composer network start --card PeerAdmin@net_basic -n basic-sample-network -V 0.1.0 -A admin -S adminpw -f admin@basic-sample-network

