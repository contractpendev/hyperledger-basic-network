
In here I am attempting to use the composer command line to connect to hyperledger.

Install the composer-cli as follows.

```npm install composer-cli -g```

I created a connection.json file, I think this file has the correct contents.

You will need to edit the file createcard.sh to place the correct key name in here. See path ./../crypto-config/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/msp/keystore/

Then run ./createcard.sh which should create the file PeerAdmin@hlfv1.card

Then run ./ping.sh which shows the following.

```
$ ./ping.sh
Error: Error trying to ping. Error: No business network has been specified for this connection
Command failed

$ 
```
