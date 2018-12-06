
//var utils = require('fabric-client/lib/utils.js');
var Client = require('fabric-client');

function doubleAfter2Seconds(x) {
    return new Promise(resolve => {
      setTimeout(() => {
        resolve(x * 2);
      }, 2);
    });
  }

async function addAsync(x) {
    const a = await doubleAfter2Seconds(10);
    const b = await doubleAfter2Seconds(20);
    const c = await doubleAfter2Seconds(30);
    return x + a + b + c;
}

var client = Client.loadFromConfig('../cli/connection.json');
var o = client.getMspid();
var channel = client.getChannel();
var peers = channel.getPeers();
var firstPeer = peers[0];
console.log(firstPeer);
var p = firstPeer.getPeer();
console.log(p);


//console.log(firstPeer);
var c = client.queryInstalledChaincodes(p);
//console.log(c);


//var peers = client.getPeersForOrgOnChannel('');

//console.log(o);
//console.log(client);

//client.loadFromConfig('test/fixtures/org1.yaml');
