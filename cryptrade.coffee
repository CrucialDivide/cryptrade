require 'sugar'
_ = require 'underscore'
fs = require 'fs'
basename = require('path').basename
io = require('socket.io-client')
CoffeeScript = require 'coffee-script'
program = require 'commander'
winston = require 'winston'
CSON = require 'cson'
inspect = require('./utils').inspect
utils = require './utils'
Trader = require './trader'
WebServer = require './webserver/app'

logger = new (winston.Logger) {
  transports: [
    new (winston.transports.Console) {level:'verbose',colorize:true,timestamp:true}
  ]
}

#logger.remove logger.transports.Console
#logger.add logger.transports.Console,{level:'verbose',colorize:true,timestamp:true}

#logger.on 'logging', (transport, level, msg, meta) =>
#  console.log("LOGGING:", arguments)
  #if meta && meta.level && (meta.level.match("data"))
  #  logger.data msg, meta
  #logger.info level, msg, meta
  # // [msg] and [meta] have now been logged at [level] to [transport]

  # $('.shopping_cart').bind 'click', (event) =>
  #   @customer.purchase @cart

version = require('./package.json').version

# a helper which allows us to redirect certain log messages to other places
loggingAddTransport = (typeName, config) ->
  typeName = typeName.capitalize()
  requiredPackage = require(config.packageName)
  requiredPackage = requiredPackage[typeName];
  logger.info "loggingAddTransport", typeName, JSON.stringify(config), winston.transports[typeName]
  logger.add winston.transports[typeName], config

if require.main == module
  program = require('commander')
  program
    .usage('[options] <filename or backtest url in format https://cryptotrader.org/backtests/<id>>')
    .option('-c,--config [value]','Load configuration file')
    .option('-p,--platform [value]','Trade at specified platform')
    .option('-i,--instrument [value]','Trade instrument (ex. btc_usd)')
    .option('-t,--period [value]','Trading period (ex. 1h)')
    .parse process.argv
  config = CSON.parseFileSync './config.cson'
  if config.logger.winston
    logger.info "Configuring logging"

    if config.logger.winston.levels
      logger.info "Setting custom log levels"
      logger.setLevels config.logger.winston.levels
    if config.logger.winston.colors
      logger.info "Setting custom log colors"
      winston.addColors config.logger.winston.colors

    if config.logger.winston.transports
      logger.info "Processing transports"

      for transport of config.logger.winston.transports
        transportConfig = config.logger.winston.transports[transport]
        loggingAddTransport transport, transportConfig

    logger.info "Testing the data level"
    logger.data "Data: Test"
  if program.config?
    logger.info "Loading configuration file configs/#{program.config}.cson.."
    anotherConfig = CSON.parseFileSync 'configs/'+program.config+'.cson'
    config = _.extend config,anotherConfig
  keys = CSON.parseFileSync 'keys.cson'
  unless keys?
    logger.error 'Unable to open keys.cson'
    process.exit 1
  if program.args.length > 1
    logger.error "Too many arguments"
    process.exit 1
  if program.args.length < 1
    logger.error "Either filename or url must be specified to load trader source code from"
    process.exit 1
  source = program.args[0]
  if source.indexOf('https://') == 0
    rx = /https?:\/\/cryptotrader.org\/backtests\/(\w+)/
    m = source.match rx
    unless m?
      logger.error 'Backtest URL should be in format https://cryptotrader.org/backtests/<id>'
      process.exit 1
    logger.verbose 'Downloading source from '+source 
    source = "https://cryptotrader.org/backtests/#{m[1]}/json"
    await utils.downloadURL source, defer err,data
    backtest = JSON.parse data
    platform = backtest.platform
    instrument = backtest.instrument
    period = backtest.period
    name = m[1]
    code = backtest.code
  else 
    code = fs.readFileSync source,
      encoding: 'utf8'
    name = basename source,'.coffee'
  unless code?
    logger.error "Unable load source code from #{source}"
    process.exit 1
  config.platform = program.platform or config.platform or platform
  config.instrument = program.instrument or config.instrument or instrument
  config.period = program.period or config.period or period
  if not fs.existsSync 'logs'
    fs.mkdirSync 'logs'
  logger.add winston.transports.File, {level:'verbose',filename:"logs/#{name}.log", name: "#{name}"}
  #winston.add(winston.transports.File, { filename: 'somefile.log' });
  logger.info "Initializing new trader instance ##{name} [#{config.platform}/#{config.instrument}/#{config.period}]"
  script = CoffeeScript.compile code,
    bare:true
  logger.info "Setting up webserver"
  WebServer.start(config.webserver, config)

  logger.info 'Connecting to data provider..'
  client = io.connect config.data_provider, config.socket_io
  trader = undefined
  client.socket.on 'connect', ->
    logger.info "Subscribing to data source #{config.platform} #{config.instrument} #{config.period}"
    logger.data {"cellyId": config.celly_cell_name, "value": "online", "type": "bot", "source": "cryptotrade" }
    client.emit 'subscribeDataSource', version, keys.cryptotrader.api_key,
      platform:config.platform
      instrument:config.instrument
      period:config.period
      limit:config.init_data_length
  client.on 'data_message', (msg)->
    logger.warn 'Server message: '+err
  client.on 'data_error', (err)->
    logger.error err
  client.on 'data_init',(bars)->
    logger.verbose "Received historical market data #{bars.length} bar(s)"
    logger.data { "dataInit": bars,  "type":"profile", "source": "cryptotrade" }
    trader = new Trader name,config,keys[config.platform],script,logger
    logger.info "Pre-initializing trader with historical market data"
    trader.init(bars)
  client.on 'data_update',(bars)->
    logger.verbose "Market data update #{bars.length} bar(s)"
    logger.data { "dataUpdate": bars,  "type":"profile", "source": "cryptotrade" }
    if trader?
      for bar in bars
        trader.handle bar
  client.on 'error', (err)->
    logger.error err
  client.on 'disconnect', ->
    logger.warn 'Disconnected'

# var logger = new (winston.Logger)({
#   transports: [
#     new (winston.transports.Console)(),
#     new (winston.transports.File)({ filename: 'somefile.log' })
#   ]
# });

# logger.on('logging', function (transport, level, msg, meta) {
#   // [msg] and [meta] have now been logged at [level] to [transport]
# });