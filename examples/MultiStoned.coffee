###
# Placeholder in case anyone needs to backtrack
# to our pre-debugging state
# DO NOT TRADE WITH THIS COPY!
#
# Reference backtests to debug against:
# https://cryptotrader.org/backtests/GZiF3vFK6sSoMJFax
# https://cryptotrader.org/backtests/prFC7pLRPtkcwDkhu
###

init: (context)->
    context.buy_adx = 14
    context.sell_adx = 11
    # Base percent of BTC to purchase
    context.curr_factor = .075
    # Base percent of GHS to sell
    context.ass_factor = .025
    context.position = 0
    context.buy_time = 30.0
    context.sell_time = 10.0
    context.buy_threshold = 0.019
    context.sell_threshold = 0.64

# Persist data after every tick
serialize: (context)->
    position:context.position

# This method is called for each tick
handle: (context, data)->
    instrument = data.instruments[0]
    short = instrument.ema(49)
    long = instrument.ema(12)       
    plot
        short: short
        long: long
    diff = 100 * (short - long) / ((short + long) / 2)

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
        optInTimePeriod: 3
    pDI = _.last(result)

    # Use compound position to execute trades
    # Anything -2 > < 2 = hold
    # Does not account for reversal very well, yet
    # ToDo: Add method to store last position factor, compare current factor to previous. 
    #    We could use the reversal to compare against pricing changes to possibly make
    #    larger buys or sells

    pos = switch
        when context.position <- 11 # separate switch in case you want to back off less often
            context.position = 0
            debug "Zeroing out bear market firesale"
        when context.position < -10
            sell instrument
            debug "Shit the bed, sold position, Factor: #{context.position}"
        when -10 <= context.position < -2
            if diff < -context.sell_threshold
                factor = context.curr_factor * context.position
                amt = (portfolio.positions[instrument.curr()].amount * factor / instrument.price).toFixed(8)

                if portfolio.positions[instrument.curr()].amount > instrument.price*amt
                    sell instrument,instrument.price*context.sell_percent,null,context.sell_time
                else
                    sell instrument,null,null,context.buy_time
                debug "Factor: #{context.position}  Sell amount: #{amt}"
        when 10 >= context.position > 2
            debug "diff: #{diff} cbt: #{context.buy_threshold}"
            if diff > context.buy_threshold  || context.position >= 5
                factor = context.ass_factor * context.position
                amt = (portfolio.positions[instrument.asset()].amount * context.ass_factor).toFixed(8)

                if portfolio.positions[instrument.curr()].amount > instrument.price*amt
                    buy instrument,instrument.price*context.buy_percent,null,context.buy_time
                    debug "Factor: #{context.position}  Buy amount: #{amt}"
        when context.position > 10
            context.position = 2
            debug "Resetting bull market position to protect gains"
        else break

    # Change position factor based on trend
    if (adx > context.buy_adx) and (pDI > mDI)
            context.position += 1
    if (adx > context.sell_adx) and (pDI < mDI)
            context.position -= 1