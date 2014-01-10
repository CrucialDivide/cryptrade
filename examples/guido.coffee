init: (context)->
    context.pair = 'ghs_btc'
    context.buy_threshold = 0.0001
    context.sell_threshold = 0.0001
    context.buy_price = 0
    context.previous_price = 0
    context.stop_loss_threshold = 0.990 # sell if price drops below buy prices times this
    context.trailing_stop_loss_threshold = 0.995 # sell if current price is lower than previous candle times this 
    context.fee = 0.0 # must be equal to settings
    context.stop_loss_counter = 0
    context.trailing_stop_loss_counter = 0
    context.buy_threshold_counter = 0
    context.sell_threshold_counter = 0
    context.win_counter = 0
    context.win_percentage = 0
    context.loss_counter = 0
    context.loss_percentage = 0
    context.rsi_factor = 1.0 # default 1.0
    context.initial = 0 # needed to store initial price
    
handle: (context, data)->
    pow = (x,y) -> Math.pow(x,y)
    round = (x,y) -> Math.round((x)*pow(10,y))/pow(10,y)
    m_percent = (x,y) -> (((1+(x/100))*(1+(y/100)))-1)*100 # multiply percentages: +5% * +2% = +7,1%
    instrument = data[context.pair]
    break_even_price = context.buy_price*pow(1+context.fee/100,2)
    win_loss = round(100*((instrument.price/break_even_price)-1),2)
    report = 0

    # Buy & Hold
    if context.initial == 0
        context.initial = instrument.price
        context.initial_btc = portfolio.positions.btc.amount
    context.last = instrument.price

    # EMA
    short = instrument.ema(7)
    long = instrument.ema(17)  
    #draw moving averages on chart
    plot
        short:short
        long:long
    diff = 100 * (short - long) / ((short + long) / 2)
    
    # RSI
    result = talib.RSI
        startIdx: instrument.close.length-10
        endIdx: instrument.close.length-1
        inReal: instrument.close
        optInTimePeriod: 16
    rsi_max = _.max(result)
    rsi_last = _.last(result)
        
    # ADX
#    result = talib.ADX
#        high: instrument.high
#        low: instrument.low
#        close: instrument.close
#        startIdx: 0
#        endIdx: instrument.close.length-1
#        optInTimePeriod: 14    
#    adx = _.last(result)    

    # MACD
#    results = talib.MACD
#        startIdx: 0
#        endIdx: instrument.close.length-1
#        inReal: instrument.close
#        optInFastPeriod: 12
#        optInSlowPeriod: 26
#        optInSignalPeriod: 9
#    if results.outMACD.length > 0
#        macd = _.last results.outMACD
#        signal = _.last results.outMACDSignal
#        histogram = _.last results.outMACDHist
    
    # STOCHASTIC
