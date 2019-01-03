composer network install --archiveFile test.bna --card PeerAdmin@net_basic
composer network start --card PeerAdmin@net_basic -n volumediscount -V 0.9.1 -A admin -S adminpw -f admin@volumediscount
composer card import --file admin@volumediscount --card admin@volumediscount
composer card import --file ./admin@volumediscount
composer card list
