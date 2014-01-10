init: (context)->
    context.buy_adx = 14
    context.sell_adx = 11

# This method is called for each tick
handle: (context, data)->
    instrument = data.instruments[0]
    result = talib.ADX
      high: instrument.high
      low: instrument.low
      close: instrument.close
      startIdx: 3
      endIdx: instrument.close.length-1
      optInTimePeriod: 9
    adx = _.last(result)

    result = talib.MINUS_DI    
      high: instrument.high
      low: instrument.low
      close: instrument.close
      startIdx: 0
      endIdx: instrument.close.length-1
      optInTimePeriod: 5
    mDI = _.last(result)

    result = talib.PLUS_DI    
      high: instrument.high
      low: instrument.low
      close: instrument.close
      startIdx: 0
      endIdx: instrument.close.length-1
      optInTimePeriod: 2
    pDI = _.last(result)

    statusMessage = "status: { "
    statusMessage = statusMessage+ "'pDI': "+pDI+", 'mDI': "+mDI+", 'adx': "+adx+", 'cBuyADX': "+context.buy_adx+", 'cSellADX': "+context.sell_adx

    #simple ADX and DI based trading logic
    if (adx > context.buy_adx) and (pDI > mDI)
        statusMessage = statusMessage+", 'action': 'buy'"
        #buy instrument
    if (adx > context.sell_adx) and (pDI < mDI)
        statusMessage = statusMessage+", 'action': 'sell'"
        #sell instrument 

    statusMessage = statusMessage+" }"
    debug statusMessage
