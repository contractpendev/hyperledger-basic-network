
express = require 'express'
bodyParser = require 'body-parser'
fs = require 'fs'
asyncRedis = require 'async-redis'
ClusterWS = require 'clusterws'
findFreePort = require 'find-free-port'
execa = require 'execa'
commandLineArgs = require 'command-line-args'

class HyperledgerService

  constructor: (opts) ->
    console.log 'constructor in Hyperledger Service'
    @opts = opts

  # Startup hyperledger then quit itself 
  start: () =>
    optionDefinitions = [
      { name: 'command', defaultOption: true }
    ]
    try
      options = commandLineArgs(optionDefinitions)
      command = options.command
      if command == 'startInDocker'
        console.log 'start in docker'
        # ./createcard.sh
        try
          a = await execa('./createcard.sh',
            cwd: process.cwd() + '/../cli/'
          )        
          b = await execa('./startbna_helloworldstate.sh',
            cwd: process.cwd() + '/../cli/'
          )        
          c = await execa('./ping.sh',
            cwd: process.cwd() + '/../cli/'
          )        
        catch e 
          console.log e 
      else if command == 'startOutsideDocker' 
        try
          b = await execa('./generate.sh',
            cwd: process.cwd() + '/../'
          )
          c = await execa('./start_docker.sh',
            cwd: process.cwd() + '/../'
          )          
        catch e 
          console.log e 
      else 
        console.log 'need to use a command line option either as startInDocker or startOutsideDocker'    
    catch e
      console.log e  
    @opts.logger.log('info', 'Start of HyperledgerService')
    #console.log stdout

module.exports = HyperledgerService



