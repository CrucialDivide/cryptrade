var http = require('http'),
	connect = require('connect'),
    httpProxy = require('http-proxy');

/*
//
// Create your proxy server and set the target in the options.
//
var proxy = httpProxy.createProxyServer({target:'http://data.cryptotrader.org', ws: true}).listen(8000);

//
// Create your target server
//

//
// Listen for the `error` event on `proxy`.


proxy.on('error', function (err, req, res) {
  res.writeHead(500, {
    'Content-Type': 'text/plain'
  });

  res.end('Something went wrong. And we are reporting a custom error message.');
});

//
// Listen for the `proxyRes` event on `proxy`.
//

proxy.on('proxyRes', function (res) {
  console.log('RAW Response from the target', JSON.stringify(res.headers, true, 2));
  //console.log(res);
});

*/
//
// Create a proxy server with custom application logic
//
/*
var proxy = httpProxy.createProxyServer({});

//
// Create your custom server and just call `proxy.web()` to proxy 
// a web request to the target passed in the options
// also you can use `proxy.ws()` to proxy a websockets request
//
var server = require('http').createServer(function(req, res) {
  // You can define here your custom logic to handle the request
  // and then proxy the request.
  proxy.web(req, res, { target: 'http://127.0.0.1:5060' });
});

console.log("listening on port 5050")
server.listen(5050);
*/

var proxy = httpProxy.createProxyServer();

var myres = {
  ondata: function(data) {
    // your logic here
    this.res.write(data);
  },
  onend: function() {
    this.res.end();
  }
}

var server = http.createServer(function(req, res) {
  var res2 = Object.create(myres);
  res2.res = res;
  proxy.web(req, res2, { target: 'http://data.cryptotrader.org', ws: true })
});
server.listen(8000);