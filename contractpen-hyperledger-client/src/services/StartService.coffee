

class StartService

  # Injected 
  constructor: (opts) ->
    @hyperledgerService = opts.HyperledgerService

  start: () ->
    @hyperledgerService.start()

module.exports = StartService



