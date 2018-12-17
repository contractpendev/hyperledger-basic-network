
express = require 'express'
bodyParser = require 'body-parser'
fs = require 'fs'
asyncRedis = require 'async-redis'
ClusterWS = require 'clusterws'
findFreePort = require 'find-free-port'
execa = require 'execa'
commandLineArgs = require 'command-line-args'
config = require 'config'
request = require 'request-json'

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
        password = config.get('server.password')
        # Check if this ssh server ip is ok with our ssh
        output = {}
        try
          output = await execa('/usr/bin/ssh-keygen', ['-F', serverIp])
          console.log output
        catch ex 
          output = ex 
        # output.code equals 0 is success
        if output.code != 0
          console.log 'ssh-keyscan running'
          await execa('/usr/bin/ssh-keyscan', ['-H', serverIp, '>>', '/root/.ssh/known_hosts'])
        console.log('just before execute reverse ssh')  
        # '-o', 'UserKnownHostsFile=/dev/null', 
        # '-o', 'StrictHostKeyChecking=no', 

        # Fetch a port from the server for reverse ssh to work 
        
        baseUrl = config.get('server.restBaseUrl')
        client = request.createClient(baseUrl)
        hyperledgerServerPortAndUuid = await client.post('proxyServiceApi/initFromHyperledgerClient', {})

        serverPort = hyperledgerServerPortAndUuid.body.serverPort
        uuid = hyperledgerServerPortAndUuid.body.uuid

        console.log 'uuid is ' + uuid

        try
          await execa('/usr/bin/sshpass', ['-p', password, 'ssh', '-N', '-R', serverPort.toString() + ':blockchain-explorer:8080', 'root@' + serverIp])   
        catch ex 
          console.log ex 
        console.log('after execute reverse ssh')  
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



