#!/bin/sh
# $1 is logical name from package.json inside the bna file
# $2 is the version from package.json inside the bna file
# $3 is the BNA file name with BNA at the end
#composer network list -c PeerAdmin@net_basic
#composer identity list -c PeerAdmin@net_basic
echo "$1\n" > out.txt
echo "$2\n" >> out.txt
echo "$3\n" >> out.txt
composer network install --archiveFile ./bna/$3 --card PeerAdmin@net_basic
composer network start --card PeerAdmin@net_basic -n $1 -V $2 -A admin -S adminpw -f ./crypto-config/admin@$1
composer card import --file ./crypto-config/admin@$1 --card admin@$1
#composer card list
# Workaround for a bug? https://github.com/hyperledger/composer/issues/4303#issuecomment-411304780
# or https://github.com/hyperledger/composer/issues/3944
# Need to do the following to activate the user?
composer network list -c admin@$1
composer identity list -c admin@$1
#composer transaction submit -c admin@acceptance-of-delivery -d '{"$class":"org.accordproject.acceptanceofdelivery.InspectDeliverable","deliverableReceivedAt":"January 1, 2018 16:34:00", "inspectionPassed": true}'
#/**
# * Execute the smart clause
# * @param {Context} context - the Accord context
# * @param {org.accordproject.helloworld.MyRequest} context.request - the incoming request
# * @param {org.accordproject.helloworld.MyResponse} context.response - the response
# * @param {org.accordproject.base.Event} context.emit - the emitted events
# * @param {org.accordproject.cicero.contract.AccordContractState} context.state - the state
# * @AccordClauseLogic
# */
#function orgXaccordprojectXhelloworldXHelloWorld_helloworld(context) {
