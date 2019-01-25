
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
    @opts = opts
    @uuid = null
    @secretKey = config.get('server.secretKey')
    @accordZipUrl = config.get('server.accordZipUrl')
    @composeControllerUuid = null

  reverseProxy: () =>
    serverIp = config.get('server.ipAddress')
    serverPassword = config.get('server.password')
    await execa('ssh-keygen -F ' + serverIp)

  startHyperledgerInstance: (name, uuidOfController, uuid) =>
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
        fileName = entry.path
        type = entry.type
        # 'Directory' or 'File' 
        size = entry.size
        if fileName == 'package.json'
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
    websocketBaseUrl = config.get('server.websocketBaseUrl')
    # Submit uuid to the server via REST API

    # Submit uuid to the pubsub server to listen for commands
    try
      @ws = new WebSocket(websocketBaseUrl + 'echo')
      @ws.on('error', =>
        console.log 'error')
      @ws.on 'close', =>
        setTimeout(() => 
          @startServer()
        , 5000)
      @ws.on 'open', =>
        data =
          command: 'listenForCommands'
          uuid: @uuid
          secretKey: @secretKey
        dataJson = JSON.stringify(data) 
        @ws.send dataJson
        setTimeout (@sendPing
        ), (10*1000)
        return
      @ws.on 'message', (data) =>
        dataJson = JSON.parse(data)
        if dataJson.command == 'deployBnaToHyperledgerInstance'
          nameInsideZip = ''
          job = dataJson.job
          try
            bnaFileName = dataJson.bnaFileName             
            transactionId = dataJson.job.transactionId
            name = dataJson.name
            email = dataJson.email
            composerRestPort = @getRandomArbitrary(17200, 65535)
            downloadUrl = @accordZipUrl + dataJson.bnaFileName
            bnaDest = './../data/' + name + '/bna/' + dataJson.bnaFileName
            await @downloadFile(downloadUrl, bnaDest)
            json = await @readPackageJsonFromArchive(bnaDest)
            jsonName = json.name
            nameInsideZip = jsonName
            version = json.version
            prefixUrl = '/hyperledgerrest/' + dataJson.uuid + '/' + json.name + '/'
            try
              a = await execa('./cli/deploy_bna.sh', [dataJson.name + '.hyperledgerclient', jsonName, version, dataJson.bnaFileName],
                cwd: process.cwd() + '/../'
              )
              b = await execa('./cli/restapi.sh', [dataJson.name + '.hyperledgerclient', jsonName, composerRestPort, prefixUrl],
                cwd: process.cwd() + '/../'
              )
              password = config.get('server.password')
              serverPort = null
              # Fetch a port from the server for reverse ssh to work               
              baseUrl = config.get('server.restBaseUrl')
              client = request.createClient(baseUrl)
              lockedPort = await client.post('proxyServiceApi/lockServerPort', {
                uuid: json.uuid
                hyperledgerLogicalName: name # BEEDED
                bnaLogicalName: jsonName # NEEDED
                version: version
                bnaFileName: dataJson.bnaFileName
                secretKey: @secretKey
              })
              serverPort = lockedPort.body.serverPort
              serverIp = config.get('server.ipAddress')
              # ssh pass from inside this docker container to the server to create reverse proxy
              c = await execa('docker', ['exec', '-d', name + '.hyperledgerclient', '/usr/bin/sshpass', '-p', password, 'ssh', '-o', 'ServerAliveInterval=60', '-o', 'ServerAliveCountMax=120', '-o', 'UserKnownHostsFile=/dev/null', '-o', 'StrictHostKeyChecking=no', '-N', '-R', serverPort.toString() + ':hyperledgerclient:' + composerRestPort.toString(), 'root@' + serverIp],
                cwd: process.cwd() + '/../'
              )
            catch ex 
              console.log ex 
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
          # Here create total names in an array and then send that to the server and attempt to start them 
          baseUrl = config.get('server.restBaseUrl')
          client = request.createClient(baseUrl)        
  
          # Start it
          # Once started then store the name and tell server it is started
          for name in names
            uuid = uuidv4().toString()
            await client.post('proxyServiceApi/attemptingToStartHyperledgerClient', 
              secretKey: @secretKey
              hyperledgerName: name
              uuid: uuid
            )      
            await @startHyperledgerInstance name, @uuid, uuid
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
      command = options.command
      if command == 'startInDocker'
        @composeControllerUuid = options.composeControllerUuid
        uuid = options.uuid
        serverIp = config.get('server.ipAddress')
        password = config.get('server.password')
        # Generate the primary card if it does not already exist
        if (not fs.existsSync('./../crypto-config/PeerAdmin@hlfv12.card'))
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
          await execa('/usr/bin/ssh-keyscan', ['-H', serverIp, '>>', '/root/.ssh/known_hosts'])
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
      else if command == 'startOutsideDocker' 
        if options.name
          uuid = uuidv4().toString()          
          @startHyperledgerInstance options.name, @uuid, uuid
        else 
          @startServer()
      else 
        console.log 'need to use a command line option either as startInDocker or startOutsideDocker'    
    catch e
      console.log e  
    @opts.logger.log('info', 'Start of HyperledgerService')

module.exports = HyperledgerService



