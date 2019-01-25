
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
unzip = require 'unzip'
unzipper = require 'unzipper'

class HyperledgerService

  constructor: (opts) ->
    console.log 'constructor in Hyperledger Service'
    @opts = opts
    @uuid = null
    @secretKey = config.get('server.secretKey')
    @accordZipUrl = config.get('server.accordZipUrl')
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

  startHyperledgerInstance: (name, uuidOfController, uuid) =>
    console.log 'we are outside docker and going to start instance by name for name :' + name + ':'  
    console.log process.cwd() + '/../'
    try
      b = await execa('./cli/generate.sh', [name, uuidOfController, uuid],
        cwd: process.cwd() + '/../'
      )
      c = await execa('./cli/start_docker.sh', [name, uuid],
        cwd: process.cwd() + '/../'
      )          
    catch e 
      console.log e 

      

  sendPing: () =>
    if (@ws.readyState == @ws.CLOSED)
      return
    ping =
      command: 'ping'
      secretKey: @secretKey
    @ws.send JSON.stringify(ping)
    setTimeout (@sendPing
    ), (10*1000)

  identifyClient: () =>
    console.log 'identify client'
    if (fs.existsSync('identity.txt'))
      @uuid = fs.readFileSync('identity.txt', 'utf8')
    else  
      @uuid = uuidv4().split('-').join('')
      await fs.writeFile('identity.txt', @uuid, 'utf8')

  streamToString = (stream, cb) ->
    chunks = []
    stream.on 'data', (chunk) ->
      chunks.push chunk.toString()
      return
    stream.on 'end', ->
      cb chunks.join('')
      return
    return

  readPackageJsonFromArchive: (bna) =>
    if (not fs.existsSync(bna))
      console.log 'file not exist'
    promise = new Promise((resolve, reject) => 
      fs.createReadStream(bna).pipe(unzipper.Parse()).on('entry', (entry) ->
        console.log 'entry'
        fileName = entry.path
        type = entry.type
        # 'Directory' or 'File' 
        size = entry.size
        if fileName == 'package.json'
          console.log 'found!'
          streamToString(entry, (data) ->
            jsonContent = JSON.parse(data)
            resolve(jsonContent)
          )
        else
          entry.autodrain())
    )
    promise

  downloadFile: (downloadUrl, bnaDest) =>
    new Promise((resolve, reject) =>
      stream = download(downloadUrl).pipe(fs.createWriteStream(bnaDest))
      stream.on('finish', () =>
        resolve(null)
      )
    )  

  getRandomArbitrary: (min, max) ->
    i = Math.random() * (max - min) + min
    return Math.floor(i)
    
  startServer: () =>
    @identifyClient()
    console.log 'uuid identity of this client is ' + @uuid
    websocketBaseUrl = config.get('server.websocketBaseUrl')
    # Submit uuid to the server via REST API

    # Submit uuid to the pubsub server to listen for commands
    try
      @ws = new WebSocket(websocketBaseUrl + 'echo')
      console.log 'just before...'
      @ws.on('error', =>
        console.log 'error')
      @ws.on 'close', =>
        console.log 'the websocket closed, why?'
        console.log 'so I will try to reopen every 5 seconds'
        setTimeout(() => 
          @startServer()
        , 5000)
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
        if dataJson.command != "pong"
          console.log 'websocket message from server is'
          console.log dataJson
        if dataJson.command == 'deployBnaToHyperledgerInstance'
          nameInsideZip = ''
          job = dataJson.job
          try
            #dataJsonName = dataJson.name
            #uuid = dataJson.uuid 
            #controllerUuid = dataJson.controllerUuid
            bnaFileName = dataJson.bnaFileName             
            transactionId = dataJson.job.transactionId
            name = dataJson.name
            email = dataJson.email
            console.log ' '
            console.log 'email is ' + email
            console.log 'command is ' + dataJson.command
            console.log 'task should be to download the bna and place it in directory data/' + name + '/bna'
            console.log 'the filename is ' + dataJson.bnaFileName
            console.log 'transaction id ' + transactionId
            composerRestPort = @getRandomArbitrary(17200, 65535)
            console.log 'composer rest port ' + composerRestPort
            # archive_0f0ec513-daba-42e5-8ec5-13daba62e5c4.bna
            downloadUrl = @accordZipUrl + dataJson.bnaFileName
            bnaDest = './../data/' + name + '/bna/' + dataJson.bnaFileName
            console.log 'bna dest ' + bnaDest
            await @downloadFile(downloadUrl, bnaDest)
            json = await @readPackageJsonFromArchive(bnaDest)
            jsonName = json.name
            nameInsideZip = jsonName
            version = json.version
            console.log 'jsonName ' + jsonName
            console.log 'version ' + version
            # $1 is logical name from package.json inside the bna file
            # $2 is the version from package.json inside the bna file
            # $3 is the BNA file name with BNA at the end  
            console.log ''    
            console.log 'call deploy_bna.sh with parameters -----------------------------------'  
            console.log dataJson.name + '.hyperledgerclient'
            console.log jsonName
            console.log version
            console.log dataJson.bnaFileName
            console.log name
            console.log 'json is'
            console.log dataJson
            prefixUrl = '/hyperledgerrest/' + dataJson.uuid + '/' + json.name + '/'
            console.log 'prefix url ----------------------------------------'
            console.log prefixUrl
            console.log 
            console.log(process.cwd() + '/../')
            try
              a = await execa('./cli/deploy_bna.sh', [dataJson.name + '.hyperledgerclient', jsonName, version, dataJson.bnaFileName],
                cwd: process.cwd() + '/../'
              )
              console.log a
              console.log 'attempting to start rest api ##############################################################################'
              b = await execa('./cli/restapi.sh', [dataJson.name + '.hyperledgerclient', jsonName, composerRestPort, prefixUrl],
                cwd: process.cwd() + '/../'
              )
              console.log 'attempting to start rest api ##############################################################################'
              console.log b
              console.log 'attempting to start rest api ##############################################################################'
              password = config.get('server.password')
              serverPort = null
              # @todo get an available server ip

              # Fetch a port from the server for reverse ssh to work               
              baseUrl = config.get('server.restBaseUrl')
              client = request.createClient(baseUrl)
              console.log 'for lock server port we need to associate what information'
              console.log 'associate the jsonName ' + jsonName
              # The next two are the same
              console.log 'the name? ' + name
              console.log 'dataJson.name: ' + dataJson.name
              # its undefined console.log 'json.uuid: ' + json.uuid
              console.log 'dataJson.bnaFileName: ' + dataJson.bnaFileName
              lockedPort = await client.post('proxyServiceApi/lockServerPort', {
                uuid: json.uuid
                hyperledgerLogicalName: name # BEEDED
                bnaLogicalName: jsonName # NEEDED
                version: version
                bnaFileName: dataJson.bnaFileName
                secretKey: @secretKey
              })
              serverPort = lockedPort.body.serverPort

              console.log 'the server port is ' + serverPort

              serverIp = config.get('server.ipAddress')
              # ssh pass from inside this docker container to the server to create reverse proxy
              c = await execa('docker', ['exec', '-d', name + '.hyperledgerclient', '/usr/bin/sshpass', '-p', password, 'ssh', '-o', 'ServerAliveInterval=60', '-o', 'ServerAliveCountMax=120', '-o', 'UserKnownHostsFile=/dev/null', '-o', 'StrictHostKeyChecking=no', '-N', '-R', serverPort.toString() + ':hyperledgerclient:' + composerRestPort.toString(), 'root@' + serverIp],
                cwd: process.cwd() + '/../'
              )
              console.log 'in theory we have now set up the reverse ssh stuff!!!!!!'
              console.log c
              # docker exec hyperledger0adcca29f53f4c748ca78eb192f8b802.hyperledgerclient composer-rest-server -c admin@acceptance-of-delivery_7hhp1nq1m -n always -u true -w true -p 1234')
            catch ex 
              console.log ex 
            console.log 'then to execute a shell script to deploy the bna to that hyperledger'
            console.log 'need to know the bna file name!'
            console.log ''
            # Completion of this requires notification to the work server
            # transactionId and job need to be sent to some server URL to notify on REDIS the job result
          catch e 
            console.log e 
          job.nameInsideZip = nameInsideZip 
          job.uuid = dataJson.uuid
          job.name = dataJson.name 
          data =
            command: 'workerFinishedJob'
            uuid: @uuid
            secretKey: @secretKey
            job: job
          @ws.send(JSON.stringify(data))
        if dataJson.command == 'listenForCommandsResult'
          baseUrl = config.get('server.restBaseUrl')
          client = request.createClient(baseUrl)
          await client.post('proxyServiceApi/hyperledgerClientAwaitingCommands', 
            secretKey: @secretKey
            uuid: @uuid
          )
        if dataJson.command == 'startHyperledgerInstance'  
          name = dataJson.hyperledgerName
          uuid = uuidv4().toString()          
          baseUrl = config.get('server.restBaseUrl')
          client = request.createClient(baseUrl)        
          await client.post('proxyServiceApi/attemptingToStartHyperledgerClient', 
            secretKey: @secretKey
            hyperledgerName: name
            uuid: uuid
          )      
          # Start it
          # Once started then store the name and tell server it is started
          await @startHyperledgerInstance name, @uuid, uuid
        if dataJson.command == 'startMultipleHyperledgerInstances'  
          total = dataJson.total

          numbers = [1..total]

          names = numbers.map((n) ->
            'hyperledger' + uuidv4().split('-').join('')
          )
          console.log names

          # Here create total names in an array and then send that to the server and attempt to start them 
          baseUrl = config.get('server.restBaseUrl')
          client = request.createClient(baseUrl)        
  
          # Start it
          # Once started then store the name and tell server it is started
          for name in names
            uuid = uuidv4().toString()
            console.log 'Attempting to start hyperledger with name :' + name + ':' + uuid
            await client.post('proxyServiceApi/attemptingToStartHyperledgerClient', 
              secretKey: @secretKey
              hyperledgerName: name
              uuid: uuid
            )      
            await @startHyperledgerInstance name, @uuid, uuid
            console.log 'finished start hyperledger :' + name + ':'
    catch e
      setTimeout(() => 
        @startServer()
      , 5000)
    return

  sleep = (ms) ->
    new Promise((resolve) ->
      setTimeout resolve, ms
      return
  )

  # Startup hyperledger then quit itself 
  start: () =>
    optionDefinitions = [
      { name: 'command', defaultOption: true },
      { name: 'name', alias: 'n', type: String },
      { name: 'composeControllerUuid', alias: 'c', type: String },
      { name: 'uuid', alias: 'u', type: String }
    ]
    try
      options = commandLineArgs(optionDefinitions)
      console.log 'options are'
      console.log options
      console.log ''
      command = options.command
      if command == 'startInDocker'
        console.log 'The parent is ' + options.composeControllerUuid
        console.log 'current directory is :' + process.cwd() + ':'
        @composeControllerUuid = options.composeControllerUuid
        uuid = options.uuid
        console.log 'uuid is ' + uuid
        serverIp = config.get('server.ipAddress')
        password = config.get('server.password')
        # Generate the primary card if it does not already exist
        if (not fs.existsSync('./../crypto-config/PeerAdmin@hlfv12.card'))
          console.log 'creating the card, need to know the result!!!!!!!!!!!!!'
          try
            createCard = await execa('./../cli/createcard.sh')
            console.log createCard
          catch ex 
            console.log ex           
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
          uuid: uuid
        })

        serverPort = hyperledgerServerPortAndUuid.body.serverPort
        #uuid = hyperledgerServerPortAndUuid.body.uuid

        console.log 'uuid is ' + uuid

        # Lets assume the next command will work successfully, so then we should tell server we have started
        resultOfStart = await client.post('proxyServiceApi/finishSetupHyperledgerClient', {
          name: options.name
          uuid: uuid
          serverPort: serverPort
          secretKey: @secretKey
        })

        #  -o "ServerAliveInterval 60" -o "ServerAliveCountMax 120" 
        while true
          try
            await execa('/usr/bin/sshpass', ['-p', password, 'ssh', '-o', 'ServerAliveInterval=60', '-o', 'ServerAliveCountMax=120', '-o', 'UserKnownHostsFile=/dev/null', '-o', 'StrictHostKeyChecking=no', '-N', '-R', serverPort.toString() + ':blockchain-explorer:8080', 'root@' + serverIp])
          catch ex 
            console.log ex 
          await @sleep(5000)

        console.log('how did we get here?')  
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
          uuid = uuidv4().toString()          
          console.log 'project name is :' + options.name + ':' + uuid
          @startHyperledgerInstance options.name, @uuid, uuid
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



