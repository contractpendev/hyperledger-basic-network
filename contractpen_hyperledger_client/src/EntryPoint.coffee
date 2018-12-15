
Comedy = require 'comedy'
Awilix = require 'awilix'
Setup = require './Setup'
GlobalContainer = require './GlobalContainer'

start = ->
  execa = require 'execa'
  output = await execa('ssh-keygen -F ' + serverIp)
  console.log output
  #setup = new Setup()
  #setup.setup()

start()



