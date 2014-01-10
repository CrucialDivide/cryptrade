var fs = require('fs');
var CSON = require('cson');

if (!fs.existsSync('keys.cson')) {
  keys = {
    cryptotrader: {
      api_key: 'demo'
    },
    mtgox: {
      key: '',
      secret: ''
    },
    bitstamp: {
      clientid: '',
      key: '',
      secret: ''
    },
    btce: {
      key: '',
      secret: ''
    },
    cexio: {
      clientid: 'laSeek',
      key: 'eFMtVds93lxkFDAxoWqSZLJzI',
      secret: '0tcPUb8JfVTvg9VyKAgIHu8iC5M'
    }
  } 
  CSON.stringify(keys, function(err,str) {
    if (err) {
      console.log(err);
    } else {
      console.log('Creating API keys storage..');
      fs.writeFile('keys.cson',str,function(err) {
        if (err) {
          console.log(err);
        }
      });
    }
  });
}
