
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
download = require 'download'

class HyperledgerService

  constructor: (opts) ->
    console.log 'constructor in Hyperledger Service'
    @opts = opts
    @uuid = uuidv4()
    @secretKey = config.get('server.secretKey')
    @composeControllerUuid = null

  reverseProxy: () =>
    serverIp = config.get('server.ipAddress')
    serverPassword = config.get('server.password')
    output = await execa('ssh-keygen -F ' + serverIp)
    console.log output
    # if [ -z `ssh-keygen -F $IP` ]; then
    # ssh-keyscan -H IPADDRESS >> ~/.ssh/known_hosts 
    # fi
    # sshpass -p 'PASSWORD' ssh -N -R 2210:localhost:8090 root@IPADDRESS

  startHyperledgerInstance: (name, uuid) =>
    console.log 'we are outside docker and going to start instance by name for name :' + name + ':'  
    try
      b = await execa('./generate.sh', [name, uuid],
        cwd: process.cwd() + '/../'
      )
      c = await execa('./start_docker.sh', [name],
        cwd: process.cwd() + '/../'
      )          
    catch e 
      console.log e 

      

  sendPing: () =>
    ping =
      command: 'ping'
      secretKey: @secretKey
    console.log 'sendPing'  
    @ws.send JSON.stringify(ping)
    setTimeout (@sendPing
    ), (10*1000)

  startServer: () =>
    console.log 'start server'
    websocketBaseUrl = config.get('server.websocketBaseUrl')
    # Submit uuid to the server via REST API

    # Submit uuid to the pubsub server to listen for commands
    @ws = new WebSocket(websocketBaseUrl + 'echo')
    console.log 'just before...'
    @ws.on 'close', =>
      console.log 'the websocket closed, why?'
    @ws.on 'open', =>
      data =
        command: 'listenForCommands'
        uuid: @uuid
        secretKey: @secretKey
      console.log 'uuid of client started outside of docker is sent to the server via websocket as command listenForCommands ' + @uuid
      dataJson = JSON.stringify(data) 
      @ws.send dataJson
      setTimeout (@sendPing
      ), (10*1000)
      return
    @ws.on 'message', (data) =>
      dataJson = JSON.parse(data)
      console.log 'websocket message from server is'
      console.log dataJson
      if dataJson.command == 'deployBnaToHyperledgerInstance'
        name = dataJson.name
        console.log ''
        console.log ''
        console.log 'command is ' + dataJson.command
        console.log 'task should be to download the bna and place it in directory data/' + name + '/bna'
        console.log 'the filename is ' + dataJson.bnaFileName
        # archive_0f0ec513-daba-42e5-8ec5-13daba62e5c4.bna
        downloadUrl = 'https://contractpen.com/file/download/accordZip?file=' + dataJson.bnaFileName
        bnaDest = './data/' + name + '/bna/' + dataJson.bnaFileName
        await download(downloadUrl).pipe(fs.createWriteStream(bnaDest))
        console.log 'then to execute a shell script to deploy the bna to that hyperledger'
        console.log 'need to know the bna file name!'
        console.log ''
      if dataJson.command == 'listenForCommandsResult'
        baseUrl = config.get('server.restBaseUrl')
        client = request.createClient(baseUrl)
        await client.post('proxyServiceApi/hyperledgerClientAwaitingCommands', 
          secretKey: @secretKey
          uuid: @uuid
        )
      if dataJson.command == 'startHyperledgerInstance'  
        name = dataJson.hyperledgerName
        baseUrl = config.get('server.restBaseUrl')
        client = request.createClient(baseUrl)        
        await client.post('proxyServiceApi/attemptingToStartHyperledgerClient', 
          secretKey: @secretKey
          hyperledgerName: name
        )      
        # Start it
        # Once started then store the name and tell server it is started
        await @startHyperledgerInstance name, @uuid
      if dataJson.command == 'startMultipleHyperledgerInstances'  
        total = dataJson.total

        numbers = [1..total]

        names = numbers.map((n) ->
          'hyperledger-' + uuidv4()
        )
        console.log names

        # Here create total names in an array and then send that to the server and attempt to start them 
        baseUrl = config.get('server.restBaseUrl')
        client = request.createClient(baseUrl)        
 
        # Start it
        # Once started then store the name and tell server it is started
        for name in names
          console.log 'Attempting to start hyperledger with name :' + name + ':'
          await client.post('proxyServiceApi/attemptingToStartHyperledgerClient', 
            secretKey: @secretKey
            hyperledgerName: name
          )      
          await @startHyperledgerInstance name, @uuid
          console.log 'finished start hyperledger :' + name + ':'

      return

  # Startup hyperledger then quit itself 
  start: () =>
    optionDefinitions = [
      { name: 'command', defaultOption: true },
      { name: 'name', alias: 'n', type: String },
      { name: 'composeControllerUuid', alias: 'c', type: String }
    ]
    try
      options = commandLineArgs(optionDefinitions)
      console.log 'options are'
      console.log options
      console.log ''
      command = options.command
      if command == 'startInDocker'
        console.log 'The parent is ' + options.composeControllerUuid
        @composeControllerUuid = options.composeControllerUuid
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
        hyperledgerServerPortAndUuid = await client.post('proxyServiceApi/initFromHyperledgerClient', {
          name: options.name
          composeControllerUuid: options.composeControllerUuid
          secretKey: @secretKey
        })

        serverPort = hyperledgerServerPortAndUuid.body.serverPort
        uuid = hyperledgerServerPortAndUuid.body.uuid

        console.log 'uuid is ' + uuid

        # Lets assume the next command will work successfully, so then we should tell server we have started
        resultOfStart = await client.post('proxyServiceApi/finishSetupHyperledgerClient', {
          name: options.name
          uuid: uuid
          serverPort: serverPort
          secretKey: @secretKey
        })

        #  -o "ServerAliveInterval 60" -o "ServerAliveCountMax 120" 
        try
          await execa('nohup', ['/usr/bin/sshpass', '-p', password, 'ssh', '-o', 'ServerAliveInterval=60', '-o', 'ServerAliveCountMax=120', '-o', 'UserKnownHostsFile=/dev/null', '-o', 'StrictHostKeyChecking=no', '-N', '-R', serverPort.toString() + ':blockchain-explorer:8080', 'root@' + serverIp, '&'])
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
          @startHyperledgerInstance options.name, @uuid
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



