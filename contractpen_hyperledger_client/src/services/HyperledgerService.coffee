
express = require 'express'
bodyParser = require 'body-parser'
fs = require 'fs'
asyncRedis = require 'async-redis'
ClusterWS = require 'clusterws'
findFreePort = require 'find-free-port'
execa = require 'execa'

class HyperledgerService

  constructor: (opts) ->
    console.log 'constructor in Hyperledger Service'
    @opts = opts

  start: () =>
    @opts.logger.log('info', 'Start of HyperledgerService')
    stdout = await execa 'bash', [ './start_docker.sh' ],
      cwd: process.cwd() + '/../'
    console.log stdout

module.exports = HyperledgerService



