_ = require 'underscore'
CEXIO = require 'cexio'
Platform = require '../platform'
attempt = require 'attempt'
moment = require 'moment'

class CEXIOPlatform extends Platform
  init: (@config,@pair,@account,logger)->
    unless @account.clientid and @account.key and @account.secret 
      throw new Error 'CEXIOPlatform: client id, API key and secret must be provided'
    @logger = logger
    @client = new CEXIO @pair,@account.clientid,@account.key,@account.secret
  trade: (order, cb)->
    if order.maxAmount < parseFloat(@config.min_order[order.asset])
      cb "#{order.type.toUpperCase()} order wasn't created because the amount is less than minimum order amount"
      return
    orderCb = (err,result)->
      if err?
        cb err
      else
        if result.error?
          cb result.error
        else
          cb null, result.id
    self = @
    amount = (order.amount or order.maxAmount) * 0.995
    amount = parseFloat amount.toFixed(8)
    price = parseFloat order.price.toFixed(8)
    switch order.type
      when 'buy'
        attempt {retries:@config.max_retries,interval:@config.retry_interval*1000},
          ->
            self.client.place_order 'buy', amount, price, @
          ,orderCb
        break
      when 'sell'
        attempt {retries:@config.max_retries,interval:@config.retry_interval*1000},
          ->
            self.client.place_order 'sell', amount, price, @
          ,orderCb
        break
  isOrderActive: (orderId, cb)->
    self = @
    attempt {retries:@config.max_retries,interval:@config.retry_interval*1000},
      ->
        self.client.open_orders @
      ,(err,result)->
        if err?
          cb "isOrderActive: reached max retries #{err}"
        else
          order = _.find result, (order)->
            order.id == orderId
          cb null,order?

  cancelOrder: (orderId, cb)->
    self = @
    attempt {retries:@config.max_retries,interval:@config.retry_interval*1000},
      ->
        self.client.cancel_order orderId, @
      ,(err,result)->
        if err?
          cb "cancelOrder: reached max retries #{err}"
        if cb?
          cb null

  getPositions: (positions,cb)->
    self = @
    attempt {retries:@config.max_retries,interval:@config.retry_interval*1000},
      ->
        self.client.balance @
      ,(err,data)->
        if err?
          cb "getPositions: reached max retries #{err}"
        else
          if data.error?
            cb "getPositions: #{data.error}"
          else
            result = {}
            for item, pos of data
              if item == 'timestamp'
                continue
              curr = item.toLowerCase()
              if pos.available
                if curr in positions
                  result[curr] = parseFloat(pos.available)
            for asset in positions
              unless asset of result
                result[asset] = 0
            cb null, result
      
  getTicker: (cb)->
    self = @
    profileStart = +moment()
    attempt {retries:@config.max_retries,interval:@config.retry_interval*1000},
      ->
        self.client.ticker @
      ,(err,result)->
        profileEnd = +moment() - profileStart;
        self.logger.data {"value": profileEnd, "name":"api-latency", "channel": "metrics", "type":"profile", "source": "cryptotrade" }
        if err?
          cb "getTicker: reached max retries #{err}"
        else
          cb null,
            buy: parseFloat(result.bid)
            sell: parseFloat(result.ask)


module.exports = CEXIOPlatform
    
