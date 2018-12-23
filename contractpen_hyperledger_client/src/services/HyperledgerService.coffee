
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
WebSocket = require('ws')
uuidv4 = require 'uuid/v4'

class HyperledgerService

  constructor: (opts) ->
    console.log 'constructor in Hyperledger Service'
    @opts = opts
    @uuid = uuidv4()

  reverseProxy: () =>
    serverIp = config.get('server.ipAddress')
    serverPassword = config.get('server.password')
    output = await execa('ssh-keygen -F ' + serverIp)
    console.log output
    # if [ -z `ssh-keygen -F $IP` ]; then
    # ssh-keyscan -H IPADDRESS >> ~/.ssh/known_hosts 
    # fi
    # sshpass -p 'PASSWORD' ssh -N -R 2210:localhost:8090 root@IPADDRESS

  startServer: () =>
    console.log 'start server'
    websocketBaseUrl = config.get('server.websocketBaseUrl')
    # Submit uuid to the server via REST API

    # Submit uuid to the pubsub server to listen for commands
    @ws = new WebSocket(websocketBaseUrl + 'echo')
    console.log 'just before...'
    @ws.on 'open', =>
      data =
        command: 'listenForCommands'
        uuid: @uuid
      dataJson = JSON.stringify(data) 
      console.log 'before send' 
      @ws.send dataJson
      console.log 'after send' 
      return
    @ws.on 'message', (data) =>
      dataJson = JSON.parse(data)
      console.log dataJson
      if dataJson.command == 'listenForCommandsResult'
        baseUrl = config.get('server.restBaseUrl')
        client = request.createClient(baseUrl)
        await client.post('proxyServiceApi/hyperledgerClientAwaitingCommands', {uuid: @uuid})
      return

  # Startup hyperledger then quit itself 
  start: () =>
    optionDefinitions = [
      { name: 'command', defaultOption: true },
      { name: 'name', alias: 'n', type: String }
    ]
    try
      options = commandLineArgs(optionDefinitions)
      command = options.command
      if command == 'startInDocker'
        console.log 'start in docker'
        console.log 'project name is :' + options.name + ':'
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
          await execa('/usr/bin/sshpass', ['-p', password, 'ssh', '-o', 'UserKnownHostsFile=/dev/null', '-o', 'StrictHostKeyChecking=no', '-N', '-R', serverPort.toString() + ':blockchain-explorer:8080', 'root@' + serverIp])   
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
        if options.name
          console.log 'project name is :' + options.name + ':'
          try
            b = await execa('./generate.sh', [options.name],
              cwd: process.cwd() + '/../'
            )
            c = await execa('./start_docker.sh', [options.name],
              cwd: process.cwd() + '/../'
            )          
          catch e 
            console.log e 
        else 
          console.log 'starting as a server'   
          @startServer()
      else 
        console.log 'need to use a command line option either as startInDocker or startOutsideDocker'    
    catch e
      console.log e  
    @opts.logger.log('info', 'Start of HyperledgerService')
    #console.log stdout

module.exports = HyperledgerService



