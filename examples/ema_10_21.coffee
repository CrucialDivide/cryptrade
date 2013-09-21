###
  EMA CROSSOVER TRADING ALGORITHM
  The script engine is based on CoffeeScript (http://coffeescript.org)
  Any trading algorithm needs to implement two methods: 
    init(context) and handle(context,data)
###        

# Initialization method called before a simulation starts. 
# Context object holds script data and will be passed to 'handle' method. 
init: (context)->
    context.pair = 'btc_usd'
    context.buy_treshold = 0.25
    context.sell_treshold = 0.25

# This method is called for each tick
handle: (context, data)->
    # data object provides access to the current candle (ex. data['btc_usd'].close)
    instrument = data[context.pair]
    short = instrument.ema(10) # calculate EMA value using ta-lib function
    long = instrument.ema(21)       
    diff = 100 * (short - long) / ((short + long) / 2)
    debug 'EMA difference: '+diff.toFixed(3)+' price: '+instrument.price.toFixed(2)+' at '+new Date(data.at)
    if diff > context.buy_treshold          
        buy instrument # Spend all amount of cash for BTC
    else
        if diff < -context.sell_treshold
            sell instrument # Sell BTC position
   
