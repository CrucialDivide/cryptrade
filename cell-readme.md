
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

