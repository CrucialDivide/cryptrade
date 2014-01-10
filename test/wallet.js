request = require("superagent");

var callback = function() {
	console.log(arguments)
}

request
  .get('https://www.cex.io/trade/finance')
  .auth('laSeek', 'always4u..')
  .end(callback);

