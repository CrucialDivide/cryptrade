/*
var io = require("socket.io-client");
var chat = io.connect('https://ws.cex.io/');

chat.on('data', function (data) {
	console.log("data", data.e);
});

current_pair = {
	symbol1: 'GHS',
	symbol2: 'BTC',
	lot_size: undefined,
	lastprice: 0.04188902
}

chat.write({ e: 'subscribe', rooms: ['tickers', 'pair-' + current_pair.symbol1 + '-' + current_pair.symbol2] });

var socket = require('engine.io')('ws://ws.cex.io');
socket.onopen = function(){
  socket.onmessage = function(data){ console.log("data", data) };
  socket.onclose = function(){console.log("onclose")};
};
*/

var sys = require('sys');
var WebSocket = require('websocket').WebSocket;

var ws = new WebSocket('ws://ws.cex.io/Primus', 'borf');
ws.addListener('data', function(buf) {
    sys.debug('Got data: ' + sys.inspect(buf));
});
ws.onmessage = function(m) {
    sys.debug('Got message: ' + m);
}