//var utils = require('fabric-client/lib/utils.js');
var Client = require('fabric-client');
const fs = require('fs');


function className(obj) {
  console.log(obj.constructor.toString());
};

function getAllMethods(object) {
  return Object.getOwnPropertyNames(object).filter(function(property) {
      return typeof object[property] == 'function';
  });
};

async function main() {
  var client = Client.loadFromConfig('../cli/connection.json');
  var mspId = client.getMspid();
  var channel = client.getChannel();
  var peers = channel.getPeers();
  var firstPeer = peers[0];
  var p = firstPeer.getPeer();

  dirPath = './../crypto-config/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp/keystore/';
  dir = fs.readdirSync(dirPath);
  file = dir[0];
  var privateKey = fs.readFileSync(dirPath + file, {encoding: 'utf8'});
  // Refer https://stackoverflow.com/questions/51095303/how-to-set-cert-when-calling-createchannel-in-fabric-node-sdk
  // Use the key from ../crypto-config/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp/keystore
  var certificate = fs.readFileSync('./../crypto-config/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp/signcerts/Admin@org1.example.com-cert.pem', {encoding: 'utf8'});
  client.setAdminSigningIdentity(privateKey, certificate, mspId);
  //client.newTransaction(true);
  var installedChaincodes = await client.queryInstalledChaincodes(p, true);
  //console.log('chaincodes');
  //console.log(installedChaincodes);
  var chaincodes = installedChaincodes.getChaincodes();
  for (var n = 0; n < chaincodes.length; n=n+1) {
    var code = chaincodes[n];
    console.log(code);
    console.log(getAllMethods(code));
    console.log(code.name + " " + code.version);
  }
}

(async () => {
  await main();
})().catch(e => {
  // Deal with the fact the chain failed
});
