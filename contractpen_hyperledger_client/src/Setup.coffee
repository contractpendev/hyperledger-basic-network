
Comedy = require 'comedy'
Awilix = require 'awilix'
Winston = require 'winston'
Graph = require '@dagrejs/graphlib'
ClusterWS = require 'clusterws'
express = require 'express'
GlobalContainer = require './GlobalContainer'

Worker = ->
  graphClass = Graph.Graph
  graphInstance = new graphClass()

  # Logging
  logger = Winston.createLogger(transports: [
    new (Winston.transports.File)(filename: 'application.log')
  ])

  logger.log('info', 'Startup')

  # Setup
  actorSystem = Comedy()
  actorSystem.getLog().setLevel(0) # Prevent output of log at startup

  # Dependency injection
  # @todo How to get the container to be globally available
  GlobalContainer.container = Awilix.createContainer
    injectionMode: Awilix.InjectionMode.PROXY

  GlobalContainer.container.register
    container: Awilix.asValue GlobalContainer.container
    logger: Awilix.asValue logger
    actorSystem: Awilix.asValue actorSystem
    graphClass: Awilix.asClass graphClass
    graph: Awilix.asValue graphInstance

  opts = {}

  GlobalContainer.container.loadModules [
      'src/services/*.js'
  ], resolverOptions:
    injectionMode: Awilix.InjectionMode.PROXY
    lifetime: Awilix.Lifetime.SINGLETON

  start = GlobalContainer.container.resolve 'StartService'
  start.start()

class Setup

  setup: () ->
    Worker()
    #@clusterws = new ClusterWS(
    #  worker: Worker
    #  port: 3060
    #  brokersPorts: [3061])

module.exports = Setup
