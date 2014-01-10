# Tweaked Coffee v0.3 - ADX/DI trading algorithm
#
# Based on Stoned Coffee v0.3
#
# For use with Crypposition (and maybe Crypto Trader if you're feeling lucky)
#
# Tips for safe CEX:
# - Start with small amounts for testing purposes
# - Run ONLY when market volume is high
# - Run ONLY when you have BTC and GHS so swings do not whipe you out
# - Assume the bot will start by selling
# - Expect it to take some small hits -- it's a fighter
# - TRIPLE CHECK your config before running
# - Avoid restarting while it runs, or else
# - USE AT YOUR OWN RISK! THIS ALGO MAY MOLEST YOUR DOG!
#
# https://cryptopositionr.org/backtests/iM3sNLA8n73KjNHxz
#
# Special thanks:
# - bitstoned for writing this damn thing in the first place
# - aliasme for going balls to the wall in a test run
# - burningfiat for helping identify weaknesses
# - serial77 for the heads' up on Crypposition
# - Everyone else in @CEX.io on Cel.ly for their general involvement
#
#

init: (context)->
	context.buy_adx = 14
	context.sell_adx = 11
	# Base percent of BTC to purchase
	context.curr_factor = .0080
	# Base percent of GHS to sell
	context.ass_factor = .0040
	context.position = 0

# Persist data after every tick
serialize: (context)->
	position:context.position

# This method is called for each tick
handle: (context, data)->
	#debug "#{context.position}"
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
			factor = context.ass_factor * context.position
			amt = portfolio.positions[instrument.asset()].amount * context.ass_factor
			sell instrument,amt
			debug "Factor: #{context.position}  Sell amount: #{amt}"
		when 10 >= context.position > 2
			factor = context.curr_factor * context.position
			amt = portfolio.positions[instrument.curr()].amount * factor / instrument.price
			buy instrument,amt
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