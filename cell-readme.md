
cel.ly - cell info

Enhancements to the cryptotrader bot to support the cell.

Following the bot's design - I've used config based approach.

If you take a look at config.cson which basically summarises things.  
Winston (https://github.com/flatiron/winston) is the logger that allows you to redirect log levels to other places.  It's a handy & flexible system that intgrates well with the bot design.

In the config - the logger:winston:transports key allows you to use any winston available logger (https://npmjs.org/search?q=winston).
Under this - add a key with the name of the Winston backend store - in the current config you can see the winston-redis being used.
While you'll need to ensure the module is installed - the code will attempt to load & use based on the keyname.

The config.cson should show:
logger:
  winston:
    transports:
      redis:
        packageName: "winston-redis"
        level: "data"
        host: "localhost"
        port: 6379

If you wanted to use say mongodb - once you have the package installed - the config would look like:
logger:
  winston:
    transports:
      mongodb:
        packageName: "winston-mongodb"
        level: "data"
        host: "localhost"
        port: 6379
        collection: "cexio"

All attributes under the provider name are passed as config to the winston provider.

Ok - so that's the what - here's the how:

The logger object is available throughout the engine - so you can use logger in your own algos.  With the config above the data level would be stored to your own backend.
I've used logger.data in a few places for storing trade information from the algo - so you'll need to have a logger the level: "data" in addition to your own - or just use one with the level set to data.

To store data is straightforward - logger.data {"some":"property"}

Here's an example of how that's used already (cexio.coffee):
	logger.data {"value": profileEnd, "name":"api-latency", "channel": "metrics", "type":"profile", "source": "cryptotrade" }

Some of the fields in the object will look familiar from the config file.
Using a few named fields allows the reporting & data provider side to work.

Reporting is a work in progress currently and will be provided by a builtin webserver.
Config-wise - an example is:

  latency:
    config:
      allowJson: true
      reportName: "latency"
    filter:
      channel:"metrics"
      name:"api-latency"

Which follows the form:

  reportName&urlPath:
    config:
      allowJson: true
      reportName: "latency"
    filter:
      channel:"metrics"
      name:"api-latency"

The filter section contains what object properties will be used when querying the winston data-store for plucking data.