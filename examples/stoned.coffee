init: (context)->

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
      optInTimePeriod: 2
    mDI = _.last(result)

    result = talib.PLUS_DI    
      high: instrument.high
      low: instrument.low
      close: instrument.close
      startIdx: 0
      endIdx: instrument.close.length-1
      optInTimePeriod: 6      
    pDI = _.last(result)

    #simple ADX and DI based trading logic
    if (adx > 12) and (pDI > mDI)
        buy instrument
    else if (adx > 18) and (pDI < mDI)
        sell instrument