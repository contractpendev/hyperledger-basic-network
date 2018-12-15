
express = require 'express'
bodyParser = require 'body-parser'
fs = require 'fs'
asyncRedis = require 'async-redis'
ClusterWS = require 'clusterws'
findFreePort = require 'find-free-port'
execa = require 'execa'
commandLineArgs = require 'command-line-args'
config = require 'config'

class HyperledgerService

  constructor: (opts) ->
    console.log 'constructor in Hyperledger Service'
    @opts = opts

  reverseProxy: () =>
    serverIp = config.get('server.ipAddress')
    serverPassword = config.get('server.password')
    output = await execa('ssh-keygen -F ' + serverIp)
    console.log output
    # if [ -z `ssh-keygen -F $IP` ]; then
    # ssh-keyscan -H IPADDRESS >> ~/.ssh/known_hosts 
    # fi
    # sshpass -p 'PASSWORD' ssh -N -R 2210:localhost:8090 root@IPADDRESS

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
        serverIp = config.get('server.ipAddress')
        output = await execa('ssh-keygen -F ' + serverIp)
        console.log output        
        # ./createcard.sh
        #try
        #  a = await execa('./createcard.sh',
        #    cwd: process.cwd() + '/../cli/'
        #  )        
        #  b = await execa('./startbna_helloworldstate.sh',
        #    cwd: process.cwd() + '/../cli/'
        #  )        
        #  c = await execa('./ping.sh',
        #    cwd: process.cwd() + '/../cli/'
        #  )    
          # Setup reverse ssh
        #  await @reverseProxy()
        #catch e 
        #  console.log e 
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