#    results = talib.STOCH
#        high: instrument.high
#        low: instrument.low
#        close: instrument.close
#        startIdx: 0
#        endIdx: instrument.close.length-1
#        optInFastK_Period: 5
#        optInSlowK_Period: 3
#        optInSlowK_MAType: 1
#        optInSlowD_Period: 3
#        optInSlowD_MAType: 1
#    if results.outSlowK.length
#            stoch_SlowK = _.last results.outSlowK
#            stoch_SlowD = _.last results.outSlowD

    # RSI EFFECT ON BUY/SELL THRESHOLD
    rsi_spread = 20
    if rsi_max > 50+rsi_spread
        if rsi_last < 50+rsi_spread
            context.rsi_factor = 1.5
    if rsi_max < 50-rsi_spread
        if rsi_last > 50-rsi_spread
            context.rsi_factor = 1.5
    
    # THRESHOLD BUY
    if diff < context.buy_threshold * context.rsi_factor
        orderId = buy instrument
        if orderId
            context.rsi_factor = 1.0
            context.buy_price = instrument.price
            context.buy_threshold_counter += 1
            report = 1
    
    # THRESHOLD SELL
    else if diff > -context.sell_threshold * context.rsi_factor
        orderId = sell instrument
        if orderId
            context.rsi_factor = 1.0
            context.sell_threshold_counter += 1
            if instrument.price < break_even_price
                debug "Loss: #{win_loss}%"
                context.loss_counter += 1
                context.loss_percentage = m_percent(win_loss, context.loss_percentage)
            else
                debug "Gain: #{win_loss}%"
                context.win_counter += 1
                context.win_percentage = m_percent(win_loss, context.win_percentage)
            report = 1
    
    # STOP LOSS SELL
    else if instrument.price < (context.stop_loss_threshold*context.buy_price)
        orderId = sell instrument # Sell GHS position
        if orderId
            context.rsi_factor = 1.0
            context.stop_loss_counter += 1
            if instrument.price < break_even_price
                debug "Loss: #{win_loss}%"
                context.loss_counter += 1
                context.loss_percentage = m_percent(win_loss, context.loss_percentage)
            else
                debug "Gain: #{win_loss}%"
                context.win_counter += 1
                context.win_percentage = m_percent(win_loss, context.win_percentage)
            report = 1
    
    # TRAILING STOP LOSS SELL
    else if instrument.price < (context.trailing_stop_loss_threshold*context.previous_price)
        orderId = sell instrument # Sell GHS position
        if orderId
            context.rsi_factor = 1.25
            context.trailing_stop_loss_counter = context.trailing_stop_loss_counter+1
            if instrument.price < break_even_price
                debug "Loss: #{win_loss}%"
                context.loss_counter += 1
                context.loss_percentage = m_percent(win_loss, context.loss_percentage)
            else
                debug "Gain: #{win_loss}%"
                context.win_counter += 1
                context.win_percentage = m_percent(win_loss, context.win_percentage)
            report = 1
    
    # DEBUG
    if report>0
#        debug "Total Gain %: #{context.win_percentage}"
#        debug "Total Loss %: #{context.loss_percentage}"
#        debug "Buy Price: #{context.buy_price}"
#        debug "Break Even Price: #{break_even_price}"
#        debug "SlowK:#{stoch_SlowK}"
#        debug "SlowD:#{stoch_SlowD}"
#        debug "MACD:#{macd}"
         debug "___________"

    context.previous_price = instrument.price
    
finalize: (context)->
    pow = (x,y) -> Math.pow(x,y)
    round = (x,y) -> Math.round((x)*pow(10,y))/pow(10,y)
#    debug "Buy Threshold:#{context.buy_threshold_counter}"
#    debug "Sell Threshold:#{context.sell_threshold_counter}"
#    debug "Trailing Stop Loss:#{context.trailing_stop_loss_counter}"
#    debug "Stop Loss:#{context.stop_loss_counter}"
    total_btc = portfolio.positions.ghs.amount * context.previous_price * (1-context.fee/100) + portfolio.positions.btc.amount
    total_percent = (total_btc/context.initial_btc)*100
    b_h_btc = (context.initial_btc / context.initial) * context.last * (1-context.fee/100)   
    b_h_percent = (context.last/context.initial) * (1-context.fee/100)*100
    performance_percent = ((total_percent/b_h_percent)-1)*100
    debug "Current Strategy____: #{round(total_btc,2)} BTC (#{round(total_percent,2)}%)"
    debug "Buy & Hold Strategy_: #{round(b_h_btc,2)} BTC (#{round(b_h_percent,2)}%)"
    debug "Total Trades________: #{context.buy_threshold_counter} -- Average G/L_: #{round(100*(pow(((1+context.win_percentage/100)*(1+context.loss_percentage/100)), (1/context.buy_threshold_counter))-1),2)}%"
    debug "Successful Trades___: #{context.win_counter} -- Average Gain: #{round(100*(pow(((1+context.win_percentage/100)), (1/context.win_counter))-1),2)}% -- Total Gain: #{round(context.win_percentage,2)}%"
    debug "Unsuccessful Trades_: #{context.loss_counter} -- Average Loss: #{round(100*(pow(((1+context.loss_percentage/100)), (1/context.loss_counter))-1),2)}% -- Total Loss: #{round(context.loss_percentage,2)}%"
    if performance_percent < 1
        debug "This strategy is #{round(performance_percent,2)}% less effective than a simple Buy & Hold Strategy."
    else
        debug "This strategy is +#{round(performance_percent,2)}% more effective than a simple Buy & Hold Strategy."
    