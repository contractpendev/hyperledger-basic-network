//var utils = require('fabric-client/lib/utils.js');
var Client = require('fabric-client');
const fs = require('fs');
const path = require('path');
const Fabric_CA_Client = require('fabric-ca-client');

function className(obj) {
  console.log(obj.constructor.toString());
};

function getAllMethods(object) {
  return Object.getOwnPropertyNames(object).filter(function(property) {
      return typeof object[property] == 'function';
  });
};

async function main() {

  try {
    var client = Client.loadFromConfig('../cli/connection.json');
    var mspId = client.getMspid();
    var channel = client.getChannel();
    var peers = channel.getPeers();
    var firstPeer = peers[0];
    var p = firstPeer.getPeer();

    const storePath = path.join(__dirname, 'hfc-key-store');
    var stateStore = await Client.newDefaultKeyValueStore({ path: storePath });
    client.setStateStore(stateStore);
    const cryptoSuite = Client.newCryptoSuite();
    const cryptoStore = Client.newCryptoKeyStore({ path: storePath });
    cryptoSuite.setCryptoKeyStore(cryptoStore);
    client.setCryptoSuite(cryptoSuite);

    dirPath = './../crypto-config/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp/keystore/';
    dir = fs.readdirSync(dirPath);
    file = dir[0];
    var privateKey = fs.readFileSync(dirPath + file, {encoding: 'utf8'});
    // Refer https://stackoverflow.com/questions/51095303/how-to-set-cert-when-calling-createchannel-in-fabric-node-sdk
    // Use the key from ../crypto-config/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp/keystore
    var certificate = fs.readFileSync('./../crypto-config/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp/signcerts/Admin@org1.example.com-cert.pem', {encoding: 'utf8'});
    client.setAdminSigningIdentity(privateKey, certificate, mspId);
    const admin_user = await client._setUserFromConfig({username: 'admin', password: 'adminpw'});

    var installedChaincodes = await client.queryInstalledChaincodes(p, true);
    var chaincodes = installedChaincodes.getChaincodes();
    for (var n = 0; n < chaincodes.length; n=n+1) {
      var code = chaincodes[n];
    }
    console.log('user is enrolled: ' + admin_user.isEnrolled());
 
    var txId = client.newTransactionID();
    const contractId = 'arg1';
    const requestJSON = {
      name: '1'
    };
    const tx = {
      fcn: 'executeSmartLegalContract',
      args: [contractId, JSON.stringify(requestJSON)],
    };
    const request = Object.assign(tx, {
      txId,
      chaincodeId: 'helloworld'
      //chainId: 'mychannel',
    });
    // send the transaction proposal to the peers
    const r = await channel.sendTransactionProposal(request);
    console.log(r);
    
  } catch (ex) {
    console.log(ex);
  }




  /*const contractId = 'MYCONTRACT';
  const request = {
    fcn: 'executeSmartLegalContract',
    args: [contractId, JSON.stringify(requestJSON)],
  };*/

  /*const request = Object.assign(tx, {
    txId,
    chaincodeId: config.chaincodeId,
    chainId: config.chainId,
  });*/
    // send the transaction proposal to the peers
//  return channel.sendTransactionProposal(request);

  
}

(async () => {
  await main();
})().catch(e => {
  // Deal with the fact the chain failed
});
